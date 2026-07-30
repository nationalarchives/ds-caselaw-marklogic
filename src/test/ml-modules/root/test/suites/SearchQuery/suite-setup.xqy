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

(: Existing fixtures for extract/highlight and HTML-representation tests. :)
let $_ := test:load-test-file("sample_judgment.xml", xdmp:database(), "/ewhc/ch/1234/5678.xml")
let $_ := xdmp:document-set-collections("/ewhc/ch/1234/5678.xml", $collections)
let $_ := local:publish-judgment("/ewhc/ch/1234/5678.xml")

let $_ := test:load-test-file("pdf-test-content.xml", xdmp:database(), "/pdf/1234/5678.xml")
let $_ := xdmp:document-set-collections("/pdf/1234/5678.xml", $collections)
let $_ := local:publish-judgment("/pdf/1234/5678.xml")

(: Keyword include/exclude fixtures. :)
let $_ := test:load-test-file("query-alpha.xml", xdmp:database(), "/query/alpha.xml")
let $_ := xdmp:document-set-collections("/query/alpha.xml", $collections)
let $_ := local:publish-judgment("/query/alpha.xml")

let $_ := test:load-test-file("query-beta.xml", xdmp:database(), "/query/beta.xml")
let $_ := xdmp:document-set-collections("/query/beta.xml", $collections)
let $_ := local:publish-judgment("/query/beta.xml")

return test:log("SearchQuery Suite Setup COMPLETE....")
