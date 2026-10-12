"""Every route the app and the iPhone Shortcut call.

Routes stay thin: read the request, call a function from auth/steps/social,
return the result. Logic functions raise ValueError for bad input; main.py
turns that into a 400 response with the message.
"""

from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

from . import auth, social, steps
from .db import get_db

router = APIRouter()


# ---- request bodies ----

class Credentials(BaseModel):
    username: str = Field(max_length=20)
    password: str = Field(max_length=128)


class StepDay(BaseModel):
    date: date
    steps: int = Field(ge=0, le=100_000)


class StepsUpload(BaseModel):
    days: list[StepDay] = Field(max_length=31)


class FriendRequest(BaseModel):
    username: str = Field(max_length=20)


# ---- who is calling ----

bearer = HTTPBearer(auto_error=False)  # also adds the Authorize button to /docs


def current_user(creds: HTTPAuthorizationCredentials | None = Depends(bearer), db=Depends(get_db)):
    """Reads 'Authorization: Bearer <token>' and returns the user row."""
    user = auth.user_from_token(db, creds.credentials) if creds else None
    if not user:
        raise HTTPException(401, "Log in first")
    return user


Db = Annotated[object, Depends(get_db)]
User = Annotated[object, Depends(current_user)]


# ---- accounts ----

@router.post("/auth/signup")
def signup(body: Credentials, db: Db):
    return {"token": auth.signup(db, body.username, body.password)}


@router.post("/auth/login")
def login(body: Credentials, db: Db):
    return {"token": auth.login(db, body.username, body.password)}


@router.get("/me")
def me(user: User, db: Db):
    return {"username": user["username"], **steps.summary(db, user["id"])}


# ---- steps ----

@router.post("/steps")
def post_steps(body: StepsUpload, user: User, db: Db):
    """Body: {"days": [{"date": "2026-10-10", "steps": 8423}]}. Up to 31 days."""
    latest_allowed = date.today() + timedelta(days=1)  # +1 for time zones
    for day in body.days:
        if day.date > latest_allowed:
            raise ValueError("Date is in the future")
        steps.save_steps(db, user["id"], day.date, day.steps)
    return steps.summary(db, user["id"])


class TodaySteps(BaseModel):
    steps: int = Field(ge=0, le=100_000)


@router.post("/steps/today")
def post_today(body: TodaySteps, user: User, db: Db):
    """Body: {"steps": 8423}. The easy one for the iPhone Shortcut.
    Uses the server's date, which matches the phone when both are in the same time zone."""
    steps.save_steps(db, user["id"], date.today(), body.steps)
    return steps.summary(db, user["id"])


# ---- friends ----

@router.get("/friends")
def get_friends(user: User, db: Db):
    return {
        "friends": social.friends(db, user["id"]),
        "requests": social.incoming_requests(db, user["id"]),
    }


@router.post("/friends/request")
def request_friend(body: FriendRequest, user: User, db: Db):
    social.send_request(db, user["id"], body.username)
    return {"ok": True}


@router.post("/friends/{from_id}/accept")
def accept_friend(from_id: int, user: User, db: Db):
    social.accept(db, user["id"], from_id)
    return {"ok": True}


# ---- leaderboard ----

@router.get("/leaderboard")
def get_leaderboard(user: User, db: Db, range_name: Annotated[str, Query(alias="range")] = "week"):
    """/leaderboard?range=today or ?range=week"""
    return social.leaderboard(db, user["id"], range_name)
