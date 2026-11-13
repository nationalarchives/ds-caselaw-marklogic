#!/usr/bin/env python3
# ruff: noqa: S311
"""Populate local MarkLogic with a small set of publication metrics fixtures."""

import argparse
import os
import random
from calendar import monthrange
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

import requests

DOCUMENT_COUNT = 18
METRICS_COLLECTION = "metrics-seed"
SECONDS_PER_HOUR = 60 * 60
RAPI_NAMESPACE = "http://marklogic.com/rest-api"
PROPERTY_NAMESPACE = "http://marklogic.com/xdmp/property"
POSITIVE_INTEGER_ERROR = "must be at least 1"
COURTS = (
    ("uksc", "Supreme Court"),
    ("ewca/civ", "Court of Appeal (Civil Division)"),
    ("eat", "Employment Appeal Tribunal"),
)


@dataclass(frozen=True)
class SeedDocument:
    index: int
    court: str
    court_name: str
    decision_date: date
    transfer_received_at: datetime
    first_published_at: datetime
    latest_published_at: datetime
    submissions_before_first_publish: int

    @property
    def tdr_to_first_publish(self) -> int:
        return int((self.first_published_at - self.transfer_received_at).total_seconds())

    @property
    def tdr_to_latest_publish(self) -> int:
        return int((self.latest_published_at - self.transfer_received_at).total_seconds())

    @property
    def uri(self) -> str:
        return f"/metrics-seed/{self.index:03d}.xml"

    @property
    def citation(self) -> str:
        return f"[{self.decision_date.year}] METRICS {self.index:03d}"

    @property
    def title(self) -> str:
        return f"Metrics seed document {self.index:03d} - {self.court_name}"


def subtract_months(value: date, months: int) -> date:
    month_index = value.year * 12 + value.month - 1 - months
    year, zero_based_month = divmod(month_index, 12)
    month = zero_based_month + 1
    return value.replace(year=year, month=month, day=min(value.day, monthrange(year, month)[1]))


def random_datetime_in_segment(
    rng: random.Random,
    *,
    start: datetime,
    end: datetime,
    index: int,
    count: int,
) -> datetime:
    total_seconds = int((end - start).total_seconds())
    segment_start = total_seconds * index // count
    segment_end = total_seconds * (index + 1) // count
    return start + timedelta(seconds=rng.randint(segment_start, max(segment_start, segment_end - 1)))


def build_seed_documents(*, count: int, rng: random.Random, now: datetime) -> list[SeedDocument]:
    start_date = subtract_months(now.date(), 3)
    start = datetime.combine(start_date, datetime.min.time(), tzinfo=UTC)
    end = now - timedelta(minutes=1)
    documents = []

    for offset in range(count):
        first_published_at = random_datetime_in_segment(rng, start=start, end=end, index=offset, count=count)
        first_duration = (
            rng.randint(25, 72) * SECONDS_PER_HOUR if offset % 4 == 0 else rng.randint(2, 23) * SECONDS_PER_HOUR
        )
        latest_published_at = min(
            first_published_at + timedelta(days=rng.randint(0, 10), hours=rng.randint(0, 23)),
            now,
        )
        court, court_name = COURTS[offset % len(COURTS)]
        documents.append(
            SeedDocument(
                index=offset + 1,
                court=court,
                court_name=court_name,
                decision_date=first_published_at.date(),
                transfer_received_at=first_published_at - timedelta(seconds=first_duration),
                first_published_at=first_published_at,
                latest_published_at=latest_published_at,
                submissions_before_first_publish=rng.randint(1, 4),
            ),
        )

    return documents


def build_content(document: SeedDocument) -> bytes:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0"
             xmlns:uk="https://caselaw.nationalarchives.gov.uk/akn">
  <judgment name="decision">
    <meta>
      <identification source="#tna">
        <FRBRWork>
          <FRBRthis value="https://caselaw.nationalarchives.gov.uk/id/metrics-seed/{document.index:03d}"/>
          <FRBRuri value="https://caselaw.nationalarchives.gov.uk/id/metrics-seed/{document.index:03d}"/>
          <FRBRdate date="{document.decision_date.isoformat()}" name="judgment"/>
          <FRBRauthor href="#tna"/>
          <FRBRcountry value="GB-ENG"/>
          <FRBRname value="{escape(document.title)}"/>
        </FRBRWork>
      </identification>
      <proprietary source="#tna">
        <uk:court>{escape(document.court)}</uk:court>
        <uk:year>{document.decision_date.year}</uk:year>
        <uk:name>{escape(document.title)}</uk:name>
        <uk:cite>{escape(document.citation)}</uk:cite>
      </proprietary>
    </meta>
    <header><p>{escape(document.title)}</p></header>
    <judgmentBody><section><p>Generated local metrics fixture.</p></section></judgmentBody>
  </judgment>
</akomaNtoso>
""".encode()


def add_text_element(parent: ET.Element, name: str, value: object) -> None:
    ET.SubElement(parent, name).text = str(value)


def build_properties(document: SeedDocument) -> bytes:
    ET.register_namespace("rapi", RAPI_NAMESPACE)
    ET.register_namespace("prop", PROPERTY_NAMESPACE)
    metadata = ET.Element(f"{{{RAPI_NAMESPACE}}}metadata")
    properties = ET.SubElement(metadata, f"{{{PROPERTY_NAMESPACE}}}properties")
    add_text_element(properties, "source-organisation", "The National Archives metrics seed")
    add_text_element(properties, "source-name", "Local metrics seed")
    add_text_element(properties, "source-email", "metrics-seed@example.invalid")
    add_text_element(properties, "transfer-consignment-reference", f"TDR-METRICS-{document.index:03d}")
    add_text_element(properties, "transfer-received-at", document.transfer_received_at.isoformat())
    add_text_element(properties, "first_submission_datetime", document.transfer_received_at.isoformat())
    add_text_element(properties, "latest_submission_datetime", document.transfer_received_at.isoformat())
    add_text_element(properties, "first_submission_tdr_receipt_datetime", document.transfer_received_at.isoformat())
    add_text_element(properties, "published", "true")
    add_text_element(properties, "first_published_datetime", document.first_published_at.isoformat())
    add_text_element(properties, "latest_published_datetime", document.latest_published_at.isoformat())

    metrics = ET.SubElement(properties, "metrics")
    add_text_element(metrics, "tdr_to_first_publish", document.tdr_to_first_publish)
    add_text_element(metrics, "tdr_to_latest_publish", document.tdr_to_latest_publish)
    add_text_element(metrics, "submissions_before_first_publish", document.submissions_before_first_publish)

    identifiers = ET.SubElement(properties, "identifiers")
    identifier = ET.SubElement(identifiers, "identifier")
    add_text_element(identifier, "namespace", "ukncn")
    add_text_element(identifier, "uuid", f"metrics-seed-{document.index:03d}")
    add_text_element(identifier, "value", document.citation)
    add_text_element(identifier, "url_slug", f"metrics-seed/{document.index:03d}")
    ET.SubElement(properties, f"{{{PROPERTY_NAMESPACE}}}last-modified").text = datetime.now(UTC).isoformat()
    return ET.tostring(metadata, xml_declaration=True, encoding="UTF-8")


def raise_for_status(response: requests.Response) -> None:
    try:
        response.raise_for_status()
    except requests.HTTPError:
        print(response.text)
        raise


def clear_existing_documents(session: requests.Session, base_url: str) -> None:
    xquery = f"""xquery version "1.0-ml";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
for $document in cts:search(fn:collection(), cts:collection-query("{METRICS_COLLECTION}"), "unfiltered")
let $uri := xdmp:node-uri($document)
where fn:not(fn:contains($uri, "_xml_versions/"))
return
  if (dls:document-is-managed($uri)) then
    dls:document-delete($uri, fn:false(), fn:false())
  else
    xdmp:document-delete($uri)
"""
    response = session.post(f"{base_url}/LATEST/eval", data={"xquery": xquery})
    raise_for_status(response)


def manage_document(session: requests.Session, base_url: str, uri: str) -> None:
    xquery = f"""xquery version "1.0-ml";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
if (dls:document-is-managed("{uri}")) then () else dls:document-manage("{uri}", fn:false())
"""
    response = session.post(f"{base_url}/LATEST/eval", data={"xquery": xquery})
    raise_for_status(response)


def insert_document(session: requests.Session, base_url: str, document: SeedDocument) -> None:
    response = session.put(
        f"{base_url}/LATEST/documents",
        params=(("uri", document.uri), ("collection", "judgment"), ("collection", METRICS_COLLECTION)),
        data=build_content(document),
        headers={"Content-Type": "application/xml"},
    )
    raise_for_status(response)

    response = session.put(
        f"{base_url}/LATEST/documents",
        params={"uri": document.uri, "category": "properties"},
        data=build_properties(document),
        headers={"Content-Type": "application/xml"},
    )
    raise_for_status(response)
    manage_document(session, base_url, document.uri)


def positive_integer(value: str) -> int:
    parsed = int(value)
    if parsed < 1:
        raise argparse.ArgumentTypeError(POSITIVE_INTEGER_ERROR)
    return parsed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", default=8011, type=int)
    parser.add_argument("--username", default=os.getenv("MARKLOGIC_USER", "admin"))
    parser.add_argument("--password", default=os.getenv("MARKLOGIC_PASSWORD", "admin"))
    parser.add_argument("--count", default=DOCUMENT_COUNT, type=positive_integer)
    parser.add_argument("--seed", type=int, help="Reuse a printed seed to reproduce the same values")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    seed = args.seed if args.seed is not None else random.SystemRandom().randrange(2**32)
    rng = random.Random(seed)
    now = datetime.now(UTC)
    documents = build_seed_documents(count=args.count, rng=rng, now=now)
    base_url = f"http://{args.host}:{args.port}"
    session = requests.Session()
    session.auth = (args.username, args.password)

    print(f"Replacing the '{METRICS_COLLECTION}' collection at {base_url}")
    print(f"Random seed: {seed}")
    clear_existing_documents(session, base_url)
    for document in documents:
        insert_document(session, base_url, document)
        print(f"Created {document.uri} ({document.court}, {document.first_published_at.date()})")
    print(f"Created {len(documents)} metrics seed documents.")


if __name__ == "__main__":
    main()
