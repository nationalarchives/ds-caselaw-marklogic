xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare function local:uris($response) {
  for $r in $response//search:result return string($r/@uri)
};

let $q := map:entry("q", "publishfixture")

let $all := search-test:search($q)
let $published-only := search-test:search(map:new(($q, map:entry("show_unpublished", fn:false()))))
let $unpublished-only := search-test:search(map:new(($q, map:entry("only_unpublished", fn:true()))))
let $public-ui := search-test:search-as-public-ui($q)

return (
  test:assert-equal("2", string($all//@total)),
  test:assert-true("/published/published.xml" = local:uris($all)),
  test:assert-true("/published/unpublished.xml" = local:uris($all)),
  test:assert-equal("1", string($published-only//@total)),
  test:assert-equal("/published/published.xml", local:uris($published-only)[1]),
  test:assert-equal("1", string($unpublished-only//@total)),
  test:assert-equal("/published/unpublished.xml", local:uris($unpublished-only)[1]),
  test:assert-equal("1", string($public-ui//@total)),
  test:assert-equal("/published/published.xml", local:uris($public-ui)[1])
)
