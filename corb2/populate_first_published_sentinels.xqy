declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $URI external;

let $set := xdmp:document-set-property($URI,
<first_published_datetime>1970-01-01T00:00:00Z</first_published_datetime>
)
return $URI
