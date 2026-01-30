import requests
import os

class AirbyteClient:

    def __init__(self, base_url: str, workspace_id: str):
        self.base_url = base_url.rstrip("/")
        self.workspace_id = workspace_id

    def get_airbyte_access_token(self) -> str:
        client_id = os.getenv("AIRBYTE_CLIENT_ID")
        client_secret = os.getenv("AIRBYTE_CLIENT_SECRET")

        if not client_id or not client_secret:
            raise RuntimeError("AIRBYTE_CLIENT_ID or AIRBYTE_CLIENT_SECRET not set")

        response = requests.post(
            f"{self.base_url}/applications/token",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={
                "client_id": client_id,
                "client_secret": client_secret,
                "grant-type": "client_credentials",
            },
            timeout=30,
        )

        response.raise_for_status()
        token = response.json().get("access_token")

        if not token:
            raise RuntimeError("❌ Failed to retrieve access token")

        return token

    def list_connections(self):
        access_token = self.get_airbyte_access_token()

        r = requests.post(
            f"{self.base_url}/connections/list",
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={"workspaceId": self.workspace_id},
            timeout=30,
        )
        r.raise_for_status()
        return r.json()["connections"]

    def trigger_sync(self, connection_id: str):
        r = requests.post(
            f"{self.base_url}/connections/sync",
            json={"connectionId": connection_id},
            timeout=30,
        )
        # already running
        if r.status_code == 409:
            return

        r.raise_for_status()
