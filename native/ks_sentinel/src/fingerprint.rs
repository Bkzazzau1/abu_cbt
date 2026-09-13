use std::process::Command;

#[cfg(not(target_os = "windows"))]
use std::fs;

use pnet_datalink::interfaces;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::error::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HardwareFingerprint {
    pub motherboard_serial: String,
    pub cpu_identity: String,
    pub primary_mac: String,
    pub machine_identity: String,
    pub virtualization_detected: bool,
    pub fingerprint_sha256: String,
}

pub fn collect_hardware_fingerprint() -> Result<HardwareFingerprint> {
    let motherboard_serial = read_motherboard_serial().unwrap_or_else(|| "unknown-board".to_string());
    let cpu_identity = read_cpu_identity().unwrap_or_else(|| "unknown-cpu".to_string());
    let primary_mac = read_primary_mac().unwrap_or_else(|| "unknown-mac".to_string());
    let machine_identity = read_machine_identity().unwrap_or_else(|| "unknown-machine".to_string());
    let virtualization_detected = is_virtualized_host();

    let joined = format!(
        "mb:{motherboard_serial}|cpu:{cpu_identity}|mac:{primary_mac}|mid:{machine_identity}|vm:{virtualization_detected}"
    )
    .to_lowercase();

    let digest = Sha256::digest(joined.as_bytes());
    let fingerprint_sha256 = hex::encode(digest);

    Ok(HardwareFingerprint {
        motherboard_serial,
        cpu_identity,
        primary_mac,
        machine_identity,
        virtualization_detected,
        fingerprint_sha256,
    })
}

pub fn derive_workstation_id(fingerprint_sha256: &str) -> String {
    let sanitized = fingerprint_sha256.trim().to_uppercase();
    let fallback = "000000000000";
    let seed = if sanitized.len() >= 12 {
        &sanitized[0..12]
    } else {
        fallback
    };

    format!(
        "ABU-CBT-{}-{}-{}",
        &seed[0..4],
        &seed[4..8],
        &seed[8..12]
    )
}

pub fn verify_fingerprint(expected_sha256: &str) -> Result<bool> {
    let current = collect_hardware_fingerprint()?;
    Ok(current
        .fingerprint_sha256
        .eq_ignore_ascii_case(expected_sha256.trim()))
}

fn normalize(input: &str) -> String {
    input
        .replace('\0', "")
        .lines()
        .map(str::trim)
        .find(|line| !line.is_empty())
        .unwrap_or("")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

fn run_and_pick_first_line(command: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(command).args(args).output().ok()?;
    if !output.status.success() {
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines = stdout
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .collect::<Vec<_>>();

    if lines.len() >= 2 {
        Some(lines[1..].join(" "))
    } else {
        lines.first().map(|line| (*line).to_string())
    }
}

#[cfg(not(target_os = "windows"))]
fn read_file(path: &str) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| normalize(&s))
}

#[cfg(target_os = "windows")]
fn read_motherboard_serial() -> Option<String> {
    run_and_pick_first_line("wmic", &["baseboard", "get", "serialnumber"]).map(|s| normalize(&s))
}

#[cfg(not(target_os = "windows"))]
fn read_motherboard_serial() -> Option<String> {
    read_file("/sys/class/dmi/id/board_serial")
}

#[cfg(target_os = "windows")]
fn read_cpu_identity() -> Option<String> {
    run_and_pick_first_line("wmic", &["cpu", "get", "processorid"]).map(|s| normalize(&s))
}

#[cfg(not(target_os = "windows"))]
fn read_cpu_identity() -> Option<String> {
    let raw = fs::read_to_string("/proc/cpuinfo").ok()?;
    for line in raw.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("model name") || trimmed.starts_with("Serial") {
            let value = trimmed.split(':').nth(1).unwrap_or("").trim();
            if !value.is_empty() {
                return Some(normalize(value));
            }
        }
    }
    None
}

fn read_primary_mac() -> Option<String> {
    let mut macs = interfaces()
        .into_iter()
        .filter(|iface| !iface.is_loopback() && iface.is_up())
        .filter_map(|iface| iface.mac.map(|mac| mac.to_string()))
        .collect::<Vec<_>>();
    macs.sort_unstable();
    macs.into_iter().next()
}

#[cfg(target_os = "windows")]
fn read_machine_identity() -> Option<String> {
    run_and_pick_first_line("wmic", &["csproduct", "get", "uuid"]).map(|s| normalize(&s))
}

#[cfg(not(target_os = "windows"))]
fn read_machine_identity() -> Option<String> {
    read_file("/etc/machine-id")
}

fn is_virtualized_host() -> bool {
    let mut probes = Vec::new();

    #[cfg(target_os = "windows")]
    {
        if let Some(manu_model) =
            run_and_pick_first_line("wmic", &["computersystem", "get", "manufacturer,model"])
        {
            probes.push(manu_model.to_lowercase());
        }
    }

    #[cfg(not(target_os = "windows"))]
    {
        if let Some(cpuinfo) = fs::read_to_string("/proc/cpuinfo").ok() {
            probes.push(cpuinfo.to_lowercase());
        }
        if let Some(product_name) = read_file("/sys/class/dmi/id/product_name") {
            probes.push(product_name.to_lowercase());
        }
        if let Some(sys_vendor) = read_file("/sys/class/dmi/id/sys_vendor") {
            probes.push(sys_vendor.to_lowercase());
        }
    }

    let flags = [
        "vmware",
        "virtualbox",
        "qemu",
        "kvm",
        "hyper-v",
        "hyperv",
        "xen",
        "bochs",
        "parallels",
        "hypervisor",
    ];

    probes
        .iter()
        .any(|probe| flags.iter().any(|needle| probe.contains(needle)))
}
