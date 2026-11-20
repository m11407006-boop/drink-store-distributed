from fastapi import FastAPI

app = FastAPI(
    title="Drink Store API",
    description="Distributed Beverage Store Management System",
    version="1.0.0"
)

@app.get("/")
def root():
    return {
        "message": "Drink Store API is running",
        "status": "ok"
    }

@app.get("/api/health")
def health():
    return {
        "service": "backend",
        "status": "healthy"
    }
