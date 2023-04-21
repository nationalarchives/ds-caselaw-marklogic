#!/bin/bash

saxon -s:tests/paragraph/test-input.xml accessible-html.xsl -it:paragraph-template > tests/paragraph/actual-output.xml
diff tests/paragraph/expected-output.xml tests/paragraph/actual-output.xml
rm tests/paragraph/actual-output.xml

# for file in *.xsl
# do
#     saxon test-input.xml "$file" > "${file%.*}-actual-output.xml"
#     diff -q "${file%.*}-expected-output.xml" "${file%.*}-actual-output.xml"
# done