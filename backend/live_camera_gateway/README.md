# Live Camera Gateway (Go)

Go service reserved for live camera and streaming work in ABU Zaria CBT.

## Purpose

- Keep live media transport out of the Rust proctoring services
- Provide a clear landing zone for camera/session streaming work
- Preserve Rust ownership of security, proctoring, and signed telemetry

## Endpoints

- `GET /healthz` -> liveness check
- `GET /v1/streaming/policy` -> current service ownership contract

## Run

```bash
cd backend/live_camera_gateway
go run .
```

Optional bind override:

```bash
LIVE_STREAM_BIND_ADDR=:8090 go run .
```

## Scope

This service should own media ingress, signaling, and stream fan-out.
It should not own workstation fingerprinting, USB/process detection,
telemetry signing, or risk scoring. Those remain in Rust.
