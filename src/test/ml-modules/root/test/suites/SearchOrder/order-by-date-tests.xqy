xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare function local:search($order as xs:string) {
  search-test:search(
    map:entry("q", "orderfixture") => map:with("order", $order)
  )
};

let $ascending := local:search("date")
let $descending := local:search("-date")

let $ascending-uris := for $r in $ascending//search:result return string($r/@uri)
let $descending-uris := for $r in $descending//search:result return string($r/@uri)

return (
  test:assert-equal("3", string($ascending//@total)),
  test:assert-equal("/order/oldest.xml", $ascending-uris[1]),
  test:assert-equal("/order/middle.xml", $ascending-uris[2]),
  test:assert-equal("/order/newest.xml", $ascending-uris[3]),
  test:assert-equal("3", string($descending//@total)),
  test:assert-equal("/order/newest.xml", $descending-uris[1]),
  test:assert-equal("/order/middle.xml", $descending-uris[2]),
  test:assert-equal("/order/oldest.xml", $descending-uris[3])
)
