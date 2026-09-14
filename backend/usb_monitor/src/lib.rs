use std::collections::VecDeque;
use std::ffi::{c_char, CString};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

const CAPACITY: usize = 256;
static EVENTS: Mutex<VecDeque<String>> = Mutex::new(VecDeque::new());
static HANDLE: Mutex<Option<usize>> = Mutex::new(None);

fn enqueue(queue: &mut VecDeque<String>, event: String) {
    if queue.len() >= CAPACITY {
        queue.pop_front();
        // Preserve an explicit coverage warning instead of silently losing events.
        if let Some(first) = queue.front_mut() {
            *first = serde_json::json!({"kind": "overflow"}).to_string();
        }
    }
    queue.push_back(event);
}

#[cfg(windows)]
unsafe extern "system" fn notification(
    _: windows_sys::Win32::Devices::DeviceAndDriverInstallation::HCMNOTIFICATION,
    _: *const core::ffi::c_void,
    action: i32,
    data: *const windows_sys::Win32::Devices::DeviceAndDriverInstallation::CM_NOTIFY_EVENT_DATA,
    size: u32,
) -> u32 {
    use windows_sys::Win32::Devices::DeviceAndDriverInstallation::*;
    if action != CM_NOTIFY_ACTION_DEVICEINTERFACEARRIVAL || data.is_null() {
        return 0;
    }
    let offset = std::mem::offset_of!(CM_NOTIFY_EVENT_DATA, u)
        + std::mem::offset_of!(CM_NOTIFY_EVENT_DATA_0_0, SymbolicLink);
    if size as usize <= offset || (*data).FilterType != CM_NOTIFY_FILTER_TYPE_DEVICEINTERFACE {
        return 0;
    }
    let ptr = (data as *const u8).add(offset) as *const u16;
    let units = std::slice::from_raw_parts(ptr, ((size as usize - offset) / 2).min(4096));
    let length = units.iter().position(|v| *v == 0).unwrap_or(units.len());
    let device = String::from_utf16_lossy(&units[..length]);
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    if let Ok(mut queue) = EVENTS.lock() {
        enqueue(
            &mut queue,
            serde_json::json!({
                "kind": "attached", "deviceId": device, "timestampMs": timestamp as u64,
            })
            .to_string(),
        );
    }
    0
}

/// One monitor per process. Call lifecycle functions from the Flutter UI isolate.
#[no_mangle]
pub extern "C" fn usb_monitor_start() -> u32 {
    #[cfg(windows)]
    {
        use windows_sys::Win32::Devices::DeviceAndDriverInstallation::*;
        let Ok(mut handle) = HANDLE.lock() else {
            return 1;
        };
        if handle.is_some() {
            return 0;
        }
        if let Ok(mut events) = EVENTS.lock() {
            events.clear();
        }
        let mut filter = CM_NOTIFY_FILTER {
            cbSize: std::mem::size_of::<CM_NOTIFY_FILTER>() as u32,
            FilterType: CM_NOTIFY_FILTER_TYPE_DEVICEINTERFACE,
            ..Default::default()
        };
        filter.u.DeviceInterface.ClassGuid =
            windows_sys::Win32::Devices::Usb::GUID_DEVINTERFACE_USB_DEVICE;
        let mut native = std::ptr::null_mut();
        let result = unsafe {
            CM_Register_Notification(&filter, std::ptr::null(), Some(notification), &mut native)
        };
        if result == CR_SUCCESS {
            *handle = Some(native as usize);
        }
        result
    }
    #[cfg(not(windows))]
    {
        1
    }
}

/// Unregister waits for callbacks; never hold EVENTS while unregistering.
#[no_mangle]
pub extern "C" fn usb_monitor_stop() {
    let native = HANDLE.lock().ok().and_then(|mut handle| handle.take());
    #[cfg(windows)]
    if let Some(native) = native {
        unsafe {
            windows_sys::Win32::Devices::DeviceAndDriverInstallation::CM_Unregister_Notification(
                native as _,
            );
        }
    }
    #[cfg(not(windows))]
    let _ = native;
}

/// Returns an owned UTF-8 JSON string, or null. Caller must free exactly once.
#[no_mangle]
pub extern "C" fn usb_monitor_poll() -> *mut c_char {
    EVENTS
        .lock()
        .ok()
        .and_then(|mut queue| queue.pop_front())
        .and_then(|text| CString::new(text).ok())
        .map_or(std::ptr::null_mut(), CString::into_raw)
}

/// # Safety
/// `value` must be null or an unfreed pointer returned by usb_monitor_poll.
#[no_mangle]
pub unsafe extern "C" fn usb_monitor_free(value: *mut c_char) {
    if !value.is_null() {
        drop(CString::from_raw(value));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn queue_preserves_order_and_reports_overflow() {
        let mut queue = VecDeque::new();
        enqueue(&mut queue, "first".into());
        enqueue(&mut queue, "second".into());
        assert_eq!(queue.pop_front().unwrap(), "first");
        for i in 0..CAPACITY + 5 {
            enqueue(&mut queue, i.to_string());
        }
        assert_eq!(queue.len(), CAPACITY);
        assert_eq!(queue.front().unwrap(), "{\"kind\":\"overflow\"}");
    }

    #[cfg(windows)]
    #[test]
    fn native_subscription_and_callback_ffi() {
        use windows_sys::Win32::Devices::DeviceAndDriverInstallation::*;
        assert_eq!(usb_monitor_start(), 0);
        assert_eq!(usb_monitor_start(), 0); // Idempotent registration.
        usb_monitor_stop();
        usb_monitor_stop();
        EVENTS.lock().unwrap().clear();
        let name: Vec<u16> = "USB-test-device\0".encode_utf16().collect();
        let offset = std::mem::offset_of!(CM_NOTIFY_EVENT_DATA, u)
            + std::mem::offset_of!(CM_NOTIFY_EVENT_DATA_0_0, SymbolicLink);
        let bytes = (offset + name.len() * 2).max(std::mem::size_of::<CM_NOTIFY_EVENT_DATA>());
        let mut buffer = vec![0u64; bytes.div_ceil(8)];
        let data = buffer.as_mut_ptr() as *mut CM_NOTIFY_EVENT_DATA;
        unsafe {
            (*data).FilterType = CM_NOTIFY_FILTER_TYPE_DEVICEINTERFACE;
            std::ptr::copy_nonoverlapping(
                name.as_ptr(),
                (data as *mut u8).add(offset) as *mut u16,
                name.len(),
            );
            notification(
                std::ptr::null_mut(),
                std::ptr::null(),
                CM_NOTIFY_ACTION_DEVICEINTERFACEREMOVAL,
                data,
                bytes as u32,
            );
            assert!(usb_monitor_poll().is_null());
            notification(
                std::ptr::null_mut(),
                std::ptr::null(),
                CM_NOTIFY_ACTION_DEVICEINTERFACEARRIVAL,
                data,
                bytes as u32,
            );
            let event = usb_monitor_poll();
            assert!(!event.is_null());
            let decoded: serde_json::Value =
                serde_json::from_str(std::ffi::CStr::from_ptr(event).to_str().unwrap()).unwrap();
            assert_eq!(decoded["deviceId"], "USB-test-device");
            assert_eq!(decoded["kind"], "attached");
            assert!(decoded["timestampMs"].as_u64().unwrap() > 0);
            usb_monitor_free(event);
            assert!(usb_monitor_poll().is_null());
        }
    }
}
