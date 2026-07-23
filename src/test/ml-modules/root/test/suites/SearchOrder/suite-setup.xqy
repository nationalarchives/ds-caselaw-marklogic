xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare function local:publish-judgment($uri as xs:string) as empty-sequence() {
  if (fn:not(dls:document-is-managed($uri))) then
    dls:document-manage($uri, fn:true())
  else (),
  dls:document-set-permissions(
    $uri,
    (
      xdmp:permission("caselaw-reader", "read"),
      xdmp:permission("caselaw-reader", "update"),
      xdmp:permission("dls-user", "read"),
      xdmp:permission("dls-user", "update")
    )
  ),
  xdmp:document-add-properties($uri, <published>true</published>),
  xdmp:document-add-collections($uri, "judgment")
};

let $collections := ("judgments", "judgment", "http://marklogic.com/collections/dls/latest-version")

let $_ := test:load-test-file("order-oldest.xml", xdmp:database(), "/order/oldest.xml")
let $_ := xdmp:document-set-collections("/order/oldest.xml", $collections)
let $_ := local:publish-judgment("/order/oldest.xml")

let $_ := test:load-test-file("order-middle.xml", xdmp:database(), "/order/middle.xml")
let $_ := xdmp:document-set-collections("/order/middle.xml", $collections)
let $_ := local:publish-judgment("/order/middle.xml")

let $_ := test:load-test-file("order-newest.xml", xdmp:database(), "/order/newest.xml")
let $_ := xdmp:document-set-collections("/order/newest.xml", $collections)
let $_ := local:publish-judgment("/order/newest.xml")

let $_ := test:load-test-file("order-undated.xml", xdmp:database(), "/order/undated.xml")
let $_ := xdmp:document-set-collections("/order/undated.xml", $collections)
let $_ := local:publish-judgment("/order/undated.xml")

(: last-modified ordering is established in setup.xqy (separate commits + sleeps). :)
let $_ := test:log("SearchOrder Suite Setup COMPLETE....")
return ()
