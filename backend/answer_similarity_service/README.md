# Answer Similarity Service (Python)

Python service that owns AI/scoring work for ABU Zaria CBT exam integrity —
starting with answer-similarity detection between candidates in the same
exam hall.

## Purpose

- Own AI/ML scoring — this is the "AI is for Python" piece of the stack
- Keep similarity/collusion analysis out of the Rust state service and out
  of the Flutter UI
- Stay swappable: `similarity()` in `main.py` is the one function to
  replace if/when this grows into a real embedding-based model

## Ownership contract

- **This service**: text-similarity scoring, and future AI-flavored
  analysis (object detection, etc.), stateless per request
- **Rust (`workstation_heartbeat_service`)**: owns live state — collects
  candidate answers per hall/exam/question, calls this service, and
  broadcasts the result to invigilators
- **Flutter**: UI only — displays whatever Rust broadcasts

## Endpoints

- `GET /healthz` -> liveness check
- `POST /similarity/batch` -> compares every pair of answers in the
  submitted batch, returns pairs at or above the similarity threshold

  Request:
  ```json
  {
    "entries": [
      {"registrationNumber": "ABU/CSC/001", "candidateName": "...", "seatNumber": "A-01", "text": "..."},
      {"registrationNumber": "ABU/CSC/002", "candidateName": "...", "seatNumber": "A-02", "text": "..."}
    ]
  }
  ```

  Response:
  ```json
  {
    "flaggedPairs": [
      {
        "registrationNumberA": "ABU/CSC/001",
        "seatA": "A-01",
        "registrationNumberB": "ABU/CSC/002",
        "seatB": "A-02",
        "similarity": 0.91
      }
    ]
  }
  ```

## Run

```bash
cd backend/answer_similarity_service
python main.py
```

Optional overrides:

```bash
ANSWER_SIMILARITY_BIND_ADDR=127.0.0.1:8099 SIMILARITY_THRESHOLD=0.85 python main.py
```

No third-party dependencies — stdlib only (`difflib` for scoring,
`http.server` for the API), so it runs anywhere Python 3.10+ runs.

## Scope

This service should own AI-flavored exam-integrity analysis. It should not
own live workstation state, risk-score persistence, or WebSocket
broadcasting — those remain in Rust.
