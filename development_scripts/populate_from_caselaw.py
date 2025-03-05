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

urls = [
    "ewhc/qb/2020/594",
    "ewca/civ/2003/1048",
    "ewca/civ/2003/1489",
    "ewca/civ/2003/48",
    "eat/2023/2",
]


def test_response(response):
    try:
        response.raise_for_status()
    except Exception:
        print("Content of server response:")
        print(response.content)
        raise


for url in urls:
    ml_url = f"/{url}.xml"
    print(url)
    response = requests.get(f"https://caselaw.nationalarchives.gov.uk/{url}/data.xml")
    test_response(response)
    xml = response.content
    print("got xml")

    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=xml,
    )
    test_response(response)
    print("added to local Marklogic db")

for filename in ["eat-2023-1"]:
    ml_url = "/" + filename.replace("-", "/") + ".xml"
    with Path(f"development_scripts/fixtures/{filename}-content.xml").open() as f:
        content = f.read()
    with Path(f"development_scripts/fixtures/{filename}-properties.xml").open() as f:
        properties = f.read()
    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=content,
    )
    test_response(response)
    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&category=properties",
        data=properties,
    )
    test_response(response)

    xquery = f"""
    xquery version "1.0-ml";
    import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
    dls:document-manage("{ml_url}", fn:false())
    """

    response = requests.post("http://admin:admin@localhost:8011/LATEST/eval", data={"xquery": xquery})

    print(response.content)
    print(f"added {filename} to local Marklogic db")
