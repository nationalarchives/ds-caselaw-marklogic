declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $URI external;

let $validates := xdmp:validate(fn:doc($URI), "lax")
return <validation><uri>{$URI}</uri><report>{$validates}</report></validation>
