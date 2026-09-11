use std::collections::BTreeSet;
use std::process::Command;

#[cfg(not(target_os = "windows"))]
use std::fs;
#[cfg(not(target_os = "windows"))]
use std::path::Path;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UsbDiff {
    pub inserted: Vec<String>,
    pub removed: Vec<String>,
}

pub fn snapshot_usb_devices() -> Vec<String> {
    #[cfg(target_os = "windows")]
    {
        return snapshot_usb_windows();
    }

    #[cfg(not(target_os = "windows"))]
    {
        return snapshot_usb_linux();
    }
}

pub fn diff_snapshots(previous: &[String], current: &[String]) -> UsbDiff {
    let prev = previous.iter().cloned().collect::<BTreeSet<_>>();
    let curr = current.iter().cloned().collect::<BTreeSet<_>>();

    let inserted = curr.difference(&prev).cloned().collect::<Vec<_>>();
    let removed = prev.difference(&curr).cloned().collect::<Vec<_>>();

    UsbDiff { inserted, removed }
}

#[cfg(target_os = "windows")]
fn snapshot_usb_windows() -> Vec<String> {
    let output = Command::new("wmic")
        .args(["path", "Win32_USBHub", "get", "DeviceID"])
        .output();

    let Ok(output) = output else {
        return vec![];
    };
    if !output.status.success() {
        return vec![];
    }

    String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .filter(|line| !line.eq_ignore_ascii_case("DeviceID"))
        .map(ToOwned::to_owned)
        .collect::<Vec<_>>()
}

#[cfg(not(target_os = "windows"))]
fn snapshot_usb_linux() -> Vec<String> {
    let base = Path::new("/sys/bus/usb/devices");
    let Ok(entries) = fs::read_dir(base) else {
        return vec![];
    };

    let mut devices = Vec::new();
    for entry in entries.flatten() {
        let path = entry.path();
        let product = read_attr(&path, "product");
        let vendor = read_attr(&path, "manufacturer");
        let serial = read_attr(&path, "serial");

        let identity = [vendor, product, serial]
            .into_iter()
            .flatten()
            .collect::<Vec<_>>()
            .join(" | ");

        if !identity.is_empty() {
            devices.push(identity);
        }
    }

    devices.sort_unstable();
    devices.dedup();
    devices
}

#[cfg(not(target_os = "windows"))]
fn read_attr(base: &Path, name: &str) -> Option<String> {
    let value = fs::read_to_string(base.join(name)).ok()?;
    let normalized = value.trim().to_string();
    if normalized.is_empty() {
        return None;
    }
    Some(normalized)
}
