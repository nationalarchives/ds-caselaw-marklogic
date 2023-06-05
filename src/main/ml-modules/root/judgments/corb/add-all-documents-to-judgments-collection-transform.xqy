xquery version "1.0-ml";

declare variable $URI as xs:string external;
let $collections := ("judgments")

return xdmp:document-add-collections($URI, $collections)
