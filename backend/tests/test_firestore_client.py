import pytest

from app.firestore_client import upsert_user

pytestmark = pytest.mark.usefixtures("clear_firestore")


def test_upsert_creates_new_user():
    result = upsert_user("auth0|new-user", "user@example.com", "Test User")

    assert result["email"] == "user@example.com"
    assert result["name"] == "Test User"
    assert result["created_at"] == result["updated_at"]


def test_upsert_preserves_created_at_on_update():
    first = upsert_user("auth0|existing-user", "old@example.com", "Old Name")
    second = upsert_user("auth0|existing-user", "new@example.com", "New Name")

    assert second["created_at"] == first["created_at"]
    assert second["updated_at"] != first["created_at"]
    assert second["email"] == "new@example.com"
    assert second["name"] == "New Name"


def test_upsert_handles_missing_optional_fields():
    result = upsert_user("auth0|minimal-user", None, None)

    assert result["email"] == ""
    assert result["name"] == ""
