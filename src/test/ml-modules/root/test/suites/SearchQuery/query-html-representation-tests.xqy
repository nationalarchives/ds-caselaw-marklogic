xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace ukakn = "https://caselaw.nationalarchives.gov.uk/akn";

(: Test: only_with_html_representation excludes PDFs :)
let $map :=
  map:new((
    map:entry("page", 1),
    map:entry("page-size", 100),
    map:entry("q", ""),
    map:entry("party", ()),
    map:entry("judge", ()),
    map:entry("neutral_citation", ()),
    map:entry("specific_keyword", ()),
    map:entry("order", ()),
    map:entry("from", ()),
    map:entry("to", ()),
    map:entry("show_unpublished", fn:true()),
    map:entry("only_unpublished", fn:false()),
    map:entry("court", ()),
    map:entry("only_with_html_representation", fn:true())
  ))

let $only_with_html_response := xdmp:invoke("/judgments/search/search-v2.xqy", $map)

(: Test: only_with_html_representation false includes PDFs :)
let $map2 :=
  map:new((
    map:entry("page", 1),
    map:entry("page-size", 100),
    map:entry("q", ""),
    map:entry("party", ()),
    map:entry("judge", ()),
    map:entry("neutral_citation", ()),
    map:entry("specific_keyword", ()),
    map:entry("order", ()),
    map:entry("from", ()),
    map:entry("to", ()),
    map:entry("show_unpublished", fn:true()),
    map:entry("only_unpublished", fn:false()),
    map:entry("court", ()),
    map:entry("only_with_html_representation", fn:false())
  ))

let $with_and_without_html_response := xdmp:invoke("/judgments/search/search-v2.xqy", $map2)

return (
  test:assert-equal("1", string($only_with_html_response//@total)),
  test:assert-equal("2", string($with_and_without_html_response//@total))
)
