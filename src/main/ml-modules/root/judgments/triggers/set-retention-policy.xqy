xquery version "1.0-ml";
import module namespace dls="http://marklogic.com/xdmp/dls"
              at "/MarkLogic/dls.xqy";

(: Run by the database-online trigger and at the end of every deployment
   (see the applyRetentionPolicy task in build.gradle), so it must be safe to
   run repeatedly: dls:retention-rule-insert raises DLS-DUPLICATERULE if the
   rule already exists. :)
let $rule-name := "All Versions Retention Rule"
return
  if (fn:exists(dls:retention-rules($rule-name))) then ()
  else
    dls:retention-rule-insert(
        dls:retention-rule(
            $rule-name,
            "Retain all versions of all documents",
            (),
            (),
            "Locate all of the documents",
            cts:and-query(())
        )
    )
