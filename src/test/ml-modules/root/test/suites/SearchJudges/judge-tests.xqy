xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace search = "http://marklogic.com/appservices/search";

declare function local:uris-for-judge($judge as xs:string) as xs:string* {
  search-test:search(map:entry("q", "judgesearchtoken") => map:with("judge", $judge))//search:result/@uri/fn:string(.)
};

let $legacy-body-judge := local:uris-for-judge("Legacybody")
let $editor-added-judge := local:uris-for-judge("Editoradded")
let $kept-judge := local:uris-for-judge("Keptjudge")
let $one-of-several-judges := local:uris-for-judge("Editoradded,Nobodyelse")
let $suppressed-body-judge := local:uris-for-judge("Suppressedbody")
let $emptied-body-judge := local:uris-for-judge("Emptiedbody")

return (
  (: With no searchable-metadata the body judge is searched, as before :)
  test:assert-equal("/judges/legacy.xml", $legacy-body-judge),

  (: Judges in searchable-metadata are found, including ones that are not in the body :)
  test:assert-equal("/judges/edited.xml", $editor-added-judge),
  test:assert-equal("/judges/edited.xml", $kept-judge),
  test:assert-equal("/judges/edited.xml", $one-of-several-judges),

  (: Once searchable-metadata exists, a body judge that is not in it no longer matches :)
  test:assert-equal((), $suppressed-body-judge),
  test:assert-equal((), $emptied-body-judge)
)
