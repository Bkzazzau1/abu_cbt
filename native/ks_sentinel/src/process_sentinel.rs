use std::ffi::OsString;

use serde::{Deserialize, Serialize};
use sysinfo::{Signal, System};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProcessPolicy {
    pub blocked_processes: Vec<String>,
    pub kill_on_detect: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProcessViolation {
    pub pid: u32,
    pub process_name: String,
    pub killed: bool,
}

impl Default for ProcessPolicy {
    fn default() -> Self {
        Self {
            blocked_processes: vec![
                "teamviewer".to_string(),
                "anydesk".to_string(),
                "zoom".to_string(),
                "obs".to_string(),
                "chrome".to_string(),
                "firefox".to_string(),
                "msedge".to_string(),
                "brave".to_string(),
                "discord".to_string(),
            ],
            kill_on_detect: true,
        }
    }
}

pub fn scan_and_enforce(policy: &ProcessPolicy) -> Vec<ProcessViolation> {
    let mut system = System::new_all();
    system.refresh_processes();

    let block_list = policy
        .blocked_processes
        .iter()
        .map(|item| item.trim().to_lowercase())
        .filter(|item| !item.is_empty())
        .collect::<Vec<_>>();

    let mut violations = Vec::new();

    for (pid, process) in system.processes() {
        let process_name = OsString::from(process.name())
            .to_string_lossy()
            .to_lowercase();

        let blocked = block_list.iter().any(|needle| process_name.contains(needle));
        if !blocked {
            continue;
        }

        let killed = if policy.kill_on_detect {
            process
                .kill_with(Signal::Kill)
                .unwrap_or_else(|| process.kill())
        } else {
            false
        };

        violations.push(ProcessViolation {
            pid: pid.as_u32(),
            process_name,
            killed,
        });
    }

    violations
}
