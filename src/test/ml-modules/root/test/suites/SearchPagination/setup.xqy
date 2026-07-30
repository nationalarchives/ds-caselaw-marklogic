xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

(: Distinct prop:last-modified before each test. Touch a→f so ascending
   updated order matches decision-date order for these fixtures. :)
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

let $_ := local:touch("/pagination/a.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/pagination/b.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/pagination/c.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/pagination/d.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/pagination/e.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/pagination/f.xml")
return test:log("SearchPagination per-test last-modified setup COMPLETE....")
