import os
import shutil
import socket
import subprocess
import time

import pytest
import requests

_EMULATOR_HOST = "localhost:8080"
_TEST_PROJECT = "music-stats-test"


def _port_open(host: str, port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        return sock.connect_ex((host, port)) == 0


@pytest.fixture(scope="session")
def firestore_emulator():
    if shutil.which("gcloud") is None:
        pytest.skip("gcloud CLI not installed; skipping Firestore emulator tests")

    host, port_str = _EMULATOR_HOST.split(":")
    port = int(port_str)

    if _port_open(host, port):
        pytest.skip(
            f"Something is already listening on {_EMULATOR_HOST}; "
            "refusing to reuse it for tests"
        )

    process = subprocess.Popen(
        ["gcloud", "emulators", "firestore", "start", f"--host-port={_EMULATOR_HOST}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        start_new_session=True,
    )

    deadline = time.monotonic() + 30
    started = False
    while time.monotonic() < deadline:
        if _port_open(host, port):
            started = True
            break
        if process.poll() is not None:
            break
        time.sleep(0.5)

    if not started:
        process.terminate()
        output = process.stdout.read() if process.stdout else ""
        pytest.skip(
            "Firestore emulator did not start within 30s. Is the "
            "cloud-firestore-emulator gcloud component installed? "
            f"Output:\n{output}"
        )

    os.environ["FIRESTORE_EMULATOR_HOST"] = _EMULATOR_HOST
    os.environ["GOOGLE_CLOUD_PROJECT"] = _TEST_PROJECT

    yield _EMULATOR_HOST

    os.killpg(os.getpgid(process.pid), 15)
    process.wait(timeout=10)
    del os.environ["FIRESTORE_EMULATOR_HOST"]
    del os.environ["GOOGLE_CLOUD_PROJECT"]


@pytest.fixture
def clear_firestore(firestore_emulator):
    url = (
        f"http://{firestore_emulator}/emulator/v1/projects/"
        f"{_TEST_PROJECT}/databases/(default)/documents"
    )
    requests.delete(url, timeout=5)
    yield
    requests.delete(url, timeout=5)
