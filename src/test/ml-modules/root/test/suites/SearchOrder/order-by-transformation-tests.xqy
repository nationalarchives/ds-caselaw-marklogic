xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare function local:search($order as xs:string) {
  search-test:search(
    map:entry("q", "orderfixture") => map:with("order", $order)
  )
};

(: Transform dates are a third permutation, distinct from decision date and
   last-modified, so accidental sort-parameter swaps fail loudly:
     middle  2020-03-01
     newest  2021-03-01
     oldest  2022-03-01
     undated 2023-03-01
   Docs with a transform date still appear even when decision date is missing. :)
let $ascending := local:search("transformation")
let $descending := local:search("-transformation")

let $ascending-uris := for $r in $ascending//search:result return string($r/@uri)
let $descending-uris := for $r in $descending//search:result return string($r/@uri)

return (
  test:assert-equal("4", string($ascending//@total)),
  test:assert-equal("/order/middle.xml", $ascending-uris[1]),
  test:assert-equal("/order/newest.xml", $ascending-uris[2]),
  test:assert-equal("/order/oldest.xml", $ascending-uris[3]),
  test:assert-equal("/order/undated.xml", $ascending-uris[4]),
  test:assert-equal("4", string($descending//@total)),
  test:assert-equal("/order/undated.xml", $descending-uris[1]),
  test:assert-equal("/order/oldest.xml", $descending-uris[2]),
  test:assert-equal("/order/newest.xml", $descending-uris[3]),
  test:assert-equal("/order/middle.xml", $descending-uris[4])
)
