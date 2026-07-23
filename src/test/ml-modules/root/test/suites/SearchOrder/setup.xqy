xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

(: Re-assert distinct prop:last-modified before each test. Touches run in
   separate auto-committed transactions with ≥1s gaps so values differ at
   MarkLogic's second-resolution last-modified clock. :)
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

let $_ := local:touch("/order/newest.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/order/middle.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/order/oldest.xml")
let $_ := xdmp:sleep(1100)
let $_ := local:touch("/order/undated.xml")
return test:log("SearchOrder per-test last-modified setup COMPLETE....")
