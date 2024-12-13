declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

import module namespace sem = "http://marklogic.com/semantics"
      at "/MarkLogic/semantics.xqy";

(: This is intended to be a migration script that runs once;
   it should not be run on a database which already has identifiers :)

declare variable $URI external;

let $cite := fn:doc($URI)//uk:cite/text()
let $slug := fn:replace(
                fn:replace($URI, "\.xml$", "")
                , "^/", "")
let $log := ("")
let $uuid := "id-"||sem:uuid-string()
let $log := ($log, "Processing", $URI, $cite, $uuid)
let $node :=
<identifiers><identifier>
<namespace>ukncn</namespace>
<uuid>{$uuid}</uuid>
<value>{$cite}</value>
<url_slug>{$slug}</url_slug>
</identifier></identifiers>
let $log := ($log, xdmp:quote($node))

let $log := ($log, if
            (fn:starts-with($URI, "/failures/") or fn:starts-with($URI, "/collisions/"))
          then
            "ignored as failure/collision"
          else
            "set property" || xdmp:document-set-property($URI, $node))

return string-join($log, "&#10;")
