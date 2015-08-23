<?xml version="1.0" encoding="UTF-8"?>
<!--
Dynamic xpath evaluator.

This version uses xslt version 2.0.

Only basic xpaths, those used in a mapper, are available: axis, elements, with
or without prefix, unique or multiple, with a possible last attribute, with
original attributes if wanted).

The exslt function "dyn:evaluate" is not used, because it is not implemented
by all parsers. Wait for xslt 3.

Because the resulting value may be a node or a simple text, next use of the
result may need to be processed as a whole.

This dynamic xpath evaluator is simple, because it's designed for a mapper,
that uses only simple mapping xpaths between a source and a destination.

Notes
- Currently, all paths are considered as relative to the specified node.
- The operator union ("|") is managed simpler, but in a non-standard way:
  elements are relative to the previous part, not to the context.

TODO
- Manage not equal filter (exemple: [element != 'value'])
- Fix the management of relative / absolute paths ("dao" is not "/dao").
- Predicates should be managed before axis (greater priority).
- Separate extraction of elements and arguments and process.
- Use regex to extract expressions, elements, axis, predicates, values... (xslt 2)
- Functions inside function (xslt 2).

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:dynx="http://dynx"

    exclude-result-prefixes="xsl fn xs dynx">

    <!-- Allows to use the simple dynamic xpath evaluator via a function. -->
    <xsl:function name="dynx:get-node" as="item()*">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:call-template name="get-node">
            <xsl:with-param name="xpath" select="$xpath" />
            <xsl:with-param name="node" select="$node" />
        </xsl:call-template>
    </xsl:function>

    <!-- Allows to process evaluation of a single simple expression via a function. -->
    <xsl:function name="dynx:get-node-simple" as="item()*">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:call-template name="get-node-simple">
            <xsl:with-param name="xpath" select="$xpath" />
            <xsl:with-param name="node" select="$node" />
        </xsl:call-template>
    </xsl:function>

    <!-- Allows to filter a node with one or multiple simple predicates via a function. -->
    <xsl:function name="dynx:filter-node" as="item()*">
        <xsl:param name="filter" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:call-template name="filter-node">
            <xsl:with-param name="filter" select="$filter" />
            <xsl:with-param name="node" select="$node" />
        </xsl:call-template>
    </xsl:function>

    <!-- Get first part of an xpath (with initial "/" if absent). -->
    <xsl:function name="dynx:get-first-part-of-xpath" as="xs:string?">
        <xsl:param name="xpath" as="xs:string?" />

        <xsl:call-template name="get-first-part-of-xpath">
            <xsl:with-param name="xpath" select="$xpath" />
        </xsl:call-template>
    </xsl:function>

    <!-- Get next part of an xpath. -->
    <xsl:function name="dynx:get-next-part-of-xpath" as="xs:string?">
        <xsl:param name="xpath" as="xs:string?" />

        <xsl:call-template name="get-next-part-of-xpath">
            <xsl:with-param name="xpath" select="$xpath" />
        </xsl:call-template>
    </xsl:function>

    <!-- ==============================================================
    Main templates to process each part of an xpath
    =============================================================== -->

    <!-- Recursive process each part of an xpath. -->
    <xsl:template name="get-node">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:variable name="path" as="xs:string?" select="normalize-space($xpath)" />

        <xsl:choose>
            <!-- Quick checks and shorts. -->
            <xsl:when test="string($path) = '' or empty($node)">
            </xsl:when>

            <!-- This path is allowed only for the root. -->
            <xsl:when test="$path = '/'">
                <xsl:copy-of select="$node" />
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="first_xpath" as="xs:string?"
                    select="dynx:get-first-part-of-xpath($path)" />

                <xsl:variable name="next_xpath" as="xs:string?"
                    select="dynx:get-next-part-of-xpath($path)" />

                <xsl:variable name="current_node" as="item()*">
                    <xsl:call-template name="get-current-node">
                        <xsl:with-param name="xpath" select="$first_xpath" />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <!-- Empty current node is checked via recursion. -->
                    <xsl:when test="$next_xpath = '' or empty($next_xpath)">
                        <xsl:sequence select="$current_node" />
                    </xsl:when>
                    <xsl:when test="$next_xpath = '/'">
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-node">
                            <xsl:with-param name="xpath" select="$next_xpath" />
                            <xsl:with-param name="node" select="$current_node" />
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
    <xsl:template name="get-current-node">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <!-- Normalize the xpath: remove the first "/" except if "//". -->
        <xsl:variable name="n_path" as="xs:string?" select="normalize-space($xpath)" />
        <xsl:variable name="path" as="xs:string?" select="
                if (starts-with($n_path, '//'))
                then $n_path
                else if (starts-with($n_path, '/'))
                    then normalize-space(substring($n_path, 2))
                    else $n_path" />

        <xsl:choose>
            <xsl:when test="$path = ''">
            </xsl:when>

            <!-- Check if the path is a function. -->
            <xsl:when test="dynx:is-function($path)">
                <xsl:variable name="first_parenthesis" as="xs:integer*"
                    select="string-length(substring-before($path, '(')) + 1" />

                <xsl:call-template name="get-node-function">
                    <xsl:with-param name="function"
                        select="substring-before($path, '(')" />
                    <xsl:with-param name="arguments"
                        select="substring($path, $first_parenthesis + 1, string-length($path) - $first_parenthesis - 1)" />
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:when>

            <!-- Else this is a simple expression, with or without filters. -->
            <xsl:otherwise>
                <xsl:variable name="first_bracket" as="xs:integer*" select="
                        if (contains($path, '['))
                        then string-length(substring-before($path, '[')) + 1
                        else 0" />

                <xsl:variable name="expression" as="xs:string" select="
                        if ($first_bracket &gt; 0)
                        then normalize-space(substring($path, 1, $first_bracket - 1))
                        else $path" />

                <xsl:variable name="filters" as="xs:string?" select="
                        if ($first_bracket &gt; 0)
                        then substring($path, $first_bracket)
                        else ''" />

                <xsl:variable name="result_node" as="node()*"
                    select="dynx:get-node-simple($expression, $node)" />

                <xsl:sequence select="dynx:filter-node($filters, $result_node)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Template to process an axis.
    =============================================================== -->

    <!-- Process a single part of a xpath (the path should be checked: no
    function, no predicate). -->
    <xsl:template name="get-node-simple">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <!-- Simplify the xpath. -->
        <xsl:variable name="n_path" as="xs:string?" select="normalize-space($xpath)" />
        <xsl:variable name="path" as="xs:string?" select="
                if (starts-with($n_path, '//'))
                then normalize-space(substring($n_path, 3))
                else if (starts-with($n_path, '/'))
                    then normalize-space(substring($n_path, 2))
                    else $n_path" />

        <!-- Unions are currently not managed, except some basic ones. -->
        <xsl:variable name="axis" as="xs:string" select="
                if (contains($path, '::'))
                then normalize-space(substring-before($path, '::'))
                else if (starts-with($path, '@'))
                    then 'attribute'
                    else if ($path = '..')
                        then 'parent'
                        else 'child'" />

        <xsl:variable name="element" as="xs:string" select="
                if (contains($path, '::'))
                then normalize-space(substring-after($path, '::'))
                else if (starts-with($path, '@'))
                    then normalize-space(substring-after($path, '@'))
                    else if ($path = '..')
                        then 'node()'
                        else $path" />

        <xsl:choose>
            <!-- Quick checks and shorts. -->
            <xsl:when test="$path = '' or empty($path) or empty($node)
                    or $axis = '' or $element = ''">
            </xsl:when>

            <!-- "/" is not allowed for next path (only for root). -->
            <xsl:when test="$n_path = '/' or $path = '/'">
            </xsl:when>

            <xsl:when test="$path = '..'">
                <xsl:sequence select="$node/.." />
            </xsl:when>

            <!-- Recursive template for "//". -->
            <xsl:when test="starts-with($n_path, '//')">
                <xsl:call-template name="get-node-simple">
                    <xsl:with-param name="xpath" select="$path" />
                    <xsl:with-param name="node" select="$node
                            /descendant-or-self::node()" />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="$path = '.'">
                <xsl:sequence select="$node" />
            </xsl:when>

            <xsl:when test="$axis != '' and $element != ''">
                <xsl:choose>
                    <xsl:when test="$element = '*'">
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:sequence select="$node/child::*" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:sequence select="$node/attribute::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:sequence select="$node/following::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:sequence select="$node/following-sibling::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:sequence select="$node/preceding::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:sequence select="$node/preceding-sibling::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:sequence select="$node/namespace::*" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:sequence select="$node/ancestor::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:sequence select="$node/ancestor-or-self::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:sequence select="$node/descendant::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:sequence select="$node/descendant-or-self::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:sequence select="$node/parent::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:sequence select="$node/self::*" />
                            </xsl:when>
                            <!-- TODO Warn an error. -->
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- Manage union. -->
                    <xsl:when test="contains($element, '|')">
                        <xsl:variable name="elements"
                            select="tokenize($element, '\|')" />
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:sequence select="$node/child::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:sequence select="$node/attribute::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:sequence select="$node/following::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:sequence select="$node/following-sibling::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:sequence select="$node/preceding::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:sequence select="$node/preceding-sibling::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:sequence select="$node/namespace::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:sequence select="$node/ancestor::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:sequence select="$node/ancestor-or-self::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:sequence select="$node/descendant::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:sequence select="$node/descendant-or-self::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:sequence select="$node/parent::*
                                       [boolean(index-of($elements, local-name()))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:sequence select="$node/self::*
                                       [boolean(index-of($elements, local-name()))]" />
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
                                <xsl:sequence select="$node/child::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:sequence select="$node/attribute::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:sequence select="$node/following::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:sequence select="$node/following-sibling::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:sequence select="$node/preceding::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:sequence select="$node/preceding-sibling::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:sequence select="$node/namespace::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:sequence select="$node/ancestor::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:sequence select="$node/ancestor-or-self::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:sequence select="$node/descendant::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:sequence select="$node/descendant-or-self::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:sequence select="$node/parent::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:sequence select="$node/self::*
                                        [local-name() = $element]" />
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
    Templates to process predicates.
    =============================================================== -->

    <!-- Filter a node with one or multiple predicates. -->
    <xsl:template name="filter-node">
        <xsl:param name="filter" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:variable name="n_filter" as="xs:string?"
            select="normalize-space($filter)" />

        <xsl:choose>
            <xsl:when test="$n_filter = ''">
                <xsl:sequence select="$node" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="filter-node-recursive">
                    <xsl:with-param name="filters"
                        select="tokenize(
                                normalize-space(substring(
                                    $n_filter, 2,
                                    string-length($n_filter) - 2)),
                                '\]\s*\[')" />
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="filter-node-recursive">
        <xsl:param name="filters" as="xs:string*" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:variable name="next_node" as="node()*">
            <xsl:call-template name="filter-node-process">
                <xsl:with-param name="filter" select="normalize-space($filters[1])" />
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="count($filters) = 1">
                <xsl:sequence select="$next_node" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="filter-node-recursive">
                    <xsl:with-param name="filters" select="$filters[position() != 1]" />
                    <xsl:with-param name="node" select="$next_node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Process one filter on a node. -->
    <xsl:template name="filter-node-process">
        <xsl:param name="filter" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:choose>
            <xsl:when test="$filter = '' or empty($filter)">
            </xsl:when>

            <xsl:when test="$filter castable as xs:integer">
                <xsl:sequence select="$node[position() = number($filter)]" />
            </xsl:when>

            <xsl:when test="starts-with($filter, 'position()')
                    and substring-after($filter, '=') castable as xs:integer">
                <xsl:sequence select="$node[position() = number(substring-after($filter, '='))]" />
            </xsl:when>

            <xsl:when test="$filter = 'last()'">
                <xsl:sequence select="$node[last()]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'name()') or starts-with($filter, 'name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value" as="xs:string"
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                <xsl:sequence select="$node[name() = $value]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'local-name()') or starts-with($filter, 'local-name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value" as="xs:string"
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                <xsl:sequence select="$node[local-name() = $value]" />
            </xsl:when>

            <xsl:when test="not(contains($filter, '='))">
                <xsl:variable name="check_node" as="node()*"
                    select="dynx:get-node($filter, $node)" />
                <xsl:if test="not(empty($check_node))">
                    <xsl:sequence select="$node" />
                </xsl:if>
            </xsl:when>

            <!-- TODO The filter "Not equal" is not implemented yet. -->
            <xsl:when test="contains($filter, '!=')">
            </xsl:when>

            <xsl:when test="contains($filter, '=')">
                <xsl:variable name="expression"
                    select="normalize-space(substring-before($filter, '='))" />
                <xsl:variable name="value" as="xs:string"
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                <xsl:variable name="check_node" as="node()*"
                    select="dynx:get-node($expression, $node)" />
                <xsl:sequence select="$check_node[. = $value]/.." />
            </xsl:when>

            <xsl:otherwise>
                <!-- Never here. -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Helpers to process a function on a node (final function extended to any part).
    =============================================================== -->

    <!-- Process default functions. -->
    <xsl:template name="get-node-function">
        <xsl:param name="function" as="xs:string?" />
        <xsl:param name="arguments" as="xs:string*" select="''" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:variable name="func" as="xs:string" select="normalize-space($function)" />

        <xsl:variable name="args" as="item()*">
            <xsl:call-template name="get-node-function-arguments">
                <xsl:with-param name="arguments" select="normalize-space($arguments)" />
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$func = ''">
            </xsl:when>
            <xsl:when test="$func = 'text'">
                <xsl:sequence select="$node/text()" />
            </xsl:when>
            <xsl:when test="$func = 'comment'">
                <xsl:sequence select="$node/comment()" />
            </xsl:when>
            <xsl:when test="$func = 'document-uri'">
                <xsl:choose>
                    <xsl:when test="$arguments = '' or $arguments = '/'" >
                        <xsl:sequence select="document-uri($node)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- TODO document-uri() with an argument. -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="get-node-extra-function">
                    <xsl:with-param name="function" select="$func" />
                    <xsl:with-param name="arguments" select="$args" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Convert a string into a list of normalized arguments. -->
    <xsl:template name="get-node-function-arguments">
        <xsl:param name="arguments" as="xs:string?" />
        <xsl:param name="node" as="node()*" select="." />

        <xsl:variable name="args" as="item()*">
            <xsl:for-each select="tokenize(normalize-space($arguments), ',')">
                <xsl:sequence select="dynx:get-argument(., $node)" />
            </xsl:for-each>
        </xsl:variable>

        <xsl:sequence select="$args" />
    </xsl:template>

    <!-- ==============================================================
    Internal Helpers.
    =============================================================== -->

    <!-- Get the first part of an xpath. It can start with "/", "//" or a letter. -->
    <xsl:template name="get-first-part-of-xpath">
        <xsl:param name="xpath" as="xs:string?" />

        <xsl:variable name="n_path" as="xs:string?" select="normalize-space($xpath)" />

        <xsl:choose>
            <!-- Quick checks. -->
            <xsl:when test="$n_path = ''">
                <xsl:value-of select="$xpath" />
            </xsl:when>
            <xsl:when test="not(contains($n_path, '/'))">
                <xsl:value-of select="$xpath" />
            </xsl:when>
            <xsl:when test="$n_path = '/' or $n_path = '//'">
                <xsl:value-of select="$xpath" />
            </xsl:when>
            <!-- Complex xpath. -->
            <xsl:otherwise>
                <!-- Replace "/" by '-' inside twins brackets and parenthesis. -->
                <xsl:variable name="r_path" as="xs:string*">
                    <xsl:analyze-string select="$xpath" regex = "(\[.*?\]|\(.*?\))">
                        <xsl:matching-substring >
                            <xsl:value-of select="replace(regex-group(1), '[/|\[|\]\(|\)]', '-')" />
                        </xsl:matching-substring>
                        <xsl:non-matching-substring >
                            <xsl:value-of select="." />
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>

                <xsl:variable name="path" as="xs:string" select="string-join($r_path, '')" />
                <xsl:variable name="m_path" as="xs:string" select="normalize-space($path)" />
                <xsl:variable name="result" as="xs:string" select="
                        if (contains($path, '/'))
                        then if (starts-with($m_path, '//'))
                            then if (contains(substring-after($path, '//'), '/'))
                                then concat('//', substring-before(substring-after($n_path, '//'), '/'))
                                else $n_path
                            else if (starts-with($m_path, '/'))
                                then if (contains(substring-after($path, '/'), '/'))
                                    then concat('/', substring-before(substring-after($n_path, '/'), '/'))
                                    else $n_path
                                else substring-before($n_path, '/')
                        else $n_path" />

                <xsl:value-of select="
                        if (normalize-space($result))
                        then normalize-space($result)
                        else $n_path" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Get next part of an xpath. -->
    <xsl:template name="get-next-part-of-xpath">
        <xsl:param name="xpath" as="xs:string?" />

        <xsl:variable name="first_part" as="xs:string?"
            select="dynx:get-first-part-of-xpath($xpath)" />

        <xsl:choose>
            <xsl:when test="empty($xpath) or empty($first_part) or $xpath = $first_part">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring($xpath, string-length($first_part) + 1)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="dynx:is-function" as="xs:boolean">
        <xsl:param name="string" as="xs:string?" />

        <xsl:call-template name="is-function">
            <xsl:with-param name="string" select="$string" />
        </xsl:call-template>
    </xsl:function>

    <xsl:template name="is-function">
        <xsl:param name="string" as="xs:string?" />

        <!-- TODO Use regex. -->
        <xsl:variable name="first_parenthesis" as="xs:integer*" select="
                if (contains($string, '('))
                then string-length(substring-before($string, '(')) + 1
                else 0" />

        <xsl:variable name="first_bracket" as="xs:integer*" select="
                if (contains($string, '['))
                then string-length(substring-before($string, '[')) + 1
                else 0" />

        <xsl:value-of select="
                $first_parenthesis &gt; 0
                and (
                    if ($first_bracket &gt; 0)
                    then $first_parenthesis &lt; $first_bracket
                    else true()
                ) " />
    </xsl:template>

    <!-- ==============================================================
    Generic Helpers.
    =============================================================== -->

    <!-- "substring-before-last" may be not supported. -->
    <xsl:function name="dynx:substring-before-last" as="xs:string?">
        <xsl:param name="string" as="xs:string?" />
        <xsl:param name="substring" as="xs:string" />

        <xsl:choose>
            <xsl:when test="$string = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="token" as="xs:string" select="
                    if (contains('|[](){}.-+*?^$\', $substring))
                    then concat('\', $substring)
                    else $substring" />
                <xsl:value-of select="string-join(tokenize($string, $token)[position() &lt; last()], $substring)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- "substring-after-last" may be not supported. -->
    <xsl:function name="dynx:substring-after-last" as="xs:string?">
        <xsl:param name="string" as="xs:string?" />
        <xsl:param name="substring" as="xs:string" />

        <xsl:choose>
            <xsl:when test="$string = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="token" as="xs:string" select="
                    if (contains('|[](){}.-+*?^$\', $substring))
                    then concat('\', $substring)
                    else $substring" />
                <xsl:value-of select="tokenize($string, $token)[last()]" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Position of a character or a substring in a string. -->
    <xsl:function name="dynx:index-of-substring" as="xs:integer">
        <xsl:param name="string" as="xs:string?" />
        <xsl:param name="substring" as="xs:string" />

        <xsl:value-of select="
                if ($string != '' and contains($string, $substring))
                then string-length(substring-before($string, $substring)) + 1
                else 0" />
    </xsl:function>

    <!-- Position of last character or substring in a string. -->
    <xsl:function name="dynx:index-of-last-substring" as="xs:integer">
        <xsl:param name="string" as="xs:string?" />
        <xsl:param name="substring" as="xs:string" />

        <xsl:value-of select="
                if ($string != '' and contains($string, $substring))
                then string-length(dynx:substring-before-last($string, $substring)) + 1
                else 0" />
    </xsl:function>

    <!-- Convert a value in an expression into a regular value (number or string). -->
    <xsl:function name="dynx:get-argument" as="item()*">
        <xsl:param name="argument" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:variable name="arg" select="normalize-space($argument)" />

        <xsl:choose>
            <xsl:when test="$arg = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:when test="$arg = '.'">
                <xsl:sequence select="$node" />
            </xsl:when>
            <!-- TODO To manage "current()" requires the good context. -->
            <!--
            <xsl:when test="$arg = 'current()'">
                <xsl:sequence select="current()" />
            </xsl:when>
            -->
            <xsl:when test="$arg = 'text()'">
                <xsl:sequence select="$node/text()" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="apos" as="xs:string"><xsl:text>'</xsl:text></xsl:variable>
                <xsl:variable name="quote" as="xs:string"><xsl:text>"</xsl:text></xsl:variable>

                <xsl:choose>
                    <!-- TODO Manage escaped quote and double quote. -->
                    <xsl:when test="starts-with($arg, $apos)">
                        <xsl:value-of select="substring($arg, 2, string-length($arg) - 2)" />
                    </xsl:when>
                    <xsl:when test="starts-with($arg, $quote)">
                        <xsl:value-of select="substring($arg, 2, string-length($arg) - 2)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="dynx:get-node($arg, $node)" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- ==============================================================
    Helpers for additional templates and functions.
    =============================================================== -->

    <!-- This template may be overridden if needed. -->
    <xsl:template name="get-node-extra-function">
        <xsl:param name="function" as="xs:string" />
        <xsl:param name="arguments" as="item()*" />
    </xsl:template>

</xsl:stylesheet>
