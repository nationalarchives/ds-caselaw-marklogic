xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

let $collections := ("judgments", "http://marklogic.com/collections/dls/latest-version")

let $_ := test:load-test-file("order-oldest.xml", xdmp:database(), "/order/oldest.xml")
let $_ := xdmp:document-set-collections("/order/oldest.xml", $collections)

let $_ := test:load-test-file("order-middle.xml", xdmp:database(), "/order/middle.xml")
let $_ := xdmp:document-set-collections("/order/middle.xml", $collections)

let $_ := test:load-test-file("order-newest.xml", xdmp:database(), "/order/newest.xml")
let $_ := xdmp:document-set-collections("/order/newest.xml", $collections)

let $_ := test:load-test-file("order-undated.xml", xdmp:database(), "/order/undated.xml")
let $_ := xdmp:document-set-collections("/order/undated.xml", $collections)

(: last-modified ordering is established in setup.xqy (separate commits + sleeps). :)
let $_ := test:log("SearchOrder Suite Setup COMPLETE....")
return ()
