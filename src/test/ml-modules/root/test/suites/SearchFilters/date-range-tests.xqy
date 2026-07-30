xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare function local:uris($response) as xs:string* {
  for $r in $response//search:result return string($r/@uri)
};

let $year-2020 := search-test:search(
  map:entry("q", "filterfixture")
    => map:with("from", "2020-01-01")
    => map:with("to", "2020-12-31")
)
let $year-2020-uris := local:uris($year-2020)

let $year-2022 := search-test:search(
  map:entry("q", "filterfixture")
    => map:with("from", "2022-01-01")
    => map:with("to", "2022-12-31")
)
let $year-2022-uris := local:uris($year-2022)

let $chancery-2020 := search-test:search(
  map:entry("q", "filterfixture")
    => map:with("court", json:to-array("EWHC-Chancery"))
    => map:with("from", "2020-01-01")
    => map:with("to", "2020-12-31")
)
let $chancery-2020-uris := local:uris($chancery-2020)

return (
  test:assert-equal("2", string($year-2020//@total)),
  test:assert-true($year-2020-uris = "/filter/ch-2020.xml"),
  test:assert-true($year-2020-uris = "/filter/fam-2020.xml"),
  test:assert-true(fn:not($year-2020-uris = "/filter/ch-2022.xml")),

  test:assert-equal("1", string($year-2022//@total)),
  test:assert-equal("/filter/ch-2022.xml", $year-2022-uris[1]),

  test:assert-equal("1", string($chancery-2020//@total)),
  test:assert-equal("/filter/ch-2020.xml", $chancery-2020-uris[1])
)
