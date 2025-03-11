#!python3
"""
This script retrieves XML data from the live TNA caselaw website and updates a local MarkLogic database.

Assumptions about the local MarkLogic server:
- is running accessible at 'localhost:8011'
- uses the default admin username and password ('admin:admin') for authentication.

Usage:
- Modify the list of URLs to match the desired URLs from the live caselaw website.
- Ensure the MarkLogic server is running and accessible at 'localhost:8011'.
- Run the script.
"""

from pathlib import Path

import requests

URLS_TO_IMPORT = [
    "ewhc/qb/2020/594",
    "ewca/civ/2003/1048",
    "ewca/civ/2003/1489",
    "ewca/civ/2003/48",
]

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


def load_fixture_from_url(url: str) -> None:
    print(f"> Loading {url} from URL…")

    ml_url = f"/{url}.xml"

    response = requests.get(f"https://caselaw.nationalarchives.gov.uk/{url}/data.xml")
    test_response(response)
    xml = response.content
    print(">> Downloaded XML…")

    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=xml,
    )
    test_response(response)
    print(">> ✅ Saved to MarkLogic")


def load_fixture_from_files(file_prefix: str) -> None:
    print(f"> Loading {filename} from filesystem…")

    ml_url = "/" + filename.replace("-", "/") + ".xml"

    with Path("development_scripts", "fixture_data", f"{filename}-content.xml").open() as f:
        content = f.read()
    with Path("development_scripts", "fixture_data", f"{filename}-properties.xml").open() as f:
        properties = f.read()

    print(">> Source files read to memory…")

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

print("Loading fixtures from URLs…")
for url in URLS_TO_IMPORT:
    load_fixture_from_url(url)

print("Loading fixtures from files…")
for filename in FIXTURE_FILES_TO_IMPORT:
    load_fixture_from_files(file_prefix=filename)
