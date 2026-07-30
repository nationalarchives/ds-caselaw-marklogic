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

let $_ := test:load-test-file("result-one.xml", xdmp:database(), "/result-data/one.xml")
let $_ := xdmp:document-set-collections("/result-data/one.xml", $collections)
let $_ := local:publish-judgment("/result-data/one.xml", "rdoneaaa", "result-data/one")

let $_ := test:load-test-file("result-two.xml", xdmp:database(), "/result-data/two.xml")
let $_ := xdmp:document-set-collections("/result-data/two.xml", $collections)
let $_ := local:publish-judgment("/result-data/two.xml", "rdtwobbb", "result-data/two")

return test:log("SearchResultData Suite Setup COMPLETE....")
