xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare function local:reader-permissions() {
  (
    xdmp:permission("caselaw-reader", "read"),
    xdmp:permission("caselaw-reader", "update"),
    xdmp:permission("dls-user", "read"),
    xdmp:permission("dls-user", "update")
  )
};

declare function local:manage-judgment($uri as xs:string) as empty-sequence() {
  if (fn:not(dls:document-is-managed($uri))) then
    dls:document-manage($uri, fn:true())
  else (),
  dls:document-set-permissions($uri, local:reader-permissions())
};

declare function local:publish-judgment($uri as xs:string) as empty-sequence() {
  local:manage-judgment($uri),
  xdmp:document-add-properties($uri, <published>true</published>),
  xdmp:document-add-collections($uri, "judgment")
};

declare function local:load-unpublished-judgment($uri as xs:string) as empty-sequence() {
  local:manage-judgment($uri),
  xdmp:document-add-collections($uri, "judgment")
};

let $collections := ("judgments", "judgment", "http://marklogic.com/collections/dls/latest-version")

let $_ := test:load-test-file("published.xml", xdmp:database(), "/published/published.xml")
let $_ := xdmp:document-set-collections("/published/published.xml", $collections)
let $_ := local:publish-judgment("/published/published.xml")

let $_ := test:load-test-file("unpublished.xml", xdmp:database(), "/published/unpublished.xml")
let $_ := xdmp:document-set-collections("/published/unpublished.xml", $collections)
let $_ := local:load-unpublished-judgment("/published/unpublished.xml")

return test:log("SearchPublished Suite Setup COMPLETE....")
