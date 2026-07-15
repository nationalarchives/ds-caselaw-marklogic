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

(: Three orthogonal orderings across the fixtures:
   - decision date ASC: oldest, middle, newest (undated omitted)
   - last-modified ASC: newest, middle, oldest, undated (touch newest first)
   - transform date ASC: middle, newest, oldest, undated (set in fixture XML)
   So each order=* suite fails if the wrong sort field is used. :)
let $_ := xdmp:document-set-property("/order/newest.xml", <updated-touch>1</updated-touch>)
let $_ := xdmp:sleep(1100)
let $_ := xdmp:document-set-property("/order/middle.xml", <updated-touch>1</updated-touch>)
let $_ := xdmp:sleep(1100)
let $_ := xdmp:document-set-property("/order/oldest.xml", <updated-touch>1</updated-touch>)
let $_ := xdmp:sleep(1100)
let $_ := xdmp:document-set-property("/order/undated.xml", <updated-touch>1</updated-touch>)

let $_ := test:log("SearchOrder Suite Setup COMPLETE....")
return ()
