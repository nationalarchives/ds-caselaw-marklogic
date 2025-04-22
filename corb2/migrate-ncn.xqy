declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

import module namespace sem = "http://marklogic.com/semantics"
      at "/MarkLogic/semantics.xqy";

(: This is intended to be a migration script that runs once;
   it should not be run on a database which already has identifiers :)

declare variable $URI external;

let $doc_cite := fn:doc($URI)//uk:cite/text()
let $summary_cite := fn:doc($URI)//uk:summaryOfCite/text()
let $cite := if ($doc_cite) then ($doc_cite) else ($summary_cite)
let $namespace := if ($doc_cite) then "ukncn" else "uksummaryofncn"

let $truncated-uri := fn:replace(
                fn:replace($URI, "\.xml$", "")
                , "^/", "")
let $slug := fn:replace($truncated-uri, "press-summary/1$", "press-summary")


let $log := ("")
let $uuid := "id-"||sem:uuid-string()
let $log := ($log, "Processing", $URI, $cite, $uuid)

let $node := if ($cite) then (
<identifiers><identifier>
<namespace>{$namespace}</namespace>
<uuid>{$uuid}</uuid>
<value>{$cite}</value>
<url_slug>{$slug}</url_slug>
</identifier></identifiers>
) else (<identifiers/>)

let $log := ($log, if ($cite) then () else "cite empty at " || $URI)

let $log := ($log, xdmp:quote($node))

let $log := ($log, if
            (fn:starts-with($URI, "/failures/") or fn:starts-with($URI, "/collisions/"))
          then
            "ignored as failure/collision"
          else
            "set property" || xdmp:document-set-property($URI, $node) )

return string-join($log, "&#10;")
