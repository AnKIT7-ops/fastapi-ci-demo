import os
from fastapi import FastAPI

app = FastAPI(title="CI Demo API")

@app.get("/")
def read_root():
    return {"message": "Hello, Hello world!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}