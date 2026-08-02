# FastAPI CI/CD Pipeline

A production-style CI/CD pipeline for a containerized FastAPI service, built with
GitHub Actions and published to Docker Hub.

![CI](https://github.com/AnKIT7-ops/fastapi-ci-demo/actions/workflows/ci.yml/badge.svg)

## What it does

Every push to `main` automatically:
1. Lints the code (ruff)
2. Runs the test suite (pytest)
3. Builds a hardened Docker image — only if the above pass
4. Publishes to Docker Hub with both `latest` and commit-SHA tags
5. Smoke-tests the published image to verify the container actually starts

Pull requests run steps 1–2 only; nothing is published until code is merged.

## Pipeline

push / PR
│
▼
┌─────────────────┐
│ lint-and-test │ ruff → pytest
└────────┬────────┘
│ (only if green, and only on push to main)
▼
┌─────────────────┐
│ build-and-push │ docker build → Docker Hub → smoke test
└─────────────────┘

## Running locally

```bash
# From source
pip install -r requirements.txt
uvicorn app.main:app --reload

# From the published image
docker run -p 8000:8000 ankit7777/fastapi-ci-demo:latest
```

Then visit http://localhost:8000/docs

## Endpoints

| Method | Path      | Description            |
|--------|-----------|------------------------|
| GET    | `/`       | Returns a greeting     |
| GET    | `/health` | Liveness check         |

## Design decisions

**Multi-stage Docker build** — dependencies are installed in a builder stage and
only the resulting packages are copied into the runtime image. Build tooling and
pip cache never ship to production, reducing image size and attack surface.

**Non-root container user** — the app runs as `appuser`, not root. If the
application is compromised, the attacker doesn't inherit root privileges inside
the container.

**Commit-SHA image tags alongside `latest`** — `latest` is mutable and tells you
nothing about what's actually deployed. SHA tags are immutable and traceable to an
exact commit, which is what makes a rollback possible: you can identify and
redeploy the precise image that was last known good.

**Job separation with `needs:`** — build and publish are a separate job that
depends on lint-and-test. A failing test blocks publication entirely rather than
producing a broken image.

**Lint before test** — linting takes ~1s, tests take longer. Failing fast on the
cheap check avoids spending pipeline time on code that won't pass basic standards.

**`--fix` is used locally, never in CI** — auto-fixing in CI would repair the
runner's throwaway copy and pass green while the repo stays broken. CI verifies;
it doesn't mutate.

**Smoke test after publish** — `CMD` is never executed during `docker build`, so a
broken start command builds and publishes successfully but crashes at runtime.
The smoke test starts the published image and hits `/health` to close that gap.

**Credentials via GitHub Secrets** — the registry token is stored encrypted and
injected at runtime. Nothing sensitive lives in the repository.

## Tech stack

FastAPI · pytest · ruff · Docker · GitHub Actions · Docker Hub