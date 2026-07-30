xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare function local:uris($response) as xs:string* {
  for $r in $response//search:result return string($r/@uri)
};

declare function local:search-with-court($court as xs:string) {
  search-test:search(
    map:entry("q", "filterfixture")
      => map:with("court", json:to-array($court))
  )
};

let $chancery := local:search-with-court("EWHC-Chancery")
let $chancery-uris := local:uris($chancery)

let $family := local:search-with-court("EWHC-Family")
let $family-uris := local:uris($family)

return (
  test:assert-equal("2", string($chancery//@total)),
  test:assert-true($chancery-uris = "/filter/ch-2020.xml"),
  test:assert-true($chancery-uris = "/filter/ch-2022.xml"),
  test:assert-true(fn:not($chancery-uris = "/filter/fam-2020.xml")),

  test:assert-equal("1", string($family//@total)),
  test:assert-equal("/filter/fam-2020.xml", $family-uris[1])
)
