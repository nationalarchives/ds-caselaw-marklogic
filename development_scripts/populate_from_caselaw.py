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

import requests

urls = [
    "ewhc/qb/2020/594",
    "ewca/civ/2003/1048",
    "ewca/civ/2003/1489",
    "ewca/civ/2003/48",
    "eat/2023/1",
    "eat/2023/2",
]

for url in urls:
    ml_url = f"/{url}.xml"
    print(url)
    response = requests.get(f"https://caselaw.nationalarchives.gov.uk/{url}/data.xml")
    response.raise_for_status()
    xml = response.content
    print("got xml")

    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=xml,
    )
    response.raise_for_status()
    print("added to local Marklogic db")
