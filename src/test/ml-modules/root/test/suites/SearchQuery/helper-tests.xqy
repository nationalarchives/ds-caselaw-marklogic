xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";



test:assert-equal("Adams v Brown", helper:normalise-vs("Adams -v- Brown")),
test:assert-equal("Charles v Daniels", helper:normalise-vs("Charles - v - Daniels")),
test:assert-equal("Edwards v Finlay", helper:normalise-vs("Edwards V Finlay")),
test:assert-equal("Gonzalez v Hughes", helper:normalise-vs("Gonzalez vs Hughes")),
test:assert-equal("Veronica Avalos v Vincent Havering &amp; VsVs Ltd.", helper:normalise-vs("Veronica Avalos v Vincent Havering &amp; VsVs Ltd."))
