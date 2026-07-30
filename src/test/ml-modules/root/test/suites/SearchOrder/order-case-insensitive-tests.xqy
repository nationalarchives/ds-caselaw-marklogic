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

(: Four updated-order searches after SearchOrder's per-test touch/sleep setup
   can exceed the 20s REST default on a slow CI host. Raise only this request
   — do not bump the app-server default (that would apply in production). :)
let $_ := xdmp:set-request-time-limit(60)

let $updated := local:uris("updated")
let $Updated := local:uris("Updated")
let $desc := local:uris("-updated")
let $Desc := local:uris("-Updated")

return (
  test:assert-true(fn:deep-equal($updated, $Updated)),
  test:assert-true(fn:deep-equal($desc, $Desc))
)
