let $uris := cts:uris(
  "",
  (),
  cts:and-query((
    cts:collection-query("http://marklogic.com/collections/dls/latest-version"),
    cts:properties-query(
      cts:and-query((
        cts:element-value-query(xs:QName("published"), "true"),
        cts:not-query(
          cts:element-query(xs:QName("first_published_datetime"), cts:true-query())
        )
      ))
    )
  ))
)
return (count($uris), $uris)
