<?xml version="1.0" encoding="UTF-8"?>
<!--
Map a file in a xml format into another one via a mapping schema and a mapper api.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

The xslt 1 version works only with some extensions, not with a parser that
follows strictly the standard. The parser should be able to interpret a tree
fragment as a node set.

Notes on xslt 1 version
- Xslt 1 is about ten to twenty times slower than xslt 2, and is harder to
  maintain, so it should be avoided.
- Xslt 1 doesn't support sequence, but only supports "copy-of", so "ancestor"
  and some other axis are not directly managed.
- Another limitation is that only one value can be returned from a template,
  that can be a problem when the needed value is an attribute.
- To bypass this limitation, each value is returned inside a wrapper "node" that
  contains the path of the current node. This is useful specially to get the
  full path for node that are selected with "//" ("descendant-or-self"). See the
  "dynamic_xpath_sequence.xsl" too.
- This stylesheet is not fully checked, in particular for axis (except "self",
  "child" and "//").
- It is not maintained, except when an update is done on the xslt 2 or on a
  mapping.

Notes on parsers for xslt 1
- Xslt 2 parsers are generally compatible with xslt 1 stylesheets, but some
  differences may occur. Furthermore, xslt parsers may be configured variously,
  so some checks should be done.
- Parsers can manage the relative path for "document()" differently when there
  is an "import".
- Parsers can manage whitespaces differently: multiple "copy-of" of a string may
  not be the same as a "concat()".
- Parsers doesn't interpret "$var = ''" the same way when $var is null, for
  example after a "normalize-space()" of an empty string after a call-template,
  so a "string($var)" (or a "normalize-space()", or a "not()") is added
  systematically for tests of variables, even when it's not needed.
- The function "name()" id allowed only on one node.

See notes inside xml_mapper_api.xsl.

TODO
- Strict parser for xslt 1.

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<!-- Note: Source namespace may be needed and prefix excluded if paths are prefixed. -->
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    exclude-result-prefixes="xsl xs">

    <!-- Import mapper api. -->
    <xsl:import href="xml_mapper_api.xsl" />

    <!-- Specific rules that are not currently managed by the mapper api. -->
    <!-- TODO Dynamic import (or create a specific mapper from this one). -->
    <!-- <xsl:import href="alpha2omega_rules.xsl" /> -->

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:strip-space elements="*" />

    <!-- Parameters -->

    <!-- Profile of options. The url should be absolute or, unlike xslt 2,
    relative to this file. -->
    <!-- This config file is empty: Define your own. -->
    <xsl:param name="configuration">../xml_mapper_config.xml</xsl:param>

    <!-- When the path is relative, some parsers use the absolute path of the
    first stylesheet, others use the absolute path of the imported stylesheet.
    So the "config" is defined here instead of "xml_mapper_api.xsl'. -->
    <xsl:variable name="config" select="document($configuration)/config" />

    <!-- Root of the document and namespaces should be set here, because they
    can be complex to manage in xslt 1. -->
    <xsl:template match="/">
        <!-- Example. -->
        <!--
        <records
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                >
        -->
        <records>
            <xsl:apply-templates select="/" mode="mapper" />
        </records>
    </xsl:template>

</xsl:stylesheet>
