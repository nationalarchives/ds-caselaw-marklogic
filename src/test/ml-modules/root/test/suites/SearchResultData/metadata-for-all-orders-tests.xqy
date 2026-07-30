xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

declare function local:sorted-strings($values as xs:string*) as xs:string* {
  for $v in $values order by $v return $v
};

declare function local:assert-result-metadata($response) {
  let $results := $response//search:result
  let $element-extracts := $results/search:extracted[(not(@kind) or @kind = "element")]
  let $titles := local:sorted-strings(
    for $v in $element-extracts//akn:FRBRname/@value return string($v)
  )
  let $courts := local:sorted-strings(
    for $v in $element-extracts//uk:court return string($v)
  )
  let $dates := local:sorted-strings(
    for $v in $element-extracts//akn:FRBRdate[@name="decision"]/@date return string($v)
  )
  let $ids := local:sorted-strings(
    for $v in $results/search:extracted[@kind="identifiers"]/identifiers/identifier/value return string($v)
  )
  let $slugs := local:sorted-strings(
    for $v in $results/search:extracted[@kind="identifiers"]/identifiers/identifier/url_slug return string($v)
  )
  return (
    test:assert-equal("2", string($response//@total)),
    test:assert-equal(2, fn:count($results)),
    test:assert-equal(0, fn:count($results/search:extracted-none)),
    test:assert-equal(2, fn:count($element-extracts)),
    test:assert-equal(("Result Data One", "Result Data Two"), $titles),
    test:assert-equal(("EWHC-Chancery", "EWHC-Family"), $courts),
    test:assert-equal(("2021-05-01", "2022-07-15"), $dates),
    test:assert-equal(2, fn:count($results/search:extracted[@kind="identifiers"])),
    test:assert-equal(("rdoneaaa", "rdtwobbb"), $ids),
    test:assert-equal(("result-data/one", "result-data/two"), $slugs),
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
