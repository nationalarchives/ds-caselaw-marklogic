xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

(: Six fixtures, page-size 2 — covers documents-scoped (date) and properties-
   scoped (updated) paging, including an empty page past the end. :)

declare function local:uris($response) as xs:string* {
  for $r in $response//search:result return string($r/@uri)
};

declare function local:search($order as xs:string, $page as xs:integer) {
  search-test:search(
    map:entry("q", "paginationfixture")
      => map:with("order", $order)
      => map:with("page", $page)
      => map:with("page-size", 2)
  )
};

declare function local:assert-page(
  $response,
  $expected-start as xs:integer,
  $expected-uris as xs:string*
) {
  let $results := $response//search:result
  let $expected-count := fn:count($expected-uris)
  return (
    test:assert-equal("6", string($response//@total)),
    test:assert-equal(string($expected-start), string($response//@start)),
    test:assert-equal($expected-count, fn:count($results)),
    test:assert-equal($expected-uris, local:uris($response)),
    (: Documents-scoped resolve keeps requested page-length even past the end;
       only assert @page-length when the page has results. :)
    if ($expected-count gt 0) then
      test:assert-equal(string($expected-count), string($response//@page-length))
    else (),
    test:assert-equal(0, fn:count($results/search:extracted-none)),
    test:assert-equal($expected-count, fn:count($results/search:extracted[(not(@kind) or @kind = "element")]//akn:FRBRname/@value)),
    test:assert-equal($expected-count, fn:count($results/search:extracted[@kind="identifiers"]/identifiers/identifier))
  )
};

let $ordered := (
  "/pagination/a.xml",
  "/pagination/b.xml",
  "/pagination/c.xml",
  "/pagination/d.xml",
  "/pagination/e.xml",
  "/pagination/f.xml"
)

let $orders := ("date", "updated")

let $page-assertions :=
  for $order in $orders
  return (
    local:assert-page(local:search($order, 1), 1, $ordered[1 to 2]),
    local:assert-page(local:search($order, 2), 3, $ordered[3 to 4]),
    local:assert-page(local:search($order, 3), 5, $ordered[5 to 6]),
    (: Past the end: total still 6, no results. :)
    local:assert-page(local:search($order, 4), 7, ())
  )

return $page-assertions
