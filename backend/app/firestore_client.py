import logging
import os
from datetime import datetime, timezone

from google.cloud import firestore
from google.cloud.firestore_v1.transaction import Transaction

logger = logging.getLogger(__name__)

_COLLECTION_NAME = "users"


def _get_client() -> firestore.Client:
    project = os.environ.get("GOOGLE_CLOUD_PROJECT", "music-stats-dev")
    return firestore.Client(project=project)


@firestore.transactional
def _upsert_in_transaction(
    transaction: Transaction,
    doc_ref: firestore.DocumentReference,
    email: str,
    name: str,
    now: str,
) -> dict:
    snapshot = doc_ref.get(transaction=transaction)
    created_at = snapshot.get("created_at") if snapshot.exists else now

    data = {
        "email": email,
        "name": name,
        "created_at": created_at,
        "updated_at": now,
    }
    transaction.set(doc_ref, data, merge=True)
    return data


def upsert_user(user_id: str, email: str | None, name: str | None) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    client = _get_client()
    doc_ref = client.collection(_COLLECTION_NAME).document(user_id)

    try:
        return _upsert_in_transaction(client.transaction(), doc_ref, email or "", name or "", now)
    except Exception as exc:
        logger.error("Firestore upsert failed for user %s: %r", user_id, exc)
        raise
