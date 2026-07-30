xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $uri as xs:string := "/test/add-properties-identifiers.xml";

declare variable $identifiers as element(identifiers) :=
  <identifiers>
    <identifier>
      <namespace>fclid</namespace>
      <uuid>id-test-fclid</uuid>
      <value>tn4t35ts</value>
      <url_slug>test/add-properties-identifiers</url_slug>
    </identifier>
  </identifiers>;

declare variable $search-with-body as element(search:response) :=
  <search:response xmlns:search="http://marklogic.com/appservices/search" total="1">
    <search:result uri="{$uri}" index="1">
      <search:snippet/>
      <search:extracted kind="element">
        <name>Example</name>
      </search:extracted>
    </search:result>
  </search:response>;

declare function local:eval-update($query as xs:string, $vars as map:map) {
  xdmp:eval(
    $query,
    $vars,
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <update>true</update>
    </options>
  )
};

declare function local:eval-query($query as xs:string, $vars as map:map) {
  xdmp:eval(
    $query,
    $vars,
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  )
};

let $_ := local:eval-update(
  'declare variable $uri as xs:string external;
   declare variable $identifiers as element(identifiers) external;
   xdmp:document-insert($uri, <doc><title>Helper Fixture</title></doc>),
   xdmp:document-set-properties($uri, $identifiers)',
  map:map() => map:with("uri", $uri) => map:with("identifiers", $identifiers)
)

(: Hydrate + amalgamate in a fresh transaction so the fixture is visible. :)
let $amalgamated := local:eval-query(
  'import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";
   declare variable $search as element() external;
   declare variable $uri as xs:string external;
   helper:amalgamate-identifiers($search, helper:hydrate-identifiers($uri))',
  map:map() => map:with("search", $search-with-body) => map:with("uri", $uri)
)

let $_ := local:eval-update(
  'declare variable $uri as xs:string external;
   if (fn:doc-available($uri)) then xdmp:document-delete($uri) else ()',
  map:map() => map:with("uri", $uri)
)

return (
  test:assert-true(fn:empty(helper:amalgamate-identifiers((), map:map()))),
  test:assert-equal("Adams v Brown", helper:normalise-vs("Adams -v- Brown")),
  test:assert-equal("Charles v Daniels", helper:normalise-vs("Charles - v - Daniels")),
  test:assert-equal("Edwards v Finlay", helper:normalise-vs("Edwards V Finlay")),
  test:assert-equal("Gonzalez v Hughes", helper:normalise-vs("Gonzalez vs Hughes")),
  test:assert-equal("Veronica Avalos v Vincent Havering &amp; VsVs Ltd.", helper:normalise-vs("Veronica Avalos v Vincent Havering &amp; VsVs Ltd.")),
  test:assert-equal(1, fn:count($amalgamated//search:extracted[@kind="identifiers"])),
  test:assert-equal("tn4t35ts", string($amalgamated//search:extracted[@kind="identifiers"]//value)),
  test:assert-equal(1, fn:count($amalgamated//identifiers)),
  test:assert-equal("Example", string($amalgamated//search:extracted[@kind="element"]/name))
)
