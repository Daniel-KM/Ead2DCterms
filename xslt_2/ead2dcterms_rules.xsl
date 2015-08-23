<?xml version="1.0" encoding="UTF-8"?>
<!--
Additional sheet used to map EAD and Dublin Core Metadata Terms.

This version uses xslt version 2.0.

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:e2d="http://ead2dcterms"
    xmlns:mapper="http://mapper"

    exclude-result-prefixes="xsl xs e2d mapper">

    <xsl:template name="get-node-extra-function-mapper">
        <xsl:param name="function" as="xs:string" />
        <xsl:param name="arguments" as="item()*" />
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <xsl:template match="*" mode="get-identifier">
        <xsl:choose>
            <xsl:when test="empty(.)">
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="name" as="xs:string?"
                    select="name(.)" />

                <!-- These identifiers should be the same than in the mapping. -->
                <xsl:choose>
                    <xsl:when test="$name = 'eadheader'">
                        <xsl:value-of select="concat(
                                mapper:get-base-id(),
                                '/ead/eadheader')" />
                    </xsl:when>

                    <!-- By default, the "frontmapper" and the "eadheader" are
                    merged to build one record. -->
                    <xsl:when test="$name = 'frontmatter'">
                        <xsl:value-of select="concat(
                                mapper:get-base-id(),
                                '/ead/eadheader')" />
                    </xsl:when>

                    <xsl:when test="$name = 'archdesc'">
                        <xsl:value-of select="concat(
                                mapper:get-base-id(),
                                '/ead/archdesc')" />
                    </xsl:when>

                    <!-- By default, dsc is not managed separately. -->
                    <xsl:when test="$name = 'dsc'">
                        <xsl:value-of select="mapper:get-identifier(mapper:get-ancestor(.))" />
                    </xsl:when>

                    <xsl:when test="boolean(index-of(tokenize('c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12', '\|'), $name))">
                        <xsl:value-of select="concat(
                                mapper:get-base-id(),
                                mapper:get-absolute-xpath(.))" />
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:text></xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper to get the ancestor of a node in order to manage hierarchical relations. -->
    <xsl:template name="get-ancestor">
        <xsl:param name="node" as="node()?" select="." />

        <xsl:choose>
            <xsl:when test="empty($node)">
            </xsl:when>

            <xsl:otherwise>
                <xsl:sequence select="$node/ancestor::element()
                        [boolean(index-of(
                            tokenize(
                                'eadheader|frontmatter|archdesc|c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12',
                                '\|'),
                            name()))]
                        [1]" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>

