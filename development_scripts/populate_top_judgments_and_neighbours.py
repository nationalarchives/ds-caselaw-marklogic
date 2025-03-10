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

import re
from urllib.parse import quote
from xml.etree import ElementTree as ET

import requests
from bs4 import BeautifulSoup

urls = [
    "ewca/civ/2022/1146",
    "ewfc/2022/89",
    "ewhc/ch/2023/320",
    "ewhc/kb/2023/963",
    "ewhc/kb/2023/822",
    "ewhc/fam/2023/399",
    "ewca/civ/2022/1047",
    "ewfc/2023/46",
    "ewfc/2022/95",
    "ewhc/admin/2006/815",
]


def get_judgment_xml(url):
    print(f"Getting judgment: {url}")
    response = requests.get(f"https://caselaw.nationalarchives.gov.uk/{url}/data.xml")
    response.raise_for_status()
    return response.content


def save_judgment_xml(url, xml):
    print(f"Saving judgment: {url}")
    ml_url = f"/{url}.xml"
    response = requests.put(
        f"http://admin:admin@localhost:8011/LATEST/documents?uri={ml_url}&collection=judgment",
        data=xml,
    )
    try:
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Something went wrong saving the judgment: {e}")


def get_neighbours_for_judgment(xml):
    tree = ET.fromstring(xml)
    ns = {"akn": "http://docs.oasis-open.org/legaldocml/ns/akn/3.0"}
    title = tree.find(
        "./akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRname",
        ns,
    ).attrib["value"]
    print(f"Getting neighbours for judgment title: {title}")
    search_url = "https://caselaw.nationalarchives.gov.uk/judgments/results?query=" + quote(title)
    search_results = requests.get(search_url)
    search_soup = BeautifulSoup(search_results.content, "html.parser")
    neighbours = list(re.sub(r"^\/", "", a["href"]) for a in search_soup.select(".judgment-listing__title a"))
    print(f"... found {len(neighbours)}")
    return neighbours


found = set()
for url in urls:
    xml = get_judgment_xml(url)
    save_judgment_xml(url, xml)
    found.add(url)
    for url2 in get_neighbours_for_judgment(xml):
        if url2 not in found:
            xml2 = get_judgment_xml(url2)
            save_judgment_xml(url2, xml2)
            found.add(url2)
        else:
            print(f"Skipping already imported judgment {url2}")
    print(f"**** {url} and close title matches added to local Marklogic db ****")
print(f"DONE. Imported {len(found)} judgments.")
