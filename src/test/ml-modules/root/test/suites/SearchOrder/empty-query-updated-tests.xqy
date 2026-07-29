xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

(: Default test params pass q as (); that must not collapse the CTS query. :)
let $response := search-test:search(map:entry("order", "updated"))

return (
  test:assert-true(fn:exists($response)),
  test:assert-true(fn:exists($response//search:result))
)
