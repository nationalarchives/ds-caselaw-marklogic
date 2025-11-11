from collections import Counter
from pathlib import Path

import lxml.etree

"""Filter validation log for insights"""

NAMESPACES = {"xdmp": "http://marklogic.com/xdmp", "error": "http://marklogic.com/xdmp/error"}

with Path("../corb2/validate.log").open() as f:
    root = lxml.etree.fromstring(f.read())


def summary():
    count_errors = 0
    count_total = 0
    for validate in root.xpath("//validation"):
        uri = validate.xpath("./uri/text()")[0]
        errors = validate.xpath(".//xdmp:validation-errors", namespaces=NAMESPACES)[0]
        count_errors += int(bool(errors))
        count_total += 1
        print(uri, bool(errors))
    print(count_errors, count_total, count_errors / count_total)


def format_strings():
    return [
        lxml.etree.tostring(fstring).decode("utf-8")
        for fstring in root.xpath("//error:format-string", namespaces=NAMESPACES)
    ]


def clean_format_strings():
    builder = []
    for fstring in format_strings():
        s = fstring
        s = s.partition(" but expected")[0]
        s = s.partition(" but required")[0]
        s = s.partition(" at fn:doc")[0]
        s = s.partition(" -- ")[2]
        builder.append(s)

    set_builder = Counter(builder)
    for string, count in sorted(set_builder.items(), key=lambda x: x[1]):
        print(count, string)
        print(sample_full_string(string))


def sample_full_string(s):
    for fstring in format_strings():
        if s in fstring:
            return fstring
    return None


clean_format_strings()
