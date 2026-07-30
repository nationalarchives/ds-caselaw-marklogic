xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

(: Test: only_with_html_representation excludes PDFs :)
let $only_with_html_response := search-test:search(
  map:entry("q", "")
    => map:with("only_with_html_representation", fn:true())
)

(: Test: only_with_html_representation false includes PDFs :)
let $with_and_without_html_response := search-test:search(
  map:entry("q", "")
    => map:with("only_with_html_representation", fn:false())
)

(: Suite fixtures: sample judgment, PDF, query-alpha, query-beta. :)
return (
  test:assert-equal("3", string($only_with_html_response//@total)),
  test:assert-equal("4", string($with_and_without_html_response//@total))
)
