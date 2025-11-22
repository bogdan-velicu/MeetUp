from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class LocationUpdate(BaseModel):
    latitude: str = Field(..., description="Latitude as string for precision")
    longitude: str = Field(..., description="Longitude as string for precision")
    accuracy_m: Optional[str] = Field(None, description="GPS accuracy in meters")
    save_history: bool = Field(True, description="Whether to save to location history")

class LocationResponse(BaseModel):
    user_id: int
    latitude: str
    longitude: str
    accuracy_m: Optional[str]
    updated_at: datetime

class FriendLocationResponse(BaseModel):
    user_id: int
    username: str
    full_name: str
    latitude: str
    longitude: str
    accuracy_m: Optional[str]
    updated_at: datetime
    availability_status: str

class LocationHistoryCreate(BaseModel):
    latitude: str
    longitude: str
    recorded_at: datetime
    altitude_m: Optional[str] = None
    accuracy_m: Optional[str] = None
    speed_mps: Optional[str] = None
    heading_deg: Optional[str] = None
    source: str = Field("gps", description="Source: gps, wifi, network, manual")

class LocationHistoryResponse(BaseModel):
    id: int
    latitude: str
    longitude: str
    recorded_at: datetime
    accuracy_m: Optional[str]
    altitude_m: Optional[str]
    speed_mps: Optional[str]
    heading_deg: Optional[str]
    source: str

