<?xml version="1.0" encoding="UTF-8"?>
<!--
Map a file in a xml format into another one via a mapping schema and a mapper api.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

See other notes inside xml_mapper.xsl.

@version: 20160222
@copyright Daniel Berthereau, 2015-2016
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<!-- Note: Source namespace may be needed and prefix excluded if paths are prefixed. -->
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:ead="http://www.loc.gov/ead"

    exclude-result-prefixes="xsl xs">

    <!-- Import mapper api. -->
    <xsl:import href="XmlMapper/xslt_1/xml_mapper_api.xsl" />

    <!-- Specific rules that are not currently managed by the mapper api. -->
    <xsl:import href="xslt_1/ead2dcterms_rules.xsl" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:strip-space elements="*" />

    <!-- Parameters -->

    <!-- Profile of options. The url should be absolute or, unlike xslt 2,
    relative to this file. -->
    <xsl:param name="configuration">ead2dcterms-omeka_config.xml</xsl:param>

    <!-- When the path is relative, some parsers use the absolute path of the
    first stylesheet, others use the absolute path of the imported stylesheet.
    So the "config" is defined here instead of "xml_mapper_api.xsl'. -->
    <xsl:variable name="config" select="document($configuration)/config" />

    <!-- Root of the document and namespaces should be set here, because they
    can be complex to manage in xslt 1. -->
    <xsl:template match="/ead:ead">
        <records
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:omeka="http://localhost/omeka"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                >
            <xsl:apply-templates select="/" mode="mapper" />
        </records>
    </xsl:template>

</xsl:stylesheet>
