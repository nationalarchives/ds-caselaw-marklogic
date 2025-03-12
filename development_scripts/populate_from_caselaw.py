#!python3
"""
This script loads document fixture files into the MarkLogic database.

Assumptions about the local MarkLogic server:
- is running accessible at 'localhost:8011'
- uses the default admin username and password ('admin:admin') for authentication.

Usage:
- Get both the document XML and properties XML for documents you wish to load, and **perform necessary anonymisation work** (particularly with things like submission data).
- Modify the list of fixture files to match those in the `fixture_data` folder you want to load.
- Ensure the MarkLogic server is running and accessible at 'localhost:8011'.
- Run the script.
"""

from pathlib import Path

import requests

FIXTURE_FILES_TO_IMPORT = [
    "eat-2023-1",
    "eat-2023-2",
]


def test_response(response):
    try:
        response.raise_for_status()
    except Exception:
        print("🔴 EXCEPTION")
        print("Content of server response:")
        print(response.content)
        raise


def load_fixture_from_files(file_prefix: str) -> None:
    print(f"> Loading {filename} from filesystem…")

    ml_url = "/" + filename.replace("-", "/") + ".xml"

    with Path("development_scripts", "fixture_data", f"{filename}-content.xml").open("rb") as f:
        content = f.read()
    with Path("development_scripts", "fixture_data", f"{filename}-properties.xml").open("rb") as f:
        properties = f.read()

    print(f">> Source files read to memory… ({len(content)}, {len(properties)} bytes)")

    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=content,
    )
    test_response(response)
    print(">> Saved source document to MarkLogic…")

    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&category=properties",
        data=properties,
    )
    test_response(response)
    print(">> Saved properties document to MarkLogic…")

    xquery = f"""
    xquery version "1.0-ml";
    import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
    dls:document-manage("{ml_url}", fn:false())
    """

    response = requests.post("http://admin:admin@localhost:8011/LATEST/eval", data={"xquery": xquery})
    test_response(response)
    print(">> Set as managed document…")

    print(">> ✅ Saved to MarkLogic")


print("Beginning fixture import…")

for filename in FIXTURE_FILES_TO_IMPORT:
    load_fixture_from_files(file_prefix=filename)
