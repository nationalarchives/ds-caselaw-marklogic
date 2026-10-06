xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

(: Retention rules belong to a database, and these tests run against the separate
   test content database, so look at the real content database. The rule is
   installed by deployment (the applyRetentionPolicy task); nothing in the tests
   creates it. If it is missing, DLS discards the content of superseded versions
   and clients cannot read back earlier versions of a document. :)

let $rules := xdmp:invoke-function(
  function() { dls:retention-rules("All Versions Retention Rule") },
  <options xmlns="xdmp:eval">
    <database>{xdmp:database("caselaw-content")}</database>
  </options>
)

return test:assert-equal(1, fn:count($rules))
