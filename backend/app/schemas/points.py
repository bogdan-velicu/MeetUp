from pydantic import BaseModel, Field
from typing import Optional, Dict, List
from datetime import datetime


class PointsSummaryResponse(BaseModel):
    """Schema for points summary response."""
    user_id: int
    total_points: int
    breakdown: Dict[str, Dict[str, int]] = Field(default_factory=dict)
    
    class Config:
        from_attributes = True


class PointsTransactionResponse(BaseModel):
    """Schema for points transaction response."""
    id: int
    points: int
    transaction_type: str
    reference_id: Optional[int] = None
    description: Optional[str] = None
    created_at: str
    
    class Config:
        from_attributes = True


class PointsHistoryResponse(BaseModel):
    """Schema for points history response."""
    user_id: int
    transactions: List[PointsTransactionResponse]
    limit: int
    offset: int


class PointsAwardResponse(BaseModel):
    """Schema for points award response."""
    transaction_id: int
    points: int
    transaction_type: str
    total_points: int
    description: Optional[str] = None

