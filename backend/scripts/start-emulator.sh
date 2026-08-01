#!/usr/bin/env bash
# Starts the Firestore emulator for local backend development.
#
# In another shell, run the API against it with:
#   export FIRESTORE_EMULATOR_HOST=localhost:8080
#   uvicorn app.main:app --reload
set -euo pipefail

if ! gcloud components list --filter="id:cloud-firestore-emulator" --format="value(state.name)" | grep -q "Installed"; then
  echo "Installing gcloud Firestore emulator component..." >&2
  gcloud components install cloud-firestore-emulator --quiet
fi

exec gcloud emulators firestore start --host-port=localhost:8080
