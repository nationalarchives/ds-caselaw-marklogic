xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare function local:search-as-public-ui($order as xs:string) {
  search-test:search-as-public-ui(
    map:entry("q", "orderfixture") => map:with("order", $order)
  )
};

(: Document-scoped sorts work for the Public UI reader surrogate (caselaw-public-ui-test). :)
let $date-ascending := local:search-as-public-ui("date")
let $date-ascending-uris := for $r in $date-ascending//search:result return string($r/@uri)

(: Updated sort uses properties fragment-scope and prop:last-modified — the path
   the Public UI reader account uses in production (tested via caselaw-public-ui-test). :)
let $ascending := local:search-as-public-ui("updated")
let $descending := local:search-as-public-ui("-updated")

let $ascending-uris := for $r in $ascending//search:result return string($r/@uri)
let $descending-uris := for $r in $descending//search:result return string($r/@uri)

return (
  test:assert-equal("3", string($date-ascending//@total)),
  test:assert-equal("/order/oldest.xml", $date-ascending-uris[1]),
  test:assert-equal("/order/middle.xml", $date-ascending-uris[2]),
  test:assert-equal("/order/newest.xml", $date-ascending-uris[3]),
  test:assert-equal("4", string($ascending//@total)),
  test:assert-equal("/order/newest.xml", $ascending-uris[1]),
  test:assert-equal("/order/middle.xml", $ascending-uris[2]),
  test:assert-equal("/order/oldest.xml", $ascending-uris[3]),
  test:assert-equal("/order/undated.xml", $ascending-uris[4]),
  test:assert-equal("4", string($descending//@total)),
  test:assert-equal("/order/undated.xml", $descending-uris[1]),
  test:assert-equal("/order/oldest.xml", $descending-uris[2]),
  test:assert-equal("/order/middle.xml", $descending-uris[3]),
  test:assert-equal("/order/newest.xml", $descending-uris[4])
)
