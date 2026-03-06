import os
from dotenv import load_dotenv

# Load .env from project root
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))

BASE_URL = "https://www.vpfree2.com"

REGIONS = [
    "las-vegas",
    "reno-tahoe",
    "laughlin",
    "nevada",
    "east",
    "gulf-coast",
    "mid-west",
    "west",
    "canada",
]

REQUEST_DELAY = 1.5  # seconds between requests

# Supabase config
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://ctqefgdvqiaiumtmcjdz.supabase.co")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

BATCH_SIZE = 500  # rows per insert call
