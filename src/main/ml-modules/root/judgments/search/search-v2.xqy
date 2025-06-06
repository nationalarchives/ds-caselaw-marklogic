xquery version "1.0-ml";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

declare function uk:get-request-date($name as xs:string) as xs:date? {
    let $raw := $name
    return if ($raw castable as xs:date) then xs:date($raw) else ()
};

declare variable $q as xs:string? external;
declare variable $party as xs:string? external;
declare variable $court as json:array? external;
declare variable $judge as xs:string? external;
declare variable $neutral_citation as xs:string? external;
declare variable $specific_keyword as xs:string? external;
declare variable $order as xs:string? external;
declare variable $page as xs:integer external;
declare variable $page-size as xs:integer external;
declare variable $from as xs:string? external;
declare variable $to as xs:string? external;
declare variable $from_date as xs:date? := uk:get-request-date($from);
declare variable $to_date as xs:date? := uk:get-request-date($to);
declare variable $show_unpublished as xs:boolean? external;
declare variable $only_unpublished as xs:boolean? external;
declare variable $only_with_html_representation as xs:boolean? external;
declare variable $editor_status as xs:string? external := "";
declare variable $editor_assigned as xs:string? external := "";
declare variable $editor_priority as xs:string? external := "";
declare variable $collections as xs:string? external := "";
declare variable $quoted_phrases as json:array? external := xdmp:from-json-string("[]");

let $collection-uris := fn:tokenize($collections, ",")
let $collection-query := if (empty($collection-uris)) then () else cts:collection-query($collection-uris)


let $start as xs:integer := ($page - 1) * $page-size + 1

let $params := map:map()
    => map:with('q', $q)
    => map:with('party', $party)
    => map:with('court', $court)
    => map:with('judge', $judge)
    => map:with('neutral_citation', $neutral_citation)
    => map:with('specific_keyword', $specific_keyword)
    => map:with('page', $page)
    => map:with('page-size', $page-size)
    => map:with('order', $order)
    => map:with('from', $from)
    => map:with('to', $to)
    => map:with('show_unpublished', $show_unpublished)
    => map:with('only_unpublished', $only_unpublished)
    => map:with('only_with_html_representation', $only_with_html_representation)
    => map:with('editor_status', $editor_status)
    => map:with('editor_assigned', $editor_assigned)
    => map:with('editor_priority', $editor_priority)
    => map:with('quoted_phrases', $quoted_phrases)

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
let $neutral-citation-query := if ($neutral_citation) then
    cts:element-value-query(fn:QName('https://caselaw.nationalarchives.gov.uk/akn', 'cite'), $neutral_citation, ('case-insensitive'))
else ()
let $specific-keyword-query := if ($specific_keyword) then
    cts:word-query($specific_keyword, ('case-insensitive', 'unstemmed'))
else ()
let $consignment-number-query := if (helper:is-a-consignment-number($q)) then (helper:make-consignment-number-query($q)) else ()
let $editor-assigned-query := if (($show_unpublished or $only_unpublished) and $editor_assigned) then cts:properties-fragment-query(cts:element-value-query(fn:QName("", "assigned-to"), $editor_assigned)) else ()
let $editor-priority-query := if (($show_unpublished or $only_unpublished) and $editor_priority) then cts:properties-fragment-query(cts:element-value-query(fn:QName("", "editor-priority"), $editor_priority)) else ()

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

(: Build the main query :)
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
    dls:documents-query()
)
let $query := cts:and-query($queries)
let $boosted-query := helper:boost-title-and-ncn($q, $query)

(: Build search options :)

let $show-snippets as xs:boolean := exists(( $q-query, $party-query, $judge-query ))

let $sort-direction := if (fn:starts-with($order, '-')) then 'descending' else 'ascending'
let $sort-word := replace($order, '-', '')

let $sort-order := if ($sort-word = 'date') then
    <sort-order xmlns="http://marklogic.com/appservices/search" direction="{$sort-direction}">
            <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRdate/@date</path-index>
        </sort-order>
else if ($sort-word = 'updated') then
    <sort-order xmlns="http://marklogic.com/appservices/search" direction="{$sort-direction}" type="xs:dateTime">
        <element ns="http://marklogic.com/xdmp/property" name="last-modified" />
    </sort-order>
else if ($sort-word = 'transformation') then
    <sort-order xmlns="http://marklogic.com/appservices/search" direction="{$sort-direction}">
        <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">akn:akomaNtoso/akn:judgment/akn:meta/akn:identification/akn:FRBRManifestation/akn:FRBRdate[@name='transform']/@date</path-index>
    </sort-order>
else
    ()

let $transform-results := if ($show-snippets) then
    helper:snippet-transform-results($quoted_phrases)
else
    <transform-results xmlns="http://marklogic.com/appservices/search" apply="empty-snippet" />

let $scope := 'documents'

let $search-options := <options xmlns="http://marklogic.com/appservices/search">
    <fragment-scope>{ $scope }</fragment-scope>
    <search-option>unfiltered</search-option>
    <constraint name="court">
        <range type="xs:string" facet="true">
            <facet-option>limit=10</facet-option>
            <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0" xmlns:uk="https://caselaw.nationalarchives.gov.uk/akn">//akn:proprietary/uk:court</path-index>
        </range>
    </constraint>
    <constraint name="year">
        <range type="xs:gYear" facet="true">
            <facet-option>limit=10</facet-option>
            <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0" xmlns:uk="https://caselaw.nationalarchives.gov.uk/akn">//akn:proprietary/uk:year</path-index>
        </range>
    </constraint>
    { $sort-order }
    <extract-document-data xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0" xmlns:uk="https://caselaw.nationalarchives.gov.uk/akn">
        <extract-path>//akn:FRBRWork/akn:FRBRdate</extract-path>
        <extract-path>//akn:FRBRWork/akn:FRBRname</extract-path>
        <extract-path>//uk:cite</extract-path>
        <extract-path>//akn:neutralCitation</extract-path>
        <extract-path>//uk:court</extract-path>
        <extract-path>//uk:jurisdiction</extract-path>
        <extract-path>//uk:hash</extract-path>
        <extract-path>//akn:FRBRManifestation/akn:FRBRdate</extract-path>
    </extract-document-data>
    { $transform-results }
</options>

(: Execute the search :)
let $results := search:resolve(element x { $boosted-query }/*, $search-options, $start, $page-size)

return helper:add-properties-to-search($results)
