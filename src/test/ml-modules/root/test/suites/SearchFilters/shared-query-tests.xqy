xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";
import module namespace filters = "https://caselaw.nationalarchives.gov.uk/search/filters" at "/judgments/search/filters.xqy";

declare namespace search = "http://marklogic.com/appservices/search";

(: Reporting uses the same selection query on properties, without paging. :)
for $overrides in (
    map:map() => map:with("court", json:to-array(("EWHC-Chancery"))),
    map:map() => map:with("from", "2021-01-01") => map:with("to", "2023-01-01"),
    map:map() => map:with("court", json:to-array(("EWHC-Chancery"))) => map:with("to", "2020-12-31"),
    map:map() => map:with("only_unpublished", true())
)
let $params := search-test:params($overrides) => map:with("specific_keyword", "filterfixture")
let $query := filters:build-search-query($params)
let $document-uris := for $doc in cts:search(fn:collection(), $query, "unfiltered") return xdmp:node-uri($doc)
let $property-uris :=
    for $props in cts:search(xdmp:document-properties(), cts:document-fragment-query($query), "unfiltered")
    return xdmp:node-uri($props)
let $search-uris := search-test:search($params)//search:result/@uri/fn:string(.)
return (
    test:assert-equal(fn:count($document-uris), fn:count($property-uris)),
    test:assert-equal(fn:count($document-uris), fn:count($search-uris)),
    test:assert-true(every $uri in $document-uris satisfies ($uri = $property-uris and $uri = $search-uris))
)
