<?xml version="1.0" encoding="UTF-8"?>
<!--
Generic helpers for the xml mapper.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    exclude-result-prefixes="xsl fn xs">

    <!-- Import dynamic xpath evaluator. -->
    <xsl:import href="dynamic_xpath_evaluator.xsl" />

    <!-- Recursive wrap one or multiple tags with or without attributes around a value. -->
    <xsl:template name="wrap-value">
        <xsl:param name="value" />
        <xsl:param name="wrap" />

        <xsl:choose>
            <xsl:when test="not($wrap)">
                <xsl:copy-of select="$value" />
            </xsl:when>
            <xsl:when test="not(contains($wrap, '/'))">
                <xsl:call-template name="wrap-value-tag">
                    <xsl:with-param name="value" select="$value" />
                    <xsl:with-param name="wrap" select="$wrap" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="last_wrap">
                    <xsl:call-template name="substring-after-last">
                        <xsl:with-param name="string" select="$wrap" />
                        <xsl:with-param name="substring" select="'/'" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="next_wraps">
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="string" select="$wrap" />
                        <xsl:with-param name="substring" select="'/'" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="wrapped_value">
                    <xsl:call-template name="wrap-value-tag">
                        <xsl:with-param name="value" select="$value" />
                        <xsl:with-param name="wrap" select="$last_wrap" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:call-template name="wrap-value">
                    <xsl:with-param name="value" select="$wrapped_value" />
                    <xsl:with-param name="wrap" select="$next_wraps" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Wrap one tag with or without attributes around a value. -->
    <xsl:template name="wrap-value-tag">
        <xsl:param name="value" />
        <xsl:param name="wrap" />

        <xsl:variable name="tag">
            <!--
            select="if (contains($wrap, '@')) then substring-before($wrap, '@') else $wrap" />
            -->
            <xsl:choose>
                <xsl:when test="contains($wrap, '@')">
                    <xsl:value-of select="substring-before($wrap, '@')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$wrap" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="attributes"
            select="normalize-space(substring-after($wrap, '@'))" />

        <xsl:element name="{normalize-space($tag)}">
            <xsl:if test="string($attributes) != ''">
                <xsl:variable name="tokens">
                    <xsl:call-template name="tokenize">
                        <xsl:with-param name="string" select="$attributes" />
                        <xsl:with-param name="separator" select="'@'" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="$tokens/token">
                    <xsl:attribute name="{normalize-space(substring-before(., '='))}">
                        <xsl:value-of select="normalize-space(substring-after(., '='))" />
                    </xsl:attribute>
                </xsl:for-each>
            </xsl:if>
            <xsl:copy-of select="$value" />
        </xsl:element>
    </xsl:template>

    <!-- Templates used to normalize spaces. -->
    <xsl:template match="*" mode="normalize_space">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="normalize_space" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*" mode="normalize_space">
        <xsl:copy>
            <xsl:attribute name="{name()}">
                <xsl:value-of select="normalize-space(.)" />
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/node()/text()" mode="normalize_space">
        <xsl:if test="starts-with(., ' ') and preceding-sibling::node()[1]">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="normalize-space(.)" />
        <xsl:if test="substring(., string-length(.)) = ' ' and following-sibling::node()[1]">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="text()" mode="normalize_space">
        <xsl:if test="starts-with(., ' ') and ../preceding-sibling::node()[1]">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="normalize-space(.)" />
        <xsl:if test="substring(., string-length(.)) = ' ' and ../following-sibling::node()[1]">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Deduplicate a flat tree. -->
    <xsl:template match="/" mode="deduplicate_flat_tree">
        <!--
        <xsl:for-each-group select="*" group-by="name()">
            <xsl:for-each-group select="current-group()" group-by=".">
                <xsl:copy-of select="current-group()[1]" />
            </xsl:for-each-group>
        </xsl:for-each-group>
        -->

        <!-- The Muenchian Method can't be used directly, because this is not
        against the source. Like each record is generally small, the method is
        good enough (select each element, then copy only different contents for
        all the same elements). -->
        <xsl:variable name="current" select="." />
        <xsl:for-each select="*">
            <xsl:variable name="name" select="name(.)" />
            <xsl:if test="count(preceding-sibling::*[name() = $name]) = 0">
                <xsl:copy-of select="$current/*[name() = $name]
                        [not(. = preceding-sibling::*[name() = $name])]" />
            </xsl:if>
        </xsl:for-each>
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
    <!-- TODO Convert to use the "except" operator. -->
    <xsl:template name="copy-except">
        <xsl:param name="elements" />
        <xsl:param name="node" select="." />

        <xsl:apply-templates select="$node" mode="get-node-except">
            <xsl:with-param name="elements" select="$elements" />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Helper to copy all the nodes, except someones, via an identity template
    and a list of elements. -->
    <xsl:template match="@*|node()" mode="get-node-except">
        <xsl:param name="elements" />
        <!--
        <xsl:if test="not(index-of(tokenize($elements, '\|'), local-name()))">
        -->
        <xsl:if test="not(contains(
                concat('|', $elements, '|'),
                concat('|', local-name(), '|')))">
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" mode="get-node-except">
                    <xsl:with-param name="elements" select="$elements" />
                </xsl:apply-templates>
            </xsl:copy>
       </xsl:if>
    </xsl:template>

    <!-- Helper to get the absolute, simple and unique xpath of a node.
    The position is added when there are siblings (example: "c02[19]"). -->
    <xsl:template name="get-absolute-xpath">
        <xsl:param name="node" select="." />

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

    <!-- ==============================================================
    Specific helpers for xslt 1.
    =============================================================== -->

    <xsl:template name="substring-replace">
        <xsl:param name="string" select="''" />
        <xsl:param name="replace" select="''" />
        <xsl:param name="with" select="''" />

        <xsl:choose>
            <xsl:when test="string($string) != '' and string($replace) != '' and contains($string, $replace)">
                <xsl:value-of select="substring-before($string, $replace)" />
                <xsl:value-of select="$with" />
                <xsl:call-template name="substring-replace">
                    <xsl:with-param name="string" select="substring-after($string, $replace)" />
                    <xsl:with-param name="replace" select="$replace" />
                    <xsl:with-param name="with" select="$with" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Some parsers add whitespaces between texts, so "concat()" is used.-->
    <xsl:template name="string-join-with-empty">
        <xsl:param name="strings" />
        <xsl:param name="string" select="''" />

        <xsl:choose>
            <xsl:when test="count($strings/text()) &gt; 0">
                <xsl:call-template name="string-join-with-empty">
                    <xsl:with-param name="strings" select="$strings/text()[not(position() = 1)]" />
                    <xsl:with-param name="string" select="concat($string, $strings/text()[1])" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="concat($string, $strings)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
