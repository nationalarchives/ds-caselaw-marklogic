xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

(:
   Runs once when your suite is started.
   You can use this to insert some data that will not be modified over the course of the suite's tests.
   If no suite-specific setup is required, this file may be deleted.
:)

let $x := test:load-test-file("sample_judgment.xml", xdmp:database(), "/ewhc/ch/1234/5678.xml")
let $x := test:load-test-file("pdf-test-content.xml", xdmp:database(), "/pdf/1234/5678.xml")
let $x := xdmp:document-set-collections("/ewhc/ch/1234/5678.xml", ("judgments", "http://marklogic.com/collections/dls/latest-version"))
let $x := xdmp:document-set-collections("/pdf/1234/5678.xml", ("judgments", "http://marklogic.com/collections/dls/latest-version"))
let $x := test:log("SampleTestSuite Suite Setup COMPLETE....")
return ()
