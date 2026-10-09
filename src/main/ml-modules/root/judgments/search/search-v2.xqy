xquery version "1.0-ml";

import module namespace helper = "https://caselaw.nationalarchives.gov.uk/helper" at "/judgments/search/helper.xqy";
import module namespace filters = "https://caselaw.nationalarchives.gov.uk/search/filters" at "/judgments/search/filters.xqy";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace uk = "https://caselaw.nationalarchives.gov.uk/akn";

declare variable $q as xs:string? external;
declare variable $party as xs:string? external;
declare variable $court as json:array? external;
declare variable $judge as xs:string? external;
declare variable $neutral_citation as xs:string? external;
declare variable $document_name as xs:string? external;
declare variable $consignment_number as xs:string? external;
declare variable $specific_keyword as xs:string? external;
declare variable $order as xs:string? external;
declare variable $page as xs:integer external;
declare variable $page-size as xs:integer external;
declare variable $from as xs:string? external;
declare variable $to as xs:string? external;
declare variable $show_unpublished as xs:boolean? external;
declare variable $only_unpublished as xs:boolean? external;
declare variable $only_with_html_representation as xs:boolean? external;
declare variable $editor_status as xs:string? external := "";
declare variable $editor_assigned as xs:string? external := "";
declare variable $editor_priority as xs:string? external := "";
declare variable $collections as xs:string? external := "";
declare variable $quoted_phrases as json:array? external := xdmp:from-json-string("[]");

let $start as xs:integer := ($page - 1) * $page-size + 1

let $params := map:map()
    => map:with('q', $q)
    => map:with('party', $party)
    => map:with('court', $court)
    => map:with('judge', $judge)
    => map:with('neutral_citation', $neutral_citation)
    => map:with('document_name', $document_name)
    => map:with('consignment_number', $consignment_number)
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
    => map:with('collections', $collections)

(: Resolve sort before building the main query — date order omits undated docs. :)
let $sort-direction := if (fn:starts-with($order, '-')) then 'descending' else 'ascending'
let $sort-word := lower-case(replace($order, '-', ''))

(: When ordering by decision date, only include judgments that have a Work date
   in the range index. Docs without that path otherwise surface at one end of
   the sorted result set. :)
let $has-decision-date-query := if ($sort-word = 'date') then
    cts:path-range-query(
        'akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRdate/@date',
        '>=',
        xs:date('0001-01-01')
    )
else ()

(: Build the main query :)
let $query := cts:and-query((filters:build-search-query($params), $has-decision-date-query))
let $boosted-query := helper:boost-title-and-ncn($q, $query)

(: Build search options :)

let $show-snippets as xs:boolean := fn:boolean(($q and not(helper:is-a-consignment-number($q))) or $party or $judge)

(: Build document options once. date/transformation sort-order live here;
   order=updated branches inside resolve-paged-search (properties index-order). :)
let $sort-order := if ($sort-word = 'date') then
    <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:date" direction="{$sort-direction}">
            <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">akn:judgment/akn:meta/akn:identification/akn:FRBRWork/akn:FRBRdate/@date</path-index>
        </sort-order>
else if ($sort-word = 'transformation') then
    <sort-order xmlns="http://marklogic.com/appservices/search" type="xs:dateTime" direction="{$sort-direction}">
        <path-index xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">akn:akomaNtoso/akn:judgment/akn:meta/akn:identification/akn:FRBRManifestation/akn:FRBRdate[@name='transform']/@date</path-index>
    </sort-order>
else
    ()

let $transform-results := if ($show-snippets) then
    helper:snippet-transform-results($quoted_phrases)
else
    <transform-results xmlns="http://marklogic.com/appservices/search" apply="empty-snippet" />

let $document-options := <options xmlns="http://marklogic.com/appservices/search">
    <fragment-scope>documents</fragment-scope>
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
        <extract-path>//uk:name</extract-path>
        <extract-path>//uk:transfer-consignment-number</extract-path>
    </extract-document-data>
    { $transform-results }
</options>

return helper:resolve-paged-search(
    $boosted-query,
    $sort-word,
    $sort-direction,
    $start,
    $page-size,
    $document-options
)
