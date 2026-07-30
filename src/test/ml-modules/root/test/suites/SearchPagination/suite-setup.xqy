xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare function local:publish-judgment($uri as xs:string, $fclid as xs:string, $slug as xs:string) as empty-sequence() {
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
  xdmp:document-add-properties(
    $uri,
    (
      <published>true</published>,
      <identifiers>
        <identifier>
          <namespace>fclid</namespace>
          <uuid>id-{$fclid}</uuid>
          <value>{$fclid}</value>
          <url_slug>{$slug}</url_slug>
        </identifier>
      </identifiers>
    )
  ),
  xdmp:document-add-collections($uri, "judgment")
};

let $collections := ("judgments", "judgment", "http://marklogic.com/collections/dls/latest-version")

let $_ := test:load-test-file("page-a.xml", xdmp:database(), "/pagination/a.xml")
let $_ := xdmp:document-set-collections("/pagination/a.xml", $collections)
let $_ := local:publish-judgment("/pagination/a.xml", "pagea00a", "pagination/a")

let $_ := test:load-test-file("page-b.xml", xdmp:database(), "/pagination/b.xml")
let $_ := xdmp:document-set-collections("/pagination/b.xml", $collections)
let $_ := local:publish-judgment("/pagination/b.xml", "pageb00b", "pagination/b")

let $_ := test:load-test-file("page-c.xml", xdmp:database(), "/pagination/c.xml")
let $_ := xdmp:document-set-collections("/pagination/c.xml", $collections)
let $_ := local:publish-judgment("/pagination/c.xml", "pagec00c", "pagination/c")

let $_ := test:load-test-file("page-d.xml", xdmp:database(), "/pagination/d.xml")
let $_ := xdmp:document-set-collections("/pagination/d.xml", $collections)
let $_ := local:publish-judgment("/pagination/d.xml", "paged00d", "pagination/d")

let $_ := test:load-test-file("page-e.xml", xdmp:database(), "/pagination/e.xml")
let $_ := xdmp:document-set-collections("/pagination/e.xml", $collections)
let $_ := local:publish-judgment("/pagination/e.xml", "pagee00e", "pagination/e")

let $_ := test:load-test-file("page-f.xml", xdmp:database(), "/pagination/f.xml")
let $_ := xdmp:document-set-collections("/pagination/f.xml", $collections)
let $_ := local:publish-judgment("/pagination/f.xml", "pagef00f", "pagination/f")

return test:log("SearchPagination Suite Setup COMPLETE....")
