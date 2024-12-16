let $uris := cts:uris("",(),cts:collection-query(
   ("http://marklogic.com/collections/dls/latest-version")
))
return (count($uris), $uris)
