"""Answer Similarity Service (Python) — the AI layer of ABU Zaria CBT.

Compares candidates' free-text exam answers against each other within the
same hall + exam + question, and flags pairs that are suspiciously alike —
a signal the Rust workstation-heartbeat backend relays to invigilators as a
"Similarity Flagged" alert. This service owns exam-integrity AI scoring; it
does not own live state (that's the Rust backend) and does not own UI
(that's the Flutter app). See backend/workstation_heartbeat_service for the
caller and lib/modules/invigilator for how the flag surfaces to invigilators.

The scoring function (`similarity`) is intentionally isolated so it can be
swapped for a real embedding/ML model later without touching the HTTP layer.

Run:
    python main.py

Optional bind override:
    ANSWER_SIMILARITY_BIND_ADDR=127.0.0.1:8099 python main.py

Optional threshold override (0.0-1.0, default 0.82):
    SIMILARITY_THRESHOLD=0.85 python main.py
"""

from __future__ import annotations

import json
import os
from difflib import SequenceMatcher
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from itertools import combinations
from typing import Any

DEFAULT_BIND_ADDR = "127.0.0.1:8099"
DEFAULT_THRESHOLD = 0.82


def similarity(text_a: str, text_b: str) -> float:
    """Returns a 0.0-1.0 similarity score between two answer strings.

    Uses difflib's ratio (longest-matching-block based) — cheap, dependency
    -free, and good enough to catch near-identical or lightly-reworded
    answers. Swap this out for a real sentence-embedding model if/when the
    project wants semantic (not just textual) similarity.
    """
    a = text_a.strip().lower()
    b = text_b.strip().lower()
    if not a or not b:
        return 0.0
    return SequenceMatcher(None, a, b).ratio()


def find_flagged_pairs(
    entries: list[dict[str, Any]], threshold: float
) -> list[dict[str, Any]]:
    flagged = []
    for entry_a, entry_b in combinations(entries, 2):
        # Never compare a candidate's answer against itself under a
        # different entry, and skip if either side is missing an id.
        reg_a = entry_a.get("registrationNumber", "")
        reg_b = entry_b.get("registrationNumber", "")
        if not reg_a or not reg_b or reg_a == reg_b:
            continue

        score = similarity(entry_a.get("text", ""), entry_b.get("text", ""))
        if score >= threshold:
            flagged.append(
                {
                    "registrationNumberA": reg_a,
                    "seatA": entry_a.get("seatNumber", ""),
                    "registrationNumberB": reg_b,
                    "seatB": entry_b.get("seatNumber", ""),
                    "similarity": round(score, 4),
                }
            )
    return flagged


class Handler(BaseHTTPRequestHandler):
    server_version = "AnswerSimilarityService/1.0"

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802 (stdlib method name)
        if self.path == "/healthz":
            self._send_json(200, {"status": "ok"})
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802 (stdlib method name)
        if self.path != "/similarity/batch":
            self._send_json(404, {"error": "not found"})
            return

        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length) if length else b"{}"

        try:
            body = json.loads(raw)
        except json.JSONDecodeError:
            self._send_json(400, {"error": "invalid json"})
            return

        entries = body.get("entries")
        if not isinstance(entries, list):
            self._send_json(400, {"error": "entries must be a list"})
            return

        threshold = float(
            os.environ.get("SIMILARITY_THRESHOLD", DEFAULT_THRESHOLD)
        )
        flagged_pairs = find_flagged_pairs(entries, threshold)
        self._send_json(200, {"flaggedPairs": flagged_pairs})

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        print(f"[answer-similarity-service] {self.address_string()} {format % args}")


def main() -> None:
    bind = os.environ.get("ANSWER_SIMILARITY_BIND_ADDR", DEFAULT_BIND_ADDR)
    host, _, port_str = bind.partition(":")
    port = int(port_str) if port_str else 8099

    server = ThreadingHTTPServer((host, port), Handler)
    print(f"answer-similarity-service listening on {host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
