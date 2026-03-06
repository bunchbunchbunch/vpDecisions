from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Casino:
    slug: str
    name: str
    region: str
    location: str
    rating: Optional[float] = None
    is_closed: bool = False
    has_coupon: bool = False
    game_count: int = 0
    source_url: str = ""


@dataclass
class Game:
    game_name: str
    abbreviation: str
    pay_table: str
    return_pct: float


@dataclass
class GameConfig:
    casino_slug: str
    abbreviation: str
    pay_table: str
    denominations: str = ""
    play_lines: str = ""
    machine_type: str = ""
    physical_type: str = ""
    location_in_casino: str = ""
    quantity: str = ""
