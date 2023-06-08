xquery version "1.0-ml";

let $uris := cts:uri-match("*.xml", (), cts:not-query(cts:collection-query("judgment")))

return (fn:count($uris), $uris)

