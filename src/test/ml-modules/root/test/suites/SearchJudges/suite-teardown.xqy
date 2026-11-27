xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';

for $doc in doc()
return xdmp:document-delete(xdmp:node-uri($doc))
