xquery version "1.0-ml";

(: Shared helpers for invoking /judgments/search/search-v2.xqy from unit tests.
   Keep default params in sync with every external declared there that has no default.

   Note: use map:new/map:entry rather than map:with for empty-sequence values —
   map:with removes a key when its value is (). :)
module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search";

declare function search-test:default-params() as map:map {
  map:new((
    map:entry("page", 1),
    map:entry("page-size", 100),
    map:entry("q", ()),
    map:entry("party", ()),
    map:entry("judge", ()),
    map:entry("neutral_citation", ()),
    map:entry("document_name", ()),
    map:entry("consignment_number", ()),
    map:entry("specific_keyword", ()),
    map:entry("order", ()),
    map:entry("from", ()),
    map:entry("to", ()),
    map:entry("show_unpublished", fn:true()),
    map:entry("only_unpublished", fn:false()),
    map:entry("only_with_html_representation", ()),
    map:entry("court", ())
  ))
};

declare function search-test:params($overrides as map:map) as map:map {
  (: Later maps win on duplicate keys. :)
  map:new((search-test:default-params(), $overrides))
};

declare function search-test:search() {
  search-test:search(map:map())
};

declare function search-test:search($overrides as map:map) {
  xdmp:invoke("/judgments/search/search-v2.xqy", search-test:params($overrides))
};

(: Test surrogate for caselaw-public-ui — same reader roles, plus caselaw-module-invoke
   so tests can impersonate via xdmp:invoke-function without widening production privileges.
   See src/test/ml-config/security/users/caselaw-public-ui-test.json :)
declare variable $PUBLIC_UI_TEST_USER as xs:string := "caselaw-public-ui-test";

declare function search-test:public-ui-test-user() as xs:string {
  $PUBLIC_UI_TEST_USER
};

(: Params matching the atom feed / search_judgments_and_parse_response path. :)
declare function search-test:public-ui-params($overrides as map:map) as map:map {
  map:new((
    map:entry("show_unpublished", fn:false()),
    map:entry("only_unpublished", fn:false()),
    map:entry("collections", "judgment"),
    map:entry("only_with_html_representation", fn:false()),
    $overrides
  ))
};

declare function search-test:search-as-user($user-name as xs:string, $overrides as map:map) {
  let $run := function() {
    xdmp:invoke("/judgments/search/search-v2.xqy", search-test:params($overrides))
  }
  return xdmp:invoke-function(
    $run,
    <options xmlns="xdmp:eval">
      <user-id>{xdmp:user($user-name)}</user-id>
    </options>
  )
};

declare function search-test:search-as-public-ui($overrides as map:map) {
  search-test:search-as-user(
    $PUBLIC_UI_TEST_USER,
    search-test:public-ui-params($overrides)
  )
};
