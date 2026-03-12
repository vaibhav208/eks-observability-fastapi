from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

@app.get("/")
def root():
    return {"message": "FastAPI Observability App"}

@app.get("/health")
def health():
    return {"status": "ok"}

Instrumentator().instrument(app).expose(app)
