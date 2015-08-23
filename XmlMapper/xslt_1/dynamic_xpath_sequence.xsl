<?xml version="1.0" encoding="UTF-8"?>
<!--
Dynamic xpath evaluator / sequence.

This file is part of the dynamic xpath evaluator for xslt 1. It allows to return
sequences of nodes and unique xpath.

Notes
- Axis "preceding", "following" and siblings are not supported.
- Union ("|") is managed as relative to the current context.
- For "ancestor", only the first is selected, even with the contextual union.
- For "descendant-or-self", the order may be different.
- For predicates, only position() and last() have been checked.

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

    <!-- Replace the element "sequence" of xslt 2: each result is wrapped in an
    element "node", that contains the unique and simple relative xpath. -->
    <xsl:template name="get-sequence">
        <xsl:param name="xpath" />
        <xsl:param name="node" select="." />

        <xsl:variable name="path" select="normalize-space($xpath)" />

        <xsl:variable name="node_base">
            <xsl:choose>
                <!-- There is and should be only one node the first time. -->
                <xsl:when test="not($node/node)">
                    <node xpath="">
                        <xsl:copy-of select="$node" />
                    </node>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$node" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <!-- Quick checks and shorts. -->
            <xsl:when test="string($path) = '' or not($node)">
            </xsl:when>

            <!-- This path is allowed only for the root. -->
            <xsl:when test="$path = '/'">
                <xsl:copy-of select="$node_base" />
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="first_xpath">
                    <xsl:call-template name="get-first-part-of-xpath">
                        <xsl:with-param name="xpath" select="$path" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="next_xpath">
                    <xsl:call-template name="get-next-part-of-xpath">
                        <xsl:with-param name="xpath" select="$path" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="current_sequence">
                    <xsl:call-template name="get-current-sequence">
                        <xsl:with-param name="xpath" select="$first_xpath" />
                        <xsl:with-param name="sequence" select="$node_base" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="string($next_xpath) = '' or $next_xpath = '/.'">
                        <xsl:copy-of select="$current_sequence" />
                    </xsl:when>
                    <xsl:when test="$next_xpath = '/'">
                    </xsl:when>
                    <xsl:when test="not($current_sequence/node)">
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-sequence">
                            <xsl:with-param name="xpath" select="$next_xpath" />
                            <xsl:with-param name="node" select="$current_sequence" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Template to process a simple part.
    =============================================================== -->

    <!-- Process a single part of an xpath (only one expression, no check is done). -->
    <xsl:template name="get-current-sequence">
        <xsl:param name="xpath" />
        <xsl:param name="sequence" select="." />

        <!-- Normalize the xpath: remove the first "/" except if "//". -->
        <xsl:variable name="n_path" select="normalize-space($xpath)" />
        <xsl:variable name="path">
            <!--
                if (starts-with($n_path, '//'))
                then $n_path
                else if (starts-with($n_path, '/'))
                    then normalize-space(substring($n_path, 2))
                    else $n_path" />
            -->
            <xsl:choose>
                <xsl:when test="starts-with($n_path, '//')">
                    <xsl:value-of select="$n_path" />
                </xsl:when>
                <xsl:when test="starts-with($n_path, '/')">
                    <xsl:value-of select="normalize-space(substring($n_path, 2))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$n_path" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($path) = ''">
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="is_function">
                    <xsl:call-template name="is-function">
                        <xsl:with-param name="string" select="$path" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <!-- Check if the path is a function. -->
                    <xsl:when test="$is_function = 'true'">
                        <xsl:variable name="first_parenthesis"
                            select="string-length(substring-before($path, '(')) + 1" />
                        <xsl:call-template name="get-sequence-function">
                            <xsl:with-param name="function"
                                select="substring-before($path, '(')" />
                            <xsl:with-param name="arguments"
                                select="substring($path, $first_parenthesis + 1, string-length($path) - $first_parenthesis - 1)" />
                            <xsl:with-param name="sequence" select="$sequence" />
                        </xsl:call-template>
                    </xsl:when>

                    <!-- Else this is a simple expression, with or without filters. -->
                    <xsl:otherwise>
                        <xsl:variable name="first_bracket">
                            <!--
                                if (contains($path, '['))
                                then string-length(substring-before($path, '[')) + 1
                                else 0" />
                            -->
                            <xsl:choose>
                                <xsl:when test="contains($path, '[')">
                                    <xsl:value-of select="string-length(substring-before($path, '[')) + 1" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:variable name="expression">
                            <!--
                                if ($first_bracket &gt; 0)
                                then normalize-space(substring($path, 1, $first_bracket - 1))
                                else $path" />
                            -->
                            <xsl:choose>
                                <xsl:when test="$first_bracket &gt; 0">
                                    <xsl:value-of select="normalize-space(substring($path, 1, $first_bracket - 1))" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$path" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:variable name="filters">
                            <!--
                                if ($first_bracket &gt; 0)
                                then substring($path, $first_bracket)
                                else ''" />
                            -->
                            <xsl:choose>
                                <xsl:when test="$first_bracket &gt; 0">
                                    <xsl:value-of select="substring($path, $first_bracket)" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text></xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:variable name="result_sequence">
                            <!--
                            select="dynx:get-node-simple($expression, $node)" />
                            -->
                            <xsl:call-template name="get-sequence-simple">
                                <xsl:with-param name="xpath" select="$expression" />
                                <xsl:with-param name="sequence" select="$sequence" />
                            </xsl:call-template>
                        </xsl:variable>

                        <!--
                        <xsl:sequence select="dynx:filter-node($filters, $result_node)" />
                        -->
                        <xsl:call-template name="filter-sequence">
                            <xsl:with-param name="filter" select="$filters" />
                            <xsl:with-param name="sequence" select="$result_sequence" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Template to process an axis.
    =============================================================== -->

    <!-- Process a single part of a xpath (the path should be checked: no
    function, no predicate). -->
    <xsl:template name="get-sequence-simple">
        <xsl:param name="xpath" />
        <xsl:param name="sequence" select="." />

        <!-- Simplify the xpath. -->
        <xsl:variable name="n_path" select="normalize-space($xpath)" />
        <xsl:variable name="path">
            <!--
                if (starts-with($n_path, '//'))
                then normalize-space(substring($n_path, 3))
                else if (starts-with($n_path, '/'))
                    then normalize-space(substring($n_path, 2))
                    else $n_path" />
            -->
            <xsl:choose>
                <xsl:when test="starts-with($n_path, '//')">
                    <xsl:value-of select="normalize-space(substring($n_path, 3))" />
                </xsl:when>
                <xsl:when test="starts-with($n_path, '/')">
                    <xsl:value-of select="normalize-space(substring($n_path, 2))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$n_path" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="axis">
            <!--
                if (contains($path, '::'))
                then normalize-space(substring-before($path, '::'))
                else if (starts-with($path, '@'))
                    then 'attribute'
                    else if ($path = '..')
                        then 'parent'
                        else 'child'" />
            -->
            <xsl:choose>
                <xsl:when test="contains($path, '::')">
                    <xsl:value-of select="normalize-space(substring-before($path, '::'))" />
                </xsl:when>
                <xsl:when test="starts-with($path, '@')">
                    <xsl:text>attribute</xsl:text>
                </xsl:when>
                <xsl:when test="$path = '..'">
                    <xsl:text>parent</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>child</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="element">
            <!--
                if (contains($path, '::'))
                then normalize-space(substring-after($path, '::'))
                else if (starts-with($path, '@'))
                    then normalize-space(substring-after($path, '@'))
                    else if ($path = '..')
                        then ''
                        else $path" />
            -->
            <xsl:choose>
                <xsl:when test="contains($path, '::')">
                    <xsl:value-of select="normalize-space(substring-after($path, '::'))" />
                </xsl:when>
                <xsl:when test="starts-with($path, '@')">
                    <xsl:value-of select="normalize-space(substring-after($path, '@'))" />
                </xsl:when>
                <xsl:when test="$path = '..'">
                    <xsl:text>node()</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$path" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <!-- Quick checks and shorts. -->
            <xsl:when test="string($path) = '' or not($sequence/node)
                    or string($axis) = '' or string($element) = ''">
            </xsl:when>

            <!-- "/" is not allowed for next path (only for root). -->
            <xsl:when test="$n_path = '/' or $path = '/'">
            </xsl:when>

            <xsl:when test="$path = '..'">
                <xsl:variable name="xpaths">
                    <xsl:apply-templates mode="xpaths_parent"
                        select="$sequence/node/@xpath">
                        <xsl:with-param name="element" select="''" />
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:apply-templates select="$xpaths/xpath" mode="xpaths_get-sequence" />
            </xsl:when>

            <!-- Recursive template for "//". -->
            <!-- Note: This recursive template is not used: because there is one
            level for notes, so the order of elements may be different. If
            "descendant-or-self" is used directly, the unique path is not the
            good one for the "self" node. -->
            <xsl:when test="starts-with($n_path, '//')">
                <!--
                <xsl:variable name="nodes">
                    <xsl:copy-of select="$sequence/node
                            [node()/self::*]" />
                    <xsl:apply-templates mode="sequence"
                        select="$sequence/node/node()
                            /descendant::node()" />
                </xsl:variable>
                <xsl:call-template name="get-sequence-simple">
                    <xsl:with-param name="xpath" select="$path" />
                    <xsl:with-param name="sequence" select="$nodes" />
                </xsl:call-template>
                -->
                <xsl:choose>
                    <xsl:when test="$axis = 'child'">
                        <xsl:choose>
                            <xsl:when test="string($element) != ''">
                                <!-- Distinction is useless, but kept temporarily. -->
                                <!-- TODO To be fixed: this should be "//*:refloc[1]", not "(//*:refloc)[1]"
                                (predicate has a greater priority than axis). -->
                                <xsl:choose>
                                    <xsl:when test="contains($element, '|')">
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node
                                                /descendant-or-self::node()
                                                /child::*
                                                    [contains(
                                                        concat('|', translate($element,' ', ''), '|'),
                                                        concat('|', local-name(), '|'))]" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node
                                                /descendant-or-self::node()
                                                /child::*
                                                    [local-name() = $element]" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:when>

                    <xsl:when test="$axis = 'attribute'">
                        <xsl:choose>
                            <xsl:when test="$element = '*'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node
                                        /descendant-or-self::node()
                                        /attribute::*" />
                            </xsl:when>
                            <!-- Distinction is useless, but kept temporarily. -->
                            <xsl:when test="contains($element, '|')">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node
                                        /descendant-or-self::node()
                                        /attribute::*
                                            [contains(
                                                concat('|', translate($element, ' ', ''), '|'),
                                                concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node
                                        /descendant-or-self::node()
                                        /attribute::*
                                            [local-name() = $element]" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- TODO Warn an error. -->
                    <xsl:otherwise>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <xsl:when test="$path = '.'">
                <xsl:copy-of select="$sequence" />
            </xsl:when>

            <xsl:when test="string($axis) != '' and string($element) != ''">
                <xsl:choose>
                    <xsl:when test="$element = '*'">
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /child::*
                                        " />
                            </xsl:when>

                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /attribute::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'following'">
                                <!-- TODO Axis following. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'following-sibling'">
                                <!-- TODO Axis following-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following-sibling::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding'">
                                <!-- TODO Axis preceding. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding-sibling'">
                                <!-- TODO Axis preceding-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding-sibling::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'namespace'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /namespace::*
                                        " />
                            </xsl:when>

                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath" />
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_self"
                                        select="$sequence/node/@xpath" />
                                    <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath" />
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'descendant'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                        " />
                            </xsl:when>

                            <!-- TODO Check order of descendants. -->
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of select="$sequence/node
                                        [node()/self::*]" />
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                        " />
                            </xsl:when>

                            <xsl:when test="$axis = 'parent'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_parent"
                                        select="$sequence/node/@xpath" />
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of select="$sequence/node
                                        [node()/self::*]" />
                            </xsl:when>

                            <!-- TODO Warn an error. -->
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- Manage contextual union. -->
                    <xsl:when test="contains($element, '|')">
                        <xsl:variable name="elements"
                            select="concat('|', translate($element, ' ', ''), '|')" />
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:choose>
                                    <xsl:when test="$sequence/node/@xpath = ''">
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node
                                                /child::node()
                                                    [contains($elements, concat('|', local-name(), '|'))]" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node/node()
                                                /child::node()
                                                    [contains($elements, concat('|', local-name(), '|'))]" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>

                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /attribute::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'following'">
                                <!-- TODO Axis following. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'following-sibling'">
                                <!-- TODO Axis following-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following-sibling::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding'">
                                <!-- TODO Axis preceding. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding-sibling'">
                                <!-- TODO Axis preceding-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding-sibling::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'namespace'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /namespace::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$elements" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$elements" />
                                    </xsl:apply-templates>
                                    <xsl:apply-templates mode="xpaths_self_union"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'descendant'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <!-- TODO Check order of descendants. -->
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of
                                    select="$sequence/node
                                        [node()/self::*
                                            [contains($elements, concat('|', local-name(), '|'))]
                                        ]" />
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                            [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'parent'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_parent_union"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of
                                    select="$sequence/node
                                        [node()/self::*
                                            [contains($elements, concat('|', local-name(), '|'))]
                                        ]" />
                            </xsl:when>

                            <!-- TODO Warn an error. -->
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- Manage simple expression. -->
                    <xsl:otherwise>
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:choose>
                                    <xsl:when test="$sequence/node/@xpath = ''">
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node
                                                /child::node()
                                                    [local-name() = $element]" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="sequence"
                                            select="$sequence/node/node()
                                                /child::node()
                                                    [local-name() = $element]" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>

                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /attribute::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'following'">
                                <!-- TODO Axis following. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'following-sibling'">
                                <!-- TODO Axis following-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /following-sibling::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding'">
                                <!-- TODO Axis preceding. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'preceding-sibling'">
                                <!-- TODO Axis preceding-sibling. -->
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /preceding-sibling::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'namespace'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /namespace::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:variable name="xpaths">
                                        <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_ancestor"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                    <xsl:apply-templates mode="xpaths_self"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'descendant'">
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <!-- TODO Check order of descendants. -->
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of
                                    select="$sequence/node
                                        [node()/self::*
                                            [local-name() = $element]
                                        ]" />
                                <xsl:apply-templates mode="sequence"
                                    select="$sequence/node/node()
                                        /descendant::*
                                            [local-name() = $element]" />
                            </xsl:when>

                            <xsl:when test="$axis = 'parent'">
                                <xsl:variable name="xpaths">
                                    <xsl:apply-templates mode="xpaths_parent"
                                        select="$sequence/node/@xpath">
                                        <xsl:with-param name="element" select="$element" />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                <xsl:apply-templates select="$xpaths/xpath"
                                    mode="xpaths_get-sequence" />
                            </xsl:when>

                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of
                                    select="$sequence/node
                                        [node()/self::*
                                            [local-name() = $element]
                                        ]" />
                            </xsl:when>

                            <!-- TODO Warn an error. -->
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- TODO Warn an error. -->
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Templates to process axis for sequence.
    =============================================================== -->

    <!-- Helper to process all specific axis, via get-sequence.
    This is the main template to get around xslt 1 limitations (no sequence).
    It avoids duplicate automatically.
    -->
    <xsl:template match="xpath[not(. = preceding-sibling::xpath)]"
        mode="xpaths_get-sequence">
        <xsl:call-template name="get-sequence">
            <xsl:with-param name="xpath" select="." />
            <xsl:with-param name="node" select="$input" />
       </xsl:call-template>
    </xsl:template>

    <!-- TODO This template is the same as "*" but may be used to process "self". -->
    <xsl:template match="/" mode="sequence">
        <xsl:variable name="unique">
            <xsl:call-template name="get-unique-xpath-for-node">
                <xsl:with-param name="node" select="." />
                <xsl:with-param name="previous_xpath"
                    select="ancestor::node[last()]/@xpath" />
            </xsl:call-template>
        </xsl:variable>
        <node xpath="{$unique}">
            <xsl:copy-of select="." />
        </node>
    </xsl:template>

    <xsl:template match="*" mode="sequence">
        <xsl:variable name="unique">
            <xsl:call-template name="get-unique-xpath-for-node">
                <xsl:with-param name="node" select="." />
                <xsl:with-param name="previous_xpath"
                    select="ancestor::node[last()]/@xpath" />
            </xsl:call-template>
        </xsl:variable>
        <node xpath="{$unique}">
            <xsl:copy-of select="." />
        </node>
    </xsl:template>

    <xsl:template match="@*" mode="sequence">
        <xsl:variable name="unique">
            <xsl:call-template name="get-unique-xpath-for-node">
                <xsl:with-param name="node" select="." />
                <xsl:with-param name="previous_xpath"
                    select="ancestor::node[last()]/@xpath" />
                <xsl:with-param name="attribute" select="local-name()" />
            </xsl:call-template>
        </xsl:variable>
        <node xpath="{$unique}">
            <xsl:value-of select="." />
        </node>
    </xsl:template>

    <xsl:template match="node
            [not(@xpath = preceding-sibling::node/@xpath)]
            "
        mode="clean_node">
        <xsl:if test="*">
            <xsl:copy-of select="." />
        </xsl:if>
    </xsl:template>

    <!-- ==============================================================
    Templates to process predicates.
    =============================================================== -->

    <!-- Filter a node with one or multiple predicates. -->
    <xsl:template name="filter-sequence">
        <xsl:param name="filter" />
        <xsl:param name="sequence" select="." />

        <xsl:variable name="n_filter"
            select="normalize-space($filter)" />

            <xsl:choose>
                <xsl:when test="string($n_filter) = ''">
                    <xsl:copy-of select="$sequence" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="result">
                        <xsl:call-template name="filter-sequence-recursive">
                            <!--
                            <xsl:with-param name="filters"
                                select="tokenize(
                                        normalize-space(substring(
                                            $n_filter, 2,
                                            string-length($n_filter) - 2)),
                                        '\]\s*\[')" />
                            -->
                            <xsl:with-param name="filters" select="$n_filter" />
                            <xsl:with-param name="sequence" select="$sequence" />
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:apply-templates select="$result/node" mode="clean_node" />
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>

    <xsl:template name="filter-sequence-recursive">
        <xsl:param name="filters" />
        <xsl:param name="sequence" select="." />

        <xsl:variable name="n_filters" select="normalize-space($filters)" />
        <xsl:variable name="x_filters"
            select="normalize-space(substring($n_filters, 2, string-length($n_filters) - 2))" />
        <xsl:variable name="first_filter">
            <xsl:choose>
                <xsl:when test="contains($x_filters, ']')">
                    <xsl:value-of select="normalize-space(substring-before($x_filters, ']'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$x_filters" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="next_filters">
            <xsl:choose>
                <xsl:when test="contains($x_filters, ']')">
                    <xsl:value-of select="normalize-space(substring-after($n_filters, ']'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="next_sequence">
            <xsl:call-template name="filter-sequence-process">
                <xsl:with-param name="filter" select="$first_filter" />
                <xsl:with-param name="sequence" select="$sequence" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($next_filters) = ''">
                <xsl:copy-of select="$next_sequence" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="filter-sequence-recursive">
                    <xsl:with-param name="filters" select="$next_filters" />
                    <xsl:with-param name="sequence" select="$next_sequence" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Process one filter on a node. -->
    <xsl:template name="filter-sequence-process">
        <xsl:param name="filter" />
        <xsl:param name="sequence" select="." />

        <xsl:choose>
            <xsl:when test="string($filter) = ''">
            </xsl:when>

            <!--
            <xsl:when test="$filter castable as xs:integer">
            -->
            <xsl:when test="number($filter) = number($filter)">
                <xsl:copy-of select="$sequence/node[position() = number($filter)]" />
            </xsl:when>

            <xsl:when test="starts-with($filter, 'position()')
                    and number(substring-after($filter, '=')) = number(substring-after($filter, '='))">
                <xsl:copy-of select="$sequence/node[position() = number(substring-after($filter, '='))]" />
            </xsl:when>

            <xsl:when test="$filter = 'last()'">
                <xsl:copy-of select="$sequence/node[last()]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'name()') or starts-with($filter, 'name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value">
                    <!--
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                    -->
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="substring-after($filter, '=')" />
                        <xsl:with-param name="node" select="$sequence" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$sequence/node[name(node()) = $value]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'local-name()') or starts-with($filter, 'local-name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value">
                    <!--
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                    -->
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="substring-after($filter, '=')" />
                        <xsl:with-param name="node" select="$sequence" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$sequence/node[local-name(node()) = $value]" />
            </xsl:when>

            <xsl:when test="not(contains($filter, '='))">
                <xsl:variable name="check_sequence">
                    <!--
                    select="dynx:get-node($filter, $node)" />
                    -->
                    <xsl:call-template name="get-sequence">
                        <xsl:with-param name="xpath" select="$filter" />
                        <xsl:with-param name="node" select="$sequence" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="$check_sequence">
                    <xsl:copy-of select="$sequence" />
                </xsl:if>
            </xsl:when>

            <!-- TODO The filter "Not equal" is not implemented yet. -->
            <xsl:when test="contains($filter, '!=')">
            </xsl:when>

            <xsl:when test="contains($filter, '=')">
                <xsl:variable name="expression"
                    select="normalize-space(substring-before($filter, '='))" />
                <xsl:variable name="value">
                    <!--
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                    -->
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="substring-after($filter, '=')" />
                        <xsl:with-param name="node" select="$sequence" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="check_sequence">
                    <!--
                    select="dynx:get-node($expression, $node)" />
                    -->
                    <xsl:call-template name="get-sequence">
                        <xsl:with-param name="xpath" select="$expression" />
                        <xsl:with-param name="node" select="$sequence" />
                    </xsl:call-template>
                </xsl:variable>
                <!-- TODO Check. -->
                <xsl:copy-of select="$check_sequence/node[node() = $value]" />
            </xsl:when>

            <xsl:otherwise>
                <!-- Never here. -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Helpers to process a function on a sequence (final function extended to any part).
    =============================================================== -->

    <!-- Process default functions. -->
    <xsl:template name="get-sequence-function">
        <xsl:param name="function" />
        <xsl:param name="arguments" select="''" />
        <xsl:param name="sequence" select="." />

        <xsl:variable name="func" select="normalize-space($function)" />

        <xsl:variable name="result">
            <xsl:for-each select="$sequence/node">
                <node xpath="{@xpath}">
                    <xsl:call-template name="get-node-function">
                        <xsl:with-param name="function" select="$func" />
                        <xsl:with-param name="arguments" select="$arguments" />
                        <xsl:with-param name="node" select="child::node()" />
                    </xsl:call-template>
                </node>
            </xsl:for-each>
        </xsl:variable>

        <xsl:apply-templates select="$result/node" mode="clean_node" />
    </xsl:template>

    <!-- ==============================================================
    Helpers to get the unique path of a node.
    =============================================================== -->

    <!-- Return the simplest unique xpath of a node of a sequence. -->
    <xsl:template name="get-unique-xpath-for-node">
        <xsl:param name="node" select="." />
        <xsl:param name="previous_xpath" select="''" />
        <xsl:param name="attribute" select="''" />

        <xsl:variable name="xpath_base">
            <xsl:call-template name ="get-unique-xpath">
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="xpath">
            <xsl:choose>
                <xsl:when test="string($attribute) != ''">
                    <xsl:value-of select="concat($xpath_base, '/@', $attribute)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$xpath_base" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="unique">
            <xsl:choose>
                <xsl:when test="starts-with($xpath, '/node')">
                    <xsl:value-of select="concat('/', substring-after(substring-after($xpath, '/node'), '/'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$xpath" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="unique_except_first">
            <xsl:call-template name="get-next-part-of-xpath">
                <xsl:with-param name="xpath" select="$unique" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="result">
            <xsl:value-of select="$previous_xpath" />
            <xsl:choose>
                <xsl:when test="string($previous_xpath) = '' or string($unique_except_first) = ''">
                    <xsl:value-of select="$unique" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$unique_except_first" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="$result" />
    </xsl:template>

    <!-- Return the simplest unique xpath of a node. -->
    <!-- TODO This is a duplicate of "get-absolute-xpath". -->
    <xsl:template name="get-unique-xpath">
        <xsl:param name="node" select="." />

        <xsl:choose>
            <xsl:when test="count($node/ancestor-or-self::*) = 0">
                   <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="result">
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
                </xsl:variable>
                <xsl:value-of select="$result" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Recursive helper used to get the last part of an xpath. -->
    <!-- This helper is used to get the parent of a node with an xpath. -->
    <xsl:template name="get-last-part-of-xpath">
        <xsl:param name="xpath" />


        <xsl:variable name="next_part">
            <xsl:call-template name="get-next-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($next_part) = ''">
                <xsl:value-of select="$xpath" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="get-last-part-of-xpath">
                    <xsl:with-param name="xpath" select="$next_part" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Recursive helper used to remove the last part of an xpath. -->
    <!-- This helper is used to get the parent of a node with an xpath. -->
    <xsl:template name="remove-last-part-of-xpath">
        <xsl:param name="xpath" />

        <xsl:variable name="next_part">
            <xsl:call-template name="get-next-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="string($next_part) != ''">
            <xsl:call-template name="get-first-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
            <xsl:call-template name="remove-last-part-of-xpath">
                <xsl:with-param name="xpath" select="$next_part" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- ==============================================================
    Helpers to get the unique path of a node for each axis.
    =============================================================== -->

    <xsl:template name="xpaths-check-last-and-add">
        <xsl:param name="xpath" select="''" />
        <xsl:param name="element" select="''" />

        <xsl:variable name="path">
            <xsl:call-template name="xpaths-check-last-element">
                <xsl:with-param name="xpath" select="$xpath" />
                <xsl:with-param name="element" select="$element" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="string($path) != ''">
            <xpath>
                <xsl:value-of select="$xpath" />
            </xpath>
        </xsl:if>
    </xsl:template>

    <!-- TODO <Horizontal axis. -->

    <!-- Vertical axis. -->

    <!-- Helper to get xpaths "ancestor" (and ancestor part of "ancestor-or-self"). -->
    <xsl:template match="node/@xpath" mode="xpaths_ancestor">
        <xsl:param name="element" select="''" />
        <xpath>
            <xsl:call-template name="get-xpath-ancestor">
                <xsl:with-param name="xpath" select="." />
                <xsl:with-param name="element" select="$element" />
            </xsl:call-template>
        </xpath>
    </xsl:template>

    <!-- Helper to get xpaths "parent". -->
    <xsl:template match="node/@xpath" mode="xpaths_parent">
        <xsl:param name="element" select="''" />

        <xsl:variable name="path">
            <xsl:call-template name="get-xpath-parent">
                <xsl:with-param name="xpath" select="." />
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="xpaths-check-last-and-add">
            <xsl:with-param name="xpath" select="$path" />
            <xsl:with-param name="element" select="$element" />
        </xsl:call-template>
    </xsl:template>

    <!-- Helper to get xpaths "self". -->
    <xsl:template match="node/@xpath" mode="xpaths_self">
        <xsl:param name="element" select="''" />

        <xsl:call-template name="xpaths-check-last-and-add">
            <xsl:with-param name="xpath" select="." />
            <xsl:with-param name="element" select="$element" />
        </xsl:call-template>
    </xsl:template>

    <!-- Helper to get xpaths "parent" (union). -->
    <xsl:template match="node/@xpath" mode="xpaths_parent_union">
        <xsl:param name="element" select="''" />

        <xsl:variable name="path">
            <xsl:call-template name="get-xpath-parent">
                <xsl:with-param name="xpath" select="." />
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="xpaths-check-last-union-and-add">
            <xsl:with-param name="xpath" select="$path" />
            <xsl:with-param name="elements" select="$element" />
        </xsl:call-template>
    </xsl:template>

    <!-- Helper to get xpaths "self" (union). -->
    <xsl:template match="node/@xpath" mode="xpaths_self_union">
        <xsl:param name="element" select="''" />

        <xsl:call-template name="xpaths-check-last-union-and-add">
            <xsl:with-param name="xpath" select="." />
            <xsl:with-param name="elements" select="$element" />
        </xsl:call-template>
    </xsl:template>

    <!-- Helper to check xpaths against a list of elements (union). -->
    <xsl:template name="xpaths-check-last-union-and-add">
        <xsl:param name="xpath" />
        <xsl:param name="elements" />

        <xsl:variable name="tokens">
            <xsl:call-template name="tokenize">
                <xsl:with-param name="string" select="normalize-space($elements)" />
                <xsl:with-param name="separator" select="'|'" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="$tokens/token">
            <xsl:call-template name="xpaths-check-last-and-add">
                <xsl:with-param name="xpath" select="$xpath" />
                <xsl:with-param name="element" select="." />
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- ==============================================================
    Sub helpers to get the unique path of a node for each axis.
    =============================================================== -->

    <!-- Recursive helper that returns the last ancestor of a node, so the
    closest one (the predicate is not checked). -->
    <xsl:template name="get-xpath-ancestor">
        <xsl:param name="xpath" />
        <xsl:param name="element" />

        <xsl:if test="string($element) = '' or contains($xpath, $element)
                or starts-with($element, '|')">
            <xsl:variable name="parent_expression">
                <xsl:call-template name="get-last-part-of-xpath">
                    <xsl:with-param name="xpath" select="$xpath" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:choose>
                <xsl:when test="string($parent_expression) = '' or string($parent_expression) = '/'">
                    <xsl:text></xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="parent_xpath">
                        <xsl:call-template name="remove-last-part-of-xpath">
                            <xsl:with-param name="xpath" select="$xpath" />
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
                        <xsl:when test="string($element) = ''">
                            <xsl:value-of select="$parent_xpath" />
                            <xsl:value-of select="$parent_expression" />
                        </xsl:when>
                        <xsl:when test="$element = $parent_element">
                            <xsl:value-of select="$parent_xpath" />
                            <xsl:value-of select="$parent_expression" />
                        </xsl:when>
                        <xsl:when test="starts-with($element, '|')
                                and contains($element, concat('|', $parent_element, '|'))">
                            <xsl:value-of select="$parent_xpath" />
                            <xsl:value-of select="$parent_expression" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="get-xpath-ancestor">
                                <xsl:with-param name="xpath" select="$parent_xpath" />
                                <xsl:with-param name="element" select="$element" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- Helper to get the parent of a node. -->
    <xsl:template name="get-xpath-parent">
        <xsl:param name="xpath" />

        <xsl:call-template name="remove-last-part-of-xpath">
            <xsl:with-param name="xpath" select="$xpath" />
        </xsl:call-template>
    </xsl:template>

    <!-- Check the last part of an xpath against an element, if any. -->
    <xsl:template name="xpaths-check-last-element">
        <xsl:param name="xpath" select="''" />
        <xsl:param name="element" select="''" />

        <xsl:variable name="last_xpath">
            <xsl:call-template name="get-last-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="last_element">
            <xsl:choose>
                <xsl:when test="contains($last_xpath, '[')">
                    <xsl:value-of select="translate(substring-before($last_xpath, '['), '/', '')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="translate($last_xpath, '/', '')" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="string($element) = '' or string($element) = string($last_element)">
            <xsl:value-of select="$xpath" />
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
