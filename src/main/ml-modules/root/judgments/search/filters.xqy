xquery version "1.0-ml";

module namespace filters = "https://caselaw.nationalarchives.gov.uk/search/filters";

import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";
declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

(: Shared document selection for search and reporting, without sorting or paging. :)
declare function filters:build-search-query($params as map:map) as cts:query {
let $q := fn:string(map:get($params, "q"))
let $party := fn:string(map:get($params, "party"))
let $judge := fn:string(map:get($params, "judge"))
let $neutral_citation := fn:string(map:get($params, "neutral_citation"))
let $document_name := fn:string(map:get($params, "document_name"))
let $consignment_number := fn:string(map:get($params, "consignment_number"))
let $specific_keyword := fn:string(map:get($params, "specific_keyword"))
let $editor_status := fn:string(map:get($params, "editor_status"))
let $editor_assigned := fn:string(map:get($params, "editor_assigned"))
let $editor_priority := fn:string(map:get($params, "editor_priority"))
let $collections := fn:string(map:get($params, "collections"))
let $show_unpublished := xs:boolean((map:get($params, "show_unpublished"), false())[1])
let $only_unpublished := xs:boolean((map:get($params, "only_unpublished"), false())[1])
let $only_with_html_representation := xs:boolean((map:get($params, "only_with_html_representation"), false())[1])
let $court := map:get($params, "court")
let $from := fn:string(map:get($params, "from"))
let $to := fn:string(map:get($params, "to"))
let $from_date := if ($from castable as xs:date) then xs:date($from) else ()
let $to_date := if ($to castable as xs:date) then xs:date($to) else ()
let $collection-uris := fn:tokenize($collections, ",")
let $collection-query := if (empty($collection-uris)) then () else cts:collection-query($collection-uris)

(: Build the individual queries :)
let $q-query := if ($q and not(helper:is-a-consignment-number($q))) then (helper:make-q-query($q)) else ()
let $party-query := if ($party) then
    cts:or-query((
        cts:element-word-query(fn:QName('http://docs.oasis-open.org/legaldocml/ns/akn/3.0', 'party'), $party),
        cts:element-attribute-word-query(fn:QName('http://docs.oasis-open.org/legaldocml/ns/akn/3.0', 'FRBRname'), fn:QName('', 'value'), $party),
        cts:element-word-query(fn:QName('https://caselaw.nationalarchives.gov.uk/akn', 'party'), $party)
    ))
else ()

let $court-query := if ($court) then cts:or-query(
    for $c in json:array-values($court) return (
    cts:element-value-query(fn:QName('https://judgments.gov.uk/', 'court'), $c, ('case-insensitive')),
    cts:element-value-query(fn:QName('https://caselaw.nationalarchives.gov.uk/akn', 'court'), $c, ('case-insensitive')),
    cts:element-attribute-word-query(
    fn:QName('http://docs.oasis-open.org/legaldocml/ns/akn/3.0', 'FRBRuri'), xs:QName('value'), $c, ('case-insensitive')
    )
)) else ()


let $judge_elements := fn:tokenize($judge, ",")

let $judge_query := cts:or-query(fn:map(function($j) {
  cts:element-word-query(fn:QName('http://docs.oasis-open.org/legaldocml/ns/akn/3.0', 'judge'), $j, ('case-insensitive', 'punctuation-insensitive'))
}, $judge_elements))

let $judge-query := if ($judge) then $judge_query else ()

let $from-date-query := if (empty($from_date)) then () else cts:path-range-query('akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRdate/@date', '>=', $from_date)
let $to-date-query := if (empty($to_date)) then () else cts:path-range-query('akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRdate/@date', '<=', $to_date)
let $published-query := if ($show_unpublished or $only_unpublished) then () else cts:properties-fragment-query(cts:element-value-query(fn:QName("", "published"), "true"))
let $unpublished-query := if ($only_unpublished) then cts:properties-fragment-query(cts:not-query(cts:element-value-query(fn:QName("", "published"), "true"))) else ()
let $html-representation-query := if ($only_with_html_representation) then cts:not-query(cts:element-value-query(xs:QName('uk:sourceFormat'), 'application/pdf', ('exact'))) else ()
let $neutral-citation-query :=
  if ($neutral_citation) then
    cts:or-query((
      cts:element-word-query(
        fn:QName('https://caselaw.nationalarchives.gov.uk/akn', 'cite'),
        $neutral_citation,
        ('case-insensitive', 'punctuation-insensitive', 'unstemmed')
      ),
      cts:element-word-query(
        fn:QName('http://docs.oasis-open.org/legaldocml/ns/akn/3.0', 'neutralCitation'),
        $neutral_citation,
        ('case-insensitive', 'punctuation-insensitive', 'unstemmed')
      )
    ))
  else ()
let $specific-keyword-query := if ($specific_keyword) then
    cts:word-query($specific_keyword, ('case-insensitive', 'unstemmed'))
else ()
let $consignment-number-query := if (helper:is-a-consignment-number($q)) then (helper:make-consignment-number-query($q)) else ()
let $editor-assigned-query := if (($show_unpublished or $only_unpublished) and $editor_assigned) then cts:properties-fragment-query(cts:element-value-query(fn:QName("", "assigned-to"), $editor_assigned)) else ()
let $editor-priority-query := if (($show_unpublished or $only_unpublished) and $editor_priority) then cts:properties-fragment-query(cts:element-value-query(fn:QName("", "editor-priority"), $editor_priority)) else ()
let $name-query := if ($document_name) then
    cts:element-word-query(fn:QName('https://caselaw.nationalarchives.gov.uk/akn', 'name'), $document_name, ('case-insensitive', 'punctuation-insensitive'))
else ()

let $fuzzy-consignment-number-query :=
  if ($consignment_number) then
    cts:element-word-query(
      fn:QName('https://caselaw.nationalarchives.gov.uk/akn',
               'transfer-consignment-number'),
      $consignment_number,
      ('case-insensitive', 'punctuation-insensitive', 'unstemmed')
    )
  else ()

let $status_new_query := cts:properties-fragment-query(cts:not-query(
    cts:element-value-query(fn:QName("", "assigned-to"), "*", "wildcarded")
    ))

(: currently there is no way to get an empty assigned-to, but that's a bug :)
(: let $empty_assignment_query := cts:properties-fragment-query(
    cts:element-value-query(fn:QName("", "assigned-to"), "")
    ) :)

let $status_held_query := cts:properties-fragment-query(
    cts:and-query((
        cts:element-value-query(fn:QName("", "editor-hold"), "true"),
        cts:element-value-query(fn:QName("", "assigned-to"), "*", "wildcarded")
    ))
)
let $status_progress_query := cts:properties-fragment-query(
    cts:and-query((
        (: does this include no editor-hold? :)
        cts:not-query(cts:element-value-query(fn:QName("", "editor-hold"), "true")),
        cts:element-value-query(fn:QName("", "assigned-to"), "*", "wildcarded")
    ))
)


let $editor-status-query := if (($show_unpublished or $only_unpublished) and $editor_status) then (
    if ($editor_status = 'new') then ($status_new_query) else (
        if ($editor_status = 'held') then ($status_held_query) else (
            if ($editor_status = 'inprogress') then ($status_progress_query) else ()
        )
    )
) else ()

let $queries := (
    $collection-query,
    $q-query,
    $party-query,
    $court-query,
    $judge-query,
    $from-date-query,
    $to-date-query,
    $published-query,
    $unpublished-query,
    $html-representation-query,
    $neutral-citation-query,
    $specific-keyword-query,
    $consignment-number-query,
    $editor-assigned-query,
    $editor-priority-query,
    $editor-status-query,
    $name-query,
    $fuzzy-consignment-number-query,
    dls:documents-query()
)
return cts:and-query($queries)
};
