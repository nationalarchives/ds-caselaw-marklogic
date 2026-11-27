xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

declare function local:judgment($body-judge as xs:string) as element() {
  <akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
    <judgment name="decision">
      <meta/>
      <header><p><judge>{ $body-judge }</judge></p></header>
      <judgmentBody><decision><p>judgesearchtoken</p></decision></judgmentBody>
    </judgment>
  </akomaNtoso>
};

declare function local:load-published-judgment($uri as xs:string, $body-judge as xs:string, $searchable-judges as xs:string*) as empty-sequence() {
  xdmp:document-insert(
    $uri,
    local:judgment($body-judge),
    (
      xdmp:permission("caselaw-reader", "read"),
      xdmp:permission("caselaw-reader", "update"),
      xdmp:permission("dls-user", "read"),
      xdmp:permission("dls-user", "update")
    ),
    ("judgments", "judgment", "http://marklogic.com/collections/dls/latest-version")
  ),
  xdmp:document-add-properties($uri, <published>true</published>),
  if (fn:exists($searchable-judges)) then
    xdmp:document-add-properties(
      $uri,
      <searchable-metadata>{ for $judge in $searchable-judges return <judge>{ $judge }</judge> }</searchable-metadata>
    )
  else ()
};

(: No searchable-metadata property: the body judge is all there is. :)
let $_ := local:load-published-judgment("/judges/legacy.xml", "Legacybody", ())

(: The property replaces the body: an editor added one judge and suppressed the body judge. :)
let $_ := local:load-published-judgment("/judges/edited.xml", "Suppressedbody", ("Editoradded", "Keptjudge"))

(: Every judge was suppressed, leaving an empty property. :)
let $_ := local:load-published-judgment("/judges/emptied.xml", "Emptiedbody", ())
let $_ := xdmp:document-add-properties("/judges/emptied.xml", <searchable-metadata/>)

return test:log("SearchJudges Suite Setup COMPLETE....")
