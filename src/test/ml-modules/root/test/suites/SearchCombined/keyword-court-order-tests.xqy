xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

(: Keyword + court filter + order, for both document-sortable and updated paths. :)

declare function local:uris($response) as xs:string* {
  for $r in $response//search:result return string($r/@uri)
};

declare function local:search($order as xs:string) {
  search-test:search(
    map:entry("q", "combinedfixture")
      => map:with("court", json:to-array("EWHC-Chancery"))
      => map:with("order", $order)
  )
};

declare function local:assert-metadata($response) {
  let $results := $response//search:result
  let $element-extracts := $results/search:extracted[(not(@kind) or @kind = "element")]
  return (
    test:assert-equal("2", string($response//@total)),
    test:assert-equal(2, fn:count($results)),
    test:assert-true(fn:not(local:uris($response) = "/combined/fam-2020.xml")),
    test:assert-equal(0, fn:count($results/search:extracted-none)),
    test:assert-equal(2, fn:count($element-extracts)),
    test:assert-equal(2, fn:count($element-extracts//akn:FRBRname/@value)),
    test:assert-equal(2, fn:count($element-extracts//uk:court)),
    test:assert-equal(2, fn:count($results/search:extracted[@kind="identifiers"])),
    test:assert-equal(2, fn:count($results/search:extracted[@kind="identifiers"]/identifiers/identifier))
  )
};

let $date-asc := local:search("date")
let $date-desc := local:search("-date")
let $updated-asc := local:search("updated")
let $updated-desc := local:search("-updated")

let $date-asc-uris := local:uris($date-asc)
let $date-desc-uris := local:uris($date-desc)
let $updated-asc-uris := local:uris($updated-asc)
let $updated-desc-uris := local:uris($updated-desc)

return (
  local:assert-metadata($date-asc),
  test:assert-equal("/combined/ch-2020.xml", $date-asc-uris[1]),
  test:assert-equal("/combined/ch-2022.xml", $date-asc-uris[2]),

  local:assert-metadata($date-desc),
  test:assert-equal("/combined/ch-2022.xml", $date-desc-uris[1]),
  test:assert-equal("/combined/ch-2020.xml", $date-desc-uris[2]),

  (: setup.xqy: ch-2022 touched first → oldest last-modified. :)
  local:assert-metadata($updated-asc),
  test:assert-equal("/combined/ch-2022.xml", $updated-asc-uris[1]),
  test:assert-equal("/combined/ch-2020.xml", $updated-asc-uris[2]),

  local:assert-metadata($updated-desc),
  test:assert-equal("/combined/ch-2020.xml", $updated-desc-uris[1]),
  test:assert-equal("/combined/ch-2022.xml", $updated-desc-uris[2])
)
