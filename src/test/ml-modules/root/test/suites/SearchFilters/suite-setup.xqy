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

let $_ := test:load-test-file("filter-ch-2020.xml", xdmp:database(), "/filter/ch-2020.xml")
let $_ := xdmp:document-set-collections("/filter/ch-2020.xml", $collections)
let $_ := local:publish-judgment("/filter/ch-2020.xml")

let $_ := test:load-test-file("filter-fam-2020.xml", xdmp:database(), "/filter/fam-2020.xml")
let $_ := xdmp:document-set-collections("/filter/fam-2020.xml", $collections)
let $_ := local:publish-judgment("/filter/fam-2020.xml")

let $_ := test:load-test-file("filter-ch-2022.xml", xdmp:database(), "/filter/ch-2022.xml")
let $_ := xdmp:document-set-collections("/filter/ch-2022.xml", $collections)
let $_ := local:publish-judgment("/filter/ch-2022.xml")

return test:log("SearchFilters Suite Setup COMPLETE....")
