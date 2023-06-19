xquery version '1.0-ml';

import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare variable $URI as xs:string external;

dls:document-add-collections($URI, "judgment")
