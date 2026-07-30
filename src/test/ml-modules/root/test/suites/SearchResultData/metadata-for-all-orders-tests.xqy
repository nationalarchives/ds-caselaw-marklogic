xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

declare function local:assert-result-metadata($response) {
  let $results := $response//search:result
  let $element-extracts := $results/search:extracted[(not(@kind) or @kind = "element")]
  return (
    test:assert-equal("2", string($response//@total)),
    test:assert-equal(2, fn:count($results)),
    test:assert-equal(0, fn:count($results/search:extracted-none)),
    test:assert-equal(2, fn:count($element-extracts)),
    test:assert-equal(2, fn:count($element-extracts//akn:FRBRname/@value)),
    test:assert-equal(2, fn:count($element-extracts//uk:court)),
    test:assert-equal(2, fn:count($element-extracts//akn:FRBRdate[@name="decision"])),
    test:assert-equal(2, fn:count($results/search:extracted[@kind="identifiers"])),
    test:assert-equal(2, fn:count($results/search:extracted[@kind="identifiers"]/identifiers/identifier)),
    (: Exactly one identifiers root per result. :)
    test:assert-equal(2, fn:count($results//identifiers))
  )
};

declare function local:search($order as xs:string?) {
  if (fn:empty($order) or $order = "") then
    search-test:search(map:entry("q", "resultdatafixture"))
  else
    search-test:search(
      map:entry("q", "resultdatafixture") => map:with("order", $order)
    )
};

let $orders := ("", "date", "-date", "updated", "-updated", "transformation", "-transformation")

let $assertions :=
  for $order in $orders
  return local:assert-result-metadata(local:search($order))

let $public-ui := search-test:search-as-public-ui(
  map:entry("q", "resultdatafixture") => map:with("order", "updated")
)

return (
  $assertions,
  local:assert-result-metadata($public-ui)
)
