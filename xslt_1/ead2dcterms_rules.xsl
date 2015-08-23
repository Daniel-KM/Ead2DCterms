<?xml version="1.0" encoding="UTF-8"?>
<!--
Additional sheet used to map EAD and Dublin Core Metadata Terms.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->
<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    exclude-result-prefixes="xsl xs">

    <xsl:template name="get-node-extra-function-mapper">
        <xsl:param name="function" />
        <xsl:param name="arguments" />
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <xsl:template match="/|*" mode="get-identifier">
        <xsl:param name="base_xpath" select="''" />

        <xsl:choose>
             <xsl:when test="count(*) + count(@*) + count(namespace::*) = 0
                    and normalize-space(.) = ''">
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="name"
                    select="name()" />

                <!-- These identifiers should be the same than in the mapping. -->
                <xsl:choose>
                    <xsl:when test="$name = 'eadheader'">
                        <xsl:variable name="base_id">
                            <xsl:call-template name ="get-base-id" />
                        </xsl:variable>
                        <xsl:value-of select="concat(
                                $base_id,
                                '/ead/eadheader')" />
                    </xsl:when>

                    <!-- By default, the "frontmapper" and the "eadheader" are
                    merged to build one record. -->
                    <xsl:when test="$name = 'frontmatter'">
                        <xsl:variable name="base_id">
                            <xsl:call-template name ="get-base-id" />
                        </xsl:variable>
                        <xsl:value-of select="concat(
                                $base_id,
                                '/ead/eadheader')" />
                    </xsl:when>

                    <xsl:when test="$name = 'archdesc'">
                        <xsl:variable name="base_id">
                            <xsl:call-template name ="get-base-id" />
                        </xsl:variable>
                        <xsl:value-of select="concat(
                                $base_id,
                                '/ead/archdesc')" />
                    </xsl:when>

                    <!-- By default, dsc is not managed separately. -->
                    <xsl:when test="$name = 'dsc'">
                        <!--
                        <xsl:value-of select="mapper:get-identifier(mapper:get-ancestor(.))" />
                        -->
                        <xsl:variable name="ancestor">
                            <xsl:call-template name="get-ancestor">
                                <xsl:with-param name="node" select="." />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:apply-templates select="$ancestor" mode="get-identifier" />
                    </xsl:when>

                    <!--
                    <xsl:when test="index-of(tokenize('c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12', '\|'), $name) &gt; 0">
                        <xsl:value-of select="concat(
                                mapper:get-base-id(),
                                mapper:get-absolute-xpath(.))" />
                    -->
                    <xsl:when test="contains('|c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12|', concat('|', $name, '|'))">
                        <xsl:variable name="base_id">
                            <xsl:call-template name ="get-base-id" />
                        </xsl:variable>

                        <xsl:variable name="absolute_xpath">
                            <xsl:call-template name ="get-absolute-xpath" />
                        </xsl:variable>

                        <xsl:value-of select="concat($base_id, $base_xpath, $absolute_xpath)" />
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
        <xsl:param name="node" select="." />
        <xsl:param name="base_xpath" select="''" />

        <xsl:choose>
            <xsl:when test="not($node)">
            </xsl:when>

            <xsl:when test="string($base_xpath) != ''">
                <xsl:call-template name="get-ancestor-identifier-via-xpath">
                    <xsl:with-param name="xpath" select="$base_xpath" />
                </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>
                <!--
                <xsl:sequence select="$node/ancestor::element()
                        [boolean(index-of(
                            tokenize(
                                'eadheader|frontmatter|archdesc|c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12',
                                '\|'),
                            name()))]
                        [1]" />
                -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Recursive helper to get ancestor from an xpath. -->
    <xsl:template name="get-ancestor-identifier-via-xpath">
        <xsl:param name="xpath" select="''" />

        <xsl:variable name="parent_xpath">
            <xsl:call-template name="remove-last-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="parent_expression">
            <xsl:call-template name="get-last-part-of-xpath">
                <xsl:with-param name="xpath" select="$parent_xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="parent_element">
            <xsl:choose>
                <xsl:when test="contains($parent_expression, '[')">
                    <xsl:value-of select="translate(substring-before($parent_expression, '['), '/', '')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="translate($parent_expression, '/', '')" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($parent_xpath) = ''">
                <xsl:text></xsl:text>
            </xsl:when>

            <xsl:when test="contains(
                    '|eadheader|frontmatter|archdesc|c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12|',
                    concat('|', $parent_element, '|'))">

                <xsl:variable name="base_id">
                    <xsl:call-template name ="get-base-id" />
                </xsl:variable>

                <xsl:value-of select="concat($base_id, $parent_xpath)" />
            </xsl:when>

            <xsl:otherwise>
                <xsl:call-template name="get-ancestor-identifier-via-xpath">
                    <xsl:with-param name="xpath" select="$parent_xpath" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

