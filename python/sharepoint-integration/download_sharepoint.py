import os
import requests
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import quote

# Configuration
GRAPH_API_URL = os.getenv("GRAPH_API_URL", "https://graph.microsoft.com/v1.0")
SHAREPOINT_SITE = os.getenv("SHAREPOINT_SITE")  # Site ID or hostname
SHAREPOINT_SITE_PATH = os.getenv("SHAREPOINT_SITE_PATH")  # Optional: site path (e.g., /sites/sitename)
SHAREPOINT_FILE_PATH = os.getenv("SHAREPOINT_FILE_PATH")  # File path relative to the document library
MS_GRAPH_TOKEN = os.getenv("MS_GRAPH_TOKEN")  # OAuth token stored as a CI/CD variable

# Validate required environment variables
if not MS_GRAPH_TOKEN:
    print("❌ Error: MS_GRAPH_TOKEN environment variable is not set.")
    sys.exit(1)

if not SHAREPOINT_SITE:
    print("❌ Error: SHAREPOINT_SITE environment variable is not set.")
    sys.exit(1)

if not SHAREPOINT_FILE_PATH:
    print("❌ Error: SHAREPOINT_FILE_PATH environment variable is not set.")
    sys.exit(1)

# Headers for Microsoft Graph API
HEADERS = {
    "Authorization": f"Bearer {MS_GRAPH_TOKEN}",
    "Accept": "application/json"
}

def manage_backups(local_path, max_backups=3):
    """
    Manage backups for the specified file.
    Ensures no more than `max_backups` backup files are kept.
    Deletes the oldest backups if the limit is exceeded.
    """
    local_path = Path(local_path)
    directory = local_path.parent
    filename = local_path.name
    
    # Find all backup files matching the pattern: filename.YYYYMMDD_HHMMSS.bak
    backups = []
    for f in directory.iterdir():
        if f.name.startswith(f"{filename}.") and f.name.endswith(".bak"):
            # Verify it has the expected structure
            parts = f.name[len(filename)+1:-4]  # Extract the middle part (timestamp)
            if parts and '_' in parts:  # Basic validation
                backups.append(f)

    # Sort backups by modification time (oldest first)
    backups = sorted(backups, key=lambda f: f.stat().st_mtime)

    # Delete oldest backups if there are more than `max_backups`
    while len(backups) > max_backups:
        oldest_backup = backups.pop(0)
        try:
            oldest_backup.unlink()
            print(f"🗑️ Deleted oldest backup: {oldest_backup}")
        except OSError as e:
            print(f"❌ Error deleting backup file {oldest_backup}: {e}")

def build_file_url():
    """
    Build the correct Microsoft Graph API URL for accessing the file.
    Supports two patterns:
    1. Site ID: /sites/{site-id}/drive/root:/{file-path}
    2. Site path: /sites/{hostname}:/{site-path}:/drive/root:/{file-path}
    """
    # URL-encode the file path
    encoded_file_path = quote(SHAREPOINT_FILE_PATH)
    
    # If SHAREPOINT_SITE_PATH is provided, use the site path pattern
    if SHAREPOINT_SITE_PATH:
        encoded_site_path = quote(SHAREPOINT_SITE_PATH.strip('/'))
        url = f"{GRAPH_API_URL}/sites/{SHAREPOINT_SITE}:/{encoded_site_path}:/drive/root:/{encoded_file_path}"
    else:
        # Assume SHAREPOINT_SITE is a site ID
        url = f"{GRAPH_API_URL}/sites/{SHAREPOINT_SITE}/drive/root:/{encoded_file_path}"
    
    return url

def download_file_from_sharepoint(local_path_str):
    """
    Download the most recent file from SharePoint using Microsoft Graph API.
    """
    local_path = Path(local_path_str)
    
    try:
        # Create the parent directory if it doesn't exist
        local_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Check if the file already exists
        if local_path.exists():
            # Rename the existing file to create a backup
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_file_path = Path(str(local_path) + f".{timestamp}.bak")
            
            try:
                local_path.rename(backup_file_path)
                print(f"⚠️ Existing file renamed to: {backup_file_path.name}")
            except OSError as e:
                print(f"❌ Error creating backup for {local_path}: {e}")
                sys.exit(1)

            # Manage backups to ensure no more than 3 backups are kept
            manage_backups(local_path_str, max_backups=3)

        # Build the file metadata URL
        file_metadata_url = build_file_url()
        print(f"📍 Fetching metadata from: {file_metadata_url}")
        response = requests.get(file_metadata_url, headers=HEADERS, timeout=30)

        if response.status_code != 200:
            print(f"❌ Error fetching file metadata: {response.status_code} - {response.text}")
            sys.exit(1)

        file_metadata = response.json()
        download_url = file_metadata.get("@microsoft.graph.downloadUrl")
        if not download_url:
            print("❌ Error: Download URL not found in metadata.")
            sys.exit(1)

        # Download the file
        print(f"📥 Downloading file...")
        file_response = requests.get(download_url, stream=True, timeout=60)
        file_response.raise_for_status()

        with local_path.open("wb") as file:
            for chunk in file_response.iter_content(chunk_size=8192):
                file.write(chunk)
            
        print(f"✅ File downloaded successfully: {local_path}")

    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")
        sys.exit(1)

# Local path to save the file
local_file_path = os.getenv("VDI_FILE_PATH", "VDI to Horizon Notes.xlsx")

# Download the file
download_file_from_sharepoint(local_file_path)
