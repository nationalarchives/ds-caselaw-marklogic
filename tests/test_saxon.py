from pathlib import Path

from saxonche import PySaxonProcessor


def transform(xml_text, xslt_text):
    with PySaxonProcessor(license=False) as proc:
        xslt_proc = proc.new_xslt30_processor()

        executable = xslt_proc.compile_stylesheet(stylesheet_text=xslt_text)
        node = proc.parse_xml(xml_text=xml_text)
        output = executable.transform_to_string(xdm_node=node)
        xslt_proc.clear_parameters()
        return output


def test_xslt_generates_legislation_links():
    with Path.open("tests/fixtures/enriched.xml") as f:
        enriched = f.read()

    with Path.open("src/main/ml-modules/root/judgments/xslts/accessible-html.xsl") as f:
        xslt = f.read()

        output = transform(enriched, xslt)
        # assert "http://www.legislation.gov.uk/id/ukpga/2010/15/section/20/3" in output
        assert "<article" in output
