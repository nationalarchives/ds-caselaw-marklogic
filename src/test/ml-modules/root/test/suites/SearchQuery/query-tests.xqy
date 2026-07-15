xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-test = "https://caselaw.nationalarchives.gov.uk/test/search" at "/test/lib/search-test-helper.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace ukakn = "https://caselaw.nationalarchives.gov.uk/akn";

let $response := search-test:search(map:entry("q", "capybara"))

return (
  test:assert-equal("1", string($response//@total)),
  test:assert-equal("2023-06-05", string($response//akn:FRBRdate[@name="decision"]/@date)),
  test:assert-equal("2023-06-05T13:07:36", string($response//akn:FRBRdate[@name="transform"]/@date)),
  test:assert-equal("Sample v Judgment", string($response//akn:FRBRname/@value)),
  test:assert-equal("376b2d62bc03ad74f3793f7b6175580eb44f9e2771e939732cf48e9000000000", string($response//ukakn:hash/text())),
  test:assert-equal("[2023] EWHC 9999 (Ch)", string($response//ukakn:cite/text())),
  test:assert-equal("EWHC-Chancery", string($response//ukakn:court/text())),
  test:assert-equal("capybara", string($response//search:highlight/text()))
)
