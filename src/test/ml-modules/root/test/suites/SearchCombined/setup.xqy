xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

(: Distinct prop:last-modified before each test. Chancery 2022 touched first
   (oldest last-modified), then 2020 (newer). Family is touched last but is
   excluded by the court filter in the combined tests. :)
declare function local:touch($uri as xs:string) {
  xdmp:eval(
    'declare variable $uri as xs:string external;
     xdmp:document-set-property($uri, <updated-touch>{xdmp:request-timestamp()}</updated-touch>)',
    map:map() => map:with("uri", $uri),
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <update>true</update>
    </options>
  )
};

let $_ := local:touch("/combined/ch-2022.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/combined/ch-2020.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/combined/fam-2020.xml")
return test:log("SearchCombined per-test last-modified setup COMPLETE....")
