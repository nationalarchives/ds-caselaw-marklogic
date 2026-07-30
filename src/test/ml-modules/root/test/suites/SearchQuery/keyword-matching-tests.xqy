xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare function local:uris($response) as xs:string* {
  for $r in $response//search:result return string($r/@uri)
};

let $shared := search-test:search(map:entry("q", "queryfixture"))
let $shared-uris := local:uris($shared)

let $alpha := search-test:search(map:entry("q", "queryalpha"))
let $alpha-uris := local:uris($alpha)

let $none := search-test:search(map:entry("q", "no-such-token-xyz"))

return (
  test:assert-equal("2", string($shared//@total)),
  test:assert-true($shared-uris = "/query/alpha.xml"),
  test:assert-true($shared-uris = "/query/beta.xml"),
  test:assert-equal(2, fn:count($shared-uris)),

  test:assert-equal("1", string($alpha//@total)),
  test:assert-equal("/query/alpha.xml", $alpha-uris[1]),

  test:assert-equal("0", string($none//@total))
)
