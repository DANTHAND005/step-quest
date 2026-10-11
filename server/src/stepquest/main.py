"""Creates the app. Run with: uv run uvicorn stepquest.main:app --reload"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .api import router
from .db import init_db


@asynccontextmanager
async def lifespan(app):
    init_db()
    yield


app = FastAPI(title="Step Quest", lifespan=lifespan)
app.include_router(router)

# Lets the Flutter app run in Chrome on this PC (flutter run -d chrome).
# Only localhost pages are allowed. Phone and desktop apps don't need this.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(ValueError)
def bad_input(request: Request, error: ValueError):
    return JSONResponse(status_code=400, content={"detail": str(error)})
