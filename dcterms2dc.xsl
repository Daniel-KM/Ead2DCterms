<?xml version="1.0" encoding="UTF-8"?>
<!--
Map a file in a xml format into another one via a mapping schema and a mapper api.

This version uses xslt version 2.0.

See notes inside readme.md and xml_mapper.xsl.

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<!-- Note: Source namespace may be needed and prefix excluded if paths are prefixed. -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    exclude-result-prefixes="xsl xs">

    <!-- Import mapper api. -->
    <xsl:import href="XmlMapper/xslt_2/xml_mapper_api.xsl" />

    <!-- Specific rules that are not currently managed by the mapper api. -->

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:strip-space elements="*" />

    <!-- Parameters -->

    <!-- Profile of options. The url should be absolute or relative to "xml_mapper_api.xml". -->
    <xsl:param name="configuration" as="xs:string+">../../dcterms2dc_config.xml</xsl:param>

</xsl:stylesheet>
