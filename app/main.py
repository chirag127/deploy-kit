"""Minimal FastAPI service — hello + /healthz + /metrics."""
import os
import time

from fastapi import FastAPI
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

app = FastAPI(title="deploy-kit-app", version="1.0.0")

REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "path", "status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency", ["path"]
)

APP_NAME = os.getenv("APP_NAME", "deploy-kit-app")
ENV = os.getenv("ENV", "dev")
_start = time.time()


@app.middleware("http")
async def metrics_middleware(request, call_next):
    t0 = time.time()
    response = await call_next(request)
    REQUEST_COUNT.labels(request.method, request.url.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.url.path).observe(time.time() - t0)
    return response


@app.get("/")
def root():
    return {"app": APP_NAME, "env": ENV, "uptime_s": round(time.time() - _start, 1)}


@app.get("/healthz")
def health():
    return {"status": "ok"}


@app.get("/readyz")
def ready():
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
