xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace search = "http://marklogic.com/appservices/search";

declare function local:uris($order as xs:string) as xs:string* {
  for $r in search-test:search(
    map:entry("q", "orderfixture") => map:with("order", $order)
  )//search:result
  return string($r/@uri)
};

let $updated := local:uris("updated")
let $Updated := local:uris("Updated")
let $desc := local:uris("-updated")
let $Desc := local:uris("-Updated")

return (
  test:assert-true(fn:deep-equal($updated, $Updated)),
  test:assert-true(fn:deep-equal($desc, $Desc))
)
