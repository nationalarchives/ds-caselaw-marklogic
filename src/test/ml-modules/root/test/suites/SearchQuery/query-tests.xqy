xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace ukakn = "https://caselaw.nationalarchives.gov.uk/akn";

let $map :=
  map:new((
    map:entry("page", 1),
    map:entry("page-size", 100),
    map:entry("q", "capybara"),
    map:entry("party", ()),
    map:entry("judge", ()),
    map:entry("neutral_citation", ()),
    map:entry("specific_keyword", ()),
    map:entry("order", ()),
    map:entry("from", ()),
    map:entry("to", ()),
    map:entry("show_unpublished", fn:true()),
    map:entry("only_unpublished", fn:false()),
    map:entry("court", ())
    (: map:entry("court", xdmp:from-json-string('["ewhc/ch", "EWHC-Chancery"]')) :)
  ))

let $response := xdmp:invoke("/judgments/search/search-v2.xqy", $map)
let $y := xdmp:log("=============")
let $y := xdmp:log($response) (: logged in /var/opt/MarkLogic/Logs/8012_ErrorLog.txt in docker container :)


(: assert-true -false -equal -not-equal -exists -all-exist -at-least-one-equal -same-values
         -throws-error -http-get-status -meets-minimum/maximum-threshold :)

return (
  (: test:assert-equal("empty-snippet", string($response//@snippet-format)), :)
  test:assert-equal("1", string($response//@total)),
  test:assert-equal("2023-06-05", string($response//akn:FRBRdate[@name="decision"]/@date)),
  test:assert-equal("2023-06-05T13:07:36", string($response//akn:FRBRdate[@name="transform"]/@date)),
  test:assert-equal("Sample v Judgment", string($response//akn:FRBRname/@value)),
  test:assert-equal("376b2d62bc03ad74f3793f7b6175580eb44f9e2771e939732cf48e9000000000", string($response//ukakn:hash/text())),
  test:assert-equal("[2023] EWHC 9999 (Ch)", string($response//ukakn:cite/text())),
  test:assert-equal("EWHC-Chancery", string($response//ukakn:court/text())),
  test:assert-equal("capybara", string($response//search:highlight/text()))
)
