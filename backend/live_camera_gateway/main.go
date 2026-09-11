package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"
)

type policyResponse struct {
	Service                 string   `json:"service"`
	Language                string   `json:"language"`
	PrimaryResponsibility   string   `json:"primaryResponsibility"`
	Owns                    []string `json:"owns"`
	DoesNotOwn              []string `json:"doesNotOwn"`
	RustProctoringServices  []string `json:"rustProctoringServices"`
	GeneratedAtISO8601UTC   string   `json:"generatedAtIso8601Utc"`
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", healthzHandler)
	mux.HandleFunc("/v1/streaming/policy", streamingPolicyHandler)

	addr := getenv("LIVE_STREAM_BIND_ADDR", ":8090")
	log.Printf("live camera gateway listening on %s", addr)

	server := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Fatal(server.ListenAndServe())
}

func healthzHandler(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"service": "live_camera_gateway",
		"owner":   "go",
	})
}

func streamingPolicyHandler(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, policyResponse{
		Service:               "live_camera_gateway",
		Language:              "go",
		PrimaryResponsibility: "live camera transport and streaming coordination",
		Owns: []string{
			"camera session ingress",
			"live stream transport",
			"signaling and relay coordination",
			"stream fan-out",
		},
		DoesNotOwn: []string{
			"usb watchdog enforcement",
			"process sentinel enforcement",
			"workstation fingerprinting",
			"signed proctoring telemetry",
			"risk scoring",
		},
		RustProctoringServices: []string{
			"native/ks_sentinel",
			"backend/workstation_heartbeat_service",
		},
		GeneratedAtISO8601UTC: time.Now().UTC().Format(time.RFC3339),
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	body, err := json.Marshal(payload)
	if err != nil {
		http.Error(w, `{"error":"encoding response failed"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(body)
	_, _ = w.Write([]byte("\n"))
}

func getenv(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
