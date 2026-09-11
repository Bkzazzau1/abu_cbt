# ks_sentinel

Rust security runtime for K-SLAS CBT workstations.

This crate is designed to be called from Flutter through Flutter Rust Bridge (FRB) in a background isolate/thread.

This crate intentionally owns proctoring and workstation integrity duties.
It does not own live camera transport or streaming.

## Capabilities

1. Hardware root-of-trust fingerprint
- Reads hardware identifiers (board serial, CPU identity, MAC, machine identity).
- Detects likely VM environment.
- Produces SHA-256 fingerprint and deterministic workstation ID seed.

2. Peripheral and process sentinel
- USB snapshot + diff utilities to detect inserted/removed devices.
- Process scanner with configurable blocklist and optional process kill.

3. Encrypted local fog sync
- AES-256-GCM encrypted local autosave file format.
- Append/load/clear APIs for answer snapshots.

4. Payload signing
- Per-workstation Ed25519 keypair generation.
- Sign and verify answer payloads.

## Explicit Non-Goals

- Live camera transport
- Stream signaling or relay
- Invigilator media fan-out

## Build

```bash
cd native/ks_sentinel
cargo check
```

## Suggested FRB surface

Expose these functions first:

- `collect_hardware_fingerprint`
- `derive_workstation_id`
- `verify_fingerprint`
- `scan_and_enforce` (process policy)
- `snapshot_usb_devices` + `diff_snapshots`
- `append_encrypted_entry` + `load_encrypted_entries`
- `load_or_create_signing_key` + `sign_bytes`

## Integration notes

- Run sentinel loop every 2-5 seconds from Rust (not Dart timers) for consistency under UI load.
- Send sentinel events to the existing Axum heartbeat service as signed telemetry.
- Enforce backend rejection when:
  - workstation fingerprint mismatches registered hash
  - workstation status != whitelisted
  - signature verification fails
