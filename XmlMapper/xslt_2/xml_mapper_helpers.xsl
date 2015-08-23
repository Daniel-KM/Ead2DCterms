<?xml version="1.0" encoding="UTF-8"?>
<!--
Generic helpers for the xml mapper.

This version uses xslt version 2.0.

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:mapper="http://mapper"

    exclude-result-prefixes="xsl fn xs mapper">

    <!-- Recursive wrap one or multiple tags with or without attributes around a value. -->
    <xsl:function name="mapper:wrap-value" as="item()?">
        <xsl:param name="value" as="item()?" />
        <xsl:param name="wrap" as="xs:string?" />

            <xsl:call-template name="wrap-value">
                <xsl:with-param name="value" select="$value" />
                <xsl:with-param name="wrap" select="$wrap" />
            </xsl:call-template>
    </xsl:function>

    <xsl:template name="wrap-value">
        <xsl:param name="value" as="item()?" />
        <xsl:param name="wrap" as="xs:string?" />

        <xsl:choose>
            <xsl:when test="not($wrap)">
                <xsl:sequence select="$value" />
            </xsl:when>
            <xsl:when test="not(contains($wrap, '/'))">
                <xsl:call-template name="wrap-value-tag">
                    <xsl:with-param name="value" select="$value" />
                    <xsl:with-param name="wrap" select="$wrap" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="wrap-value">
                    <xsl:with-param name="value">
                        <xsl:call-template name="wrap-value-tag">
                            <xsl:with-param name="value" select="$value" />
                            <xsl:with-param name="wrap" select="tokenize($wrap, '/')[last()]" />
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="wrap"
                        select="string-join(tokenize($wrap, '/')[position() != last()], '/')" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Wrap one tag with or without attributes around a value. -->
    <xsl:template name="wrap-value-tag">
        <xsl:param name="value" as="item()" />
        <xsl:param name="wrap" as="xs:string*" />

        <xsl:variable name="tag" as="xs:string*"
            select="if (contains($wrap, '@')) then substring-before($wrap, '@') else $wrap" />

        <xsl:variable name="attributes" as="xs:string*"
            select="normalize-space(substring-after($wrap, '@'))" />

        <xsl:element name="{normalize-space($tag)}">
            <xsl:if test="$attributes != ''">
                <xsl:for-each select="tokenize($attributes, '@')">
                    <xsl:attribute name="{normalize-space(substring-before(., '='))}">
                        <xsl:value-of select="normalize-space(substring-after(., '='))" />
                    </xsl:attribute>
                </xsl:for-each>
            </xsl:if>
            <xsl:sequence select="$value" />
        </xsl:element>
    </xsl:template>

    <!-- Templates used to normalize spaces. -->
    <xsl:template match="element()" mode="normalize_space">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="normalize_space" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*" mode="normalize_space">
        <xsl:copy>
            <xsl:attribute name="{name()}" select="normalize-space(.)" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/node()/text()" mode="normalize_space">
        <xsl:value-of select="concat(
                if (starts-with(., ' ') and preceding-sibling::node()[1]) then ' ' else '',
                normalize-space(.),
                if (ends-with(., ' ') and following-sibling::node()[1]) then ' ' else ''
            )" />
    </xsl:template>

    <xsl:template match="text()" mode="normalize_space">
        <xsl:value-of select="concat(
                if (starts-with(., ' ') and ../preceding-sibling::node()[1]) then ' ' else '',
                normalize-space(.),
                if (ends-with(., ' ') and ../following-sibling::node()[1]) then ' ' else ''
            )" />
    </xsl:template>

    <!-- Deduplicate a flat tree. -->
    <xsl:template match="/" mode="deduplicate_flat_tree">
        <xsl:for-each-group select="*" group-by="name()">
            <xsl:for-each-group select="current-group()" group-by=".">
                <xsl:copy-of select="current-group()[1]" />
            </xsl:for-each-group>
        </xsl:for-each-group>
    </xsl:template>

    <!-- Template used to copy nodes without namespaces. -->
    <xsl:template match="*" mode="copy_without_namespace">
        <xsl:element name="{local-name()}">
            <xsl:copy-of select="@*" />
            <xsl:apply-templates select="text()|*" mode="copy_without_namespace" />
        </xsl:element>
    </xsl:template>

    <!-- Helper to copy all the nodes, except someones. -->
    <!-- Note: The original node will be partial: the ancestor is not copied. -->
    <!-- TODO Convert to use a standard identify template. -->
    <xsl:function name="mapper:copy-except">
        <xsl:param name="elements" as="xs:string*" />
        <xsl:param name="node" as="node()*" />

        <xsl:apply-templates select="$node" mode="get-node-except">
            <xsl:with-param name="elements" select="$elements" />
        </xsl:apply-templates>
    </xsl:function>

    <!-- Helper to copy all the nodes, except someones, via an identity template
    and a list of elements. -->
    <xsl:template match="@*|node()" mode="get-node-except">
        <xsl:param name="elements" as="xs:string" />

        <xsl:if test="not(index-of(tokenize($elements, '\|'), local-name()))">
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" mode="get-node-except">
                    <xsl:with-param name="elements" select="$elements" />
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <!-- Helper to get the absolute, simple and unique xpath of a node.
    The position is added when there are siblings (example: "c02[19]"). -->
    <xsl:function name="mapper:get-absolute-xpath" as="xs:string">
        <xsl:param name="node" as="node()" />

        <xsl:variable name="xpath">
            <xsl:call-template name="get-absolute-xpath">
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:value-of select="$xpath" />
    </xsl:function>

    <xsl:template name="get-absolute-xpath">
        <xsl:param name="node" as="node()" select="." />

        <xsl:choose>
            <xsl:when test="count($node/ancestor-or-self::*) = 0">
                   <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$node/ancestor-or-self::*">
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="local-name()" />
                    <xsl:if test="preceding-sibling::*[local-name() = local-name(current())]
                            or following-sibling::*[local-name() = local-name(current())]">
                        <xsl:text>[</xsl:text>
                        <xsl:value-of select="string(
                                count(preceding-sibling::*[local-name() = local-name(current())])
                                + 1)" />
                        <xsl:text>]</xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
