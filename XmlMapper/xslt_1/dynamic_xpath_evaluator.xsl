<?xml version="1.0" encoding="UTF-8"?>
<!--
Dynamic xpath evaluator.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

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

<xsl:stylesheet version="1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xsl fn xs">

    <!-- Special dynamic xpath evaluator for xslt 1 to get sequences. -->
    <xsl:import href="dynamic_xpath_sequence.xsl" />

    <!-- ==============================================================
    Main templates to process each part of an xpath
    =============================================================== -->

    <!-- Recursive process each part of an xpath. -->
    <xsl:template name="get-node">
        <xsl:param name="xpath" />
        <xsl:param name="node" select="." />
        <xsl:param name="is_first" select="true()" />

        <xsl:variable name="path" select="normalize-space($xpath)" />

        <xsl:choose>
            <!-- Quick checks and shorts. -->
            <xsl:when test="string($path) = '' or not($node)">
            </xsl:when>

            <!-- This path is allowed only for the root. -->
            <xsl:when test="$is_first and $path = '/'">
                <xsl:copy-of select="$node" />
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

                <!-- Need to know if the first part is a function. Xsl allows
                one only as final part of xpath. -->
                <xsl:variable name="first_is_function">
                    <xsl:call-template name="is-function">
                        <xsl:with-param name="string" select="$first_xpath" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="true_node">
                    <xsl:choose>
                        <!-- TODO Check if "//". -->
                        <xsl:when test="$is_first and starts-with($first_xpath, '/')">
                            <xsl:copy-of select="$node" />
                        </xsl:when>
                        <xsl:when test="starts-with($first_xpath, '@') or starts-with($first_xpath, '/@')
                                or starts-with($first_xpath, 'attribute::') or starts-with($first_xpath, '/attribute::')">
                            <xsl:copy-of select="$node" />
                        </xsl:when>
                        <xsl:when test="starts-with($first_xpath, 'namespace::') or starts-with($first_xpath, '/namespace::')">
                            <xsl:copy-of select="$node" />
                        </xsl:when>
                        <xsl:when test="starts-with($first_xpath, 'self::') or starts-with($first_xpath, '/self::')
                                or (starts-with($first_xpath, '.') and not(starts-with($first_xpath, '..')))
                                ">
                            <xsl:copy-of select="$node" />
                        </xsl:when>
                        <xsl:when test="string($first_is_function) = 'true'">
                            <xsl:copy-of select="$node" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$node/node()/node()" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="current_node">
                    <xsl:call-template name="get-current-node">
                        <xsl:with-param name="xpath" select="$first_xpath" />
                        <xsl:with-param name="node" select="$true_node" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <!-- Empty current node is checked via recursion. -->
                    <xsl:when test="string($next_xpath) = ''">
                        <xsl:copy-of select="$current_node" />
                    </xsl:when>
                    <xsl:when test="$next_xpath = '/'">
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-node">
                            <xsl:with-param name="xpath" select="$next_xpath" />
                            <xsl:with-param name="node" select="$current_node" />
                            <xsl:with-param name="is_first" select="false()" />
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
        <xsl:param name="xpath" />
        <xsl:param name="node" select="." />

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

                        <xsl:variable name="result_node">
                            <!--
                            select="dynx:get-node-simple($expression, $node)" />
                            -->
                            <xsl:call-template name="get-node-simple">
                                <xsl:with-param name="xpath" select="$expression" />
                                <xsl:with-param name="node" select="$node" />
                            </xsl:call-template>
                        </xsl:variable>

                        <!--
                        <xsl:sequence select="dynx:filter-node($filters, $result_node)" />
                        -->
                        <xsl:call-template name="filter-node">
                            <xsl:with-param name="filter" select="$filters" />
                            <xsl:with-param name="node" select="$result_node" />
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
    <xsl:template name="get-node-simple">
        <xsl:param name="xpath" />
        <xsl:param name="node" select="." />

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
                        then 'node()'
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
            <xsl:when test="string($path) = '' or not($node)
                    or string($axis) = '' or string($element) = ''">
            </xsl:when>

            <!-- "/" is not allowed for next path (only for root). -->
            <xsl:when test="$n_path = '/' or $path = '/'">
            </xsl:when>

            <xsl:when test="$path = '..'">
                <xsl:copy-of select="$node/.." />
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
                <xsl:copy-of select="$node" />
            </xsl:when>

            <xsl:when test="string($axis) != '' and string($element) != ''">
                <xsl:choose>
                    <xsl:when test="$element = '*'">
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:copy-of select="$node/child::*" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:for-each select="$node/node()
                                        /attribute::*">
                                    <node name="@{local-name()}">
                                        <xsl:value-of select="." />
                                    </node>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:copy-of select="$node/following::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:copy-of select="$node/following-sibling::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:copy-of select="$node/preceding::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:copy-of select="$node/preceding-sibling::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:copy-of select="$node/namespace::*" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:copy-of select="$node/ancestor::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:copy-of select="$node/ancestor-or-self::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:copy-of select="$node/descendant::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of select="$node/descendant-or-self::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:copy-of select="$node/parent::*" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of select="$node/node()/self::*" />
                            </xsl:when>
                            <!-- TODO Warn an error. -->
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- Manage union. -->
                    <xsl:when test="contains($element, '|')">
                        <xsl:variable name="elements"
                            select="concat('|', translate($element, ' ', ''), '|')" />
                        <xsl:choose>
                            <!-- Child is the default vertical axis. -->
                            <xsl:when test="$axis = 'child'">
                                <xsl:copy-of select="$node/child::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:for-each select="$node/node()/attribute::*
                                        [contains($elements, concat('|', local-name(), '|'))]">
                                    <node name="@{local-name()}">
                                        <xsl:value-of select="." />
                                    </node>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:copy-of select="$node/following::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:copy-of select="$node/following-sibling::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:copy-of select="$node/preceding::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:copy-of select="$node/preceding-sibling::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:copy-of select="$node/namespace::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:copy-of select="$node/ancestor::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:copy-of select="$node/ancestor-or-self::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:copy-of select="$node/descendant::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of select="$node/descendant-or-self::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:copy-of select="$node/parent::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of select="$node/node()/self::*
                                        [contains($elements, concat('|', local-name(), '|'))]" />
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
                                <xsl:copy-of select="$node/child::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <!-- Horizontal axis. -->
                            <xsl:when test="$axis = 'attribute'">
                                <xsl:for-each select="$node/node()
                                        /attribute::*[local-name() = $element]">
                                    <node name="@{local-name()}">
                                        <xsl:value-of select="." />
                                    </node>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="$axis = 'following'">
                                <xsl:copy-of select="$node/following::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'following-sibling'">
                                <xsl:copy-of select="$node/following-sibling::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding'">
                                <xsl:copy-of select="$node/preceding::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'preceding-sibling'">
                                <xsl:copy-of select="$node/preceding-sibling::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'namespace'">
                                <xsl:copy-of select="$node/namespace::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <!-- Vertical axis. -->
                            <xsl:when test="$axis = 'ancestor'">
                                <xsl:copy-of select="$node/ancestor::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'ancestor-or-self'">
                                <xsl:copy-of select="$node/ancestor-or-self::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant'">
                                <xsl:copy-of select="$node/descendant::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'descendant-or-self'">
                                <xsl:copy-of select="$node/descendant-or-self::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'parent'">
                                <xsl:copy-of select="$node/parent::*
                                        [local-name() = $element]" />
                            </xsl:when>
                            <xsl:when test="$axis = 'self'">
                                <xsl:copy-of select="$node/node()/self::*
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
        <xsl:param name="filter" />
        <xsl:param name="node" select="." />
        <xsl:param name="testf" />
        <xsl:param name="testf2" />

        <xsl:variable name="n_filter"
            select="normalize-space($filter)" />

        <xsl:choose>
            <xsl:when test="string($n_filter) = '' or string($filter) = ''">
                <xsl:copy-of select="$node" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="filter-node-recursive">
                    <!--
                    <xsl:with-param name="filters"
                        select="tokenize(
                                normalize-space(substring(
                                    $n_filter, 2,
                                    string-length($n_filter) - 2)),
                                '\]\s*\[')" />
                    -->
                    <xsl:with-param name="filters" select="$n_filter" />
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="filter-node-recursive">
        <xsl:param name="filters" />
        <xsl:param name="node" select="." />

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

        <xsl:variable name="next_node">
            <xsl:call-template name="filter-node-process">
                <xsl:with-param name="filter" select="$first_filter" />
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($next_filters) = ''">
                <xsl:copy-of select="$next_node" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="filter-node-recursive">
                    <xsl:with-param name="filters" select="$next_filters" />
                    <xsl:with-param name="node" select="$next_node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Process one filter on a node. -->
    <xsl:template name="filter-node-process">
        <xsl:param name="filter" />
        <xsl:param name="node" select="." />

        <xsl:choose>
            <xsl:when test="string($filter) = ''">
            </xsl:when>

            <!--
            <xsl:when test="$filter castable as xs:integer">
            -->
            <xsl:when test="number($filter) = number($filter)">
                <xsl:copy-of select="$node[position() = number($filter)]" />
            </xsl:when>

            <xsl:when test="starts-with($filter, 'position()')
                    and number(substring-after($filter, '=')) = number(substring-after($filter, '='))">
                <xsl:copy-of select="$node[position() = number(substring-after($filter, '='))]" />
            </xsl:when>

            <xsl:when test="$filter = 'last()'">
                <xsl:copy-of select="$node[last()]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'name()') or starts-with($filter, 'name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value">
                    <!--
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                    -->
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="substring-after($filter, '=')" />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$node[name(node()) = $value]" />
            </xsl:when>

            <xsl:when test="(starts-with($filter, 'local-name()') or starts-with($filter, 'local-name(.)'))
                    and contains($filter, '=')">
                <xsl:variable name="value">
                    <!--
                    select="dynx:get-argument(substring-after($filter, '='), $node)" />
                    -->
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="substring-after($filter, '=')" />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$node[local-name(node()) = $value]" />
            </xsl:when>

            <xsl:when test="not(contains($filter, '='))">
                <xsl:variable name="check_node">
                    <!--
                    select="dynx:get-node($filter, $node)" />
                    -->
                    <xsl:call-template name="get-node">
                        <xsl:with-param name="xpath" select="$filter" />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="$check_node">
                    <xsl:copy-of select="$node" />
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
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="check_node">
                    <!--
                    select="dynx:get-node($expression, $node)" />
                    -->
                    <xsl:call-template name="get-node">
                        <xsl:with-param name="xpath" select="$expression" />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$check_node[. = $value]/.." />
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
        <xsl:param name="function" />
        <xsl:param name="arguments" select="''" />
        <xsl:param name="node" select="." />

        <xsl:variable name="func" select="normalize-space($function)" />

        <xsl:variable name="args">
            <xsl:call-template name="get-node-function-arguments">
                <xsl:with-param name="arguments" select="normalize-space($arguments)" />
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($func) = ''">
            </xsl:when>
            <xsl:when test="$func = 'text'">
                <xsl:copy-of select="$node/text()" />
            </xsl:when>
            <xsl:when test="$func = 'comment'">
                <xsl:copy-of select="$node/comment()" />
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
        <xsl:param name="arguments" />
        <xsl:param name="node" select="." />

        <xsl:variable name="tokens">
            <xsl:call-template name="tokenize">
                <xsl:with-param name="string" select="normalize-space($arguments)" />
                <xsl:with-param name="separator" select="','" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="args">
            <!--
            <xsl:for-each select="tokenize(normalize-space($arguments), ',')">
                <xsl:copy-of select="dynx:get-argument(., $node)" />
            </xsl:for-each>
            -->
            <xsl:for-each select="$tokens/token">
                <argument>
                    <xsl:call-template name="get-argument">
                        <xsl:with-param name="argument" select="." />
                        <xsl:with-param name="node" select="$node" />
                    </xsl:call-template>
                </argument>
            </xsl:for-each>
        </xsl:variable>

        <xsl:copy-of select="$args" />
    </xsl:template>

    <!-- ==============================================================
    Internal Helpers.
    =============================================================== -->

    <!-- Get the first part of an xpath. It can start with "/", "//" or a letter. -->
    <xsl:template name="get-first-part-of-xpath">
        <xsl:param name="xpath" />

        <xsl:variable name="n_path" select="normalize-space($xpath)" />

        <xsl:choose>
            <!-- Quick checks. -->
            <xsl:when test="string($n_path) = ''">
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
                <!--
                <xsl:variable name="r_path">
                    <xsl:analyze-string select="$xpath" regex = "(\[.*?\]|\(.*?\))">
                        <xsl:matching-substring >
                            <xsl:value-of select="replace(regex-group(1), '[/|\[|\]\(|\)]', '-')" />
                        </xsl:matching-substring>
                        <xsl:non-matching-substring >
                            <xsl:value-of select="." />
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>

                <xsl:variable name="path" select="string-join($r_path, '')" />
                -->
                <xsl:variable name="path">
                    <xsl:call-template name="replace-slash-inside">
                        <xsl:with-param name="string" select="$xpath" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="m_path" select="normalize-space($path)" />
                <xsl:variable name="result">
                    <!--
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
                    -->
                    <xsl:choose>
                        <xsl:when test="contains($path, '/')">
                            <xsl:choose>
                                <xsl:when test="starts-with($m_path, '//')">
                                    <xsl:choose>
                                        <xsl:when test="contains(substring-after($path, '//'), '/')">
                                            <xsl:value-of select="concat('//', substring-before(substring-after($n_path, '//'), '/'))" />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$n_path" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <xsl:when test="starts-with($m_path, '/')">
                                            <xsl:choose>
                                                <xsl:when test="contains(substring-after($path, '/'), '/')">
                                                    <xsl:value-of select="concat('/', substring-before(substring-after($n_path, '/'), '/'))" />
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$n_path" />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="substring-before($n_path, '/')" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$n_path" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!--
                <xsl:value-of select="
                        if (normalize-space($result))
                        then normalize-space($result)
                        else $n_path" />
                -->
                <xsl:choose>
                    <xsl:when test="normalize-space($result)">
                        <xsl:value-of select="normalize-space($result)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$n_path" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Get next part of an xpath. -->
    <xsl:template name="get-next-part-of-xpath">
        <xsl:param name="xpath" />

        <xsl:variable name="first_part">
            <!--
            select="dynx:get-first-part-of-xpath($xpath)" />
            -->
            <xsl:call-template name="get-first-part-of-xpath">
                <xsl:with-param name="xpath" select="$xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($xpath) = '' or string($first_part) = '' or string($xpath) = string($first_part)">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring($xpath, string-length($first_part) + 1)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="is-function">
        <xsl:param name="string" />

        <xsl:variable name="first_parenthesis">
            <!--
                if (contains($string, '('))
                then string-length(substring-before($string, '(')) + 1
                else 0" />
            -->
            <xsl:choose>
                <xsl:when test="contains($string, '(')">
                    <xsl:value-of select="string-length(substring-before($string, '(')) + 1" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="first_bracket">
            <!--
                if (contains($string, '['))
                then string-length(substring-before($string, '[')) + 1
                else 0" />
            -->
            <xsl:choose>
                <xsl:when test="contains($string, '[')">
                    <xsl:value-of select="string-length(substring-before($string, '[')) + 1" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="is_before_bracket">
            <xsl:choose>
                <xsl:when test="$first_bracket &gt; 0">
                    <xsl:value-of select="$first_parenthesis &lt; $first_bracket" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="true()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--
        <xsl:value-of select="
                $first_parenthesis &gt; 0
                and (
                    if ($first_bracket &gt; 0)
                    then $first_parenthesis &lt; $first_bracket
                    else true()
                ) " />
        -->
        <xsl:value-of select="$first_parenthesis &gt; 0 and $is_before_bracket = 'true'" />
    </xsl:template>

    <!-- ==============================================================
    Generic Helpers.
    =============================================================== -->

    <!-- "substring-before-last" may be not supported. -->
    <xsl:template name="substring-before-last">
        <xsl:param name="string" />
        <xsl:param name="substring" />

        <xsl:if test="contains($string, $substring)">
            <xsl:value-of select="substring-before($string, $substring)" />

            <xsl:if test="contains(substring-after($string, $substring), $substring)">
                <xsl:value-of select="$substring" />
            </xsl:if>

            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="string" select="substring-after($string, $substring)" />
                <xsl:with-param name="substring" select="$substring" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- "substring-after-last" may be not supported. -->
    <xsl:template name="substring-after-last">
        <xsl:param name="string" />
        <xsl:param name="substring" />

        <xsl:choose>
            <xsl:when test="contains($string, $substring)">
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="string" select="substring-after($string, $substring)" />
                    <xsl:with-param name="substring" select="$substring" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Position of a character or a substring in a string. -->
    <xsl:template name="index-of-substring">
        <xsl:param name="string" />
        <xsl:param name="substring" />

        <xsl:choose>
            <xsl:when test="string($string) != '' and contains($string, $substring)">
                <xsl:value-of select="string-length(substring-before($string, $substring)) + 1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Position of last character or substring in a string. -->
    <xsl:template name="index-of-last-substring">
        <xsl:param name="string" />
        <xsl:param name="substring" />

        <xsl:choose>
            <xsl:when test="string($string) != '' and contains($string, $substring)">
                <xsl:variable name="before_last">
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="string" select="$string" />
                        <xsl:with-param name="substring" select="$substring" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="string-length($before_last) + 1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Convert a value in an expression into a regular value (number or string). -->
    <xsl:template name="get-argument">
        <xsl:param name="argument" />
        <xsl:param name="node" />

        <xsl:variable name="arg" select="normalize-space($argument)" />

        <xsl:choose>
            <xsl:when test="string($arg) = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:when test="$arg = '.'">
                <xsl:copy-of select="$node" />
            </xsl:when>
            <!-- TODO To manage "current()" requires the good context. -->
            <!--
            <xsl:when test="$arg = 'current()'">
                <xsl:copy-of select="current()" />
            </xsl:when>
            -->
            <xsl:when test="$arg = 'text()'">
                <xsl:copy-of select="$node/text()" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="apos"><xsl:text>'</xsl:text></xsl:variable>
                <xsl:variable name="quote"><xsl:text>"</xsl:text></xsl:variable>

                <xsl:choose>
                    <!-- TODO Manage escaped quote and double quote. -->
                    <xsl:when test="starts-with($arg, $apos)">
                        <xsl:value-of select="substring($arg, 2, string-length($arg) - 2)" />
                    </xsl:when>
                    <xsl:when test="starts-with($arg, $quote)">
                        <xsl:value-of select="substring($arg, 2, string-length($arg) - 2)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-node">
                            <xsl:with-param name="xpath" select="$arg" />
                            <xsl:with-param name="node" select="$node" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ==============================================================
    Helpers for additional templates and functions.
    =============================================================== -->

    <!-- This template may be overridden if needed. -->
    <xsl:template name="get-node-extra-function">
        <xsl:param name="function" />
        <xsl:param name="arguments" />
    </xsl:template>

    <!-- ==============================================================
    Templates for xslt 1.
    =============================================================== -->

    <!-- Replace "/" by '-' inside twins brackets and parenthesis (not nested). -->
    <xsl:template name="replace-slash-inside">
        <xsl:param name="string" select="." />

        <xsl:variable name="inside_bracket">
            <xsl:call-template name="replace-between">
                <xsl:with-param name="string" select="$string" />
                <xsl:with-param name="char" select="'/'" />
                <xsl:with-param name="by" select="'-'" />
                <xsl:with-param name="start" select="'['" />
                <xsl:with-param name="end" select="']'" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="replace-between">
            <xsl:with-param name="string" select="$inside_bracket" />
            <xsl:with-param name="char" select="'/'" />
            <xsl:with-param name="by" select="'-'" />
            <xsl:with-param name="start" select="'('" />
            <xsl:with-param name="end" select="')'" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="replace-between">
        <xsl:param name="string" select="." />
        <xsl:param name="char" select="''" />
        <xsl:param name="by" select="''" />
        <xsl:param name="start" select="''" />
        <xsl:param name="end" select="''" />

        <xsl:choose>
            <xsl:when test="string($string) = '' or string($char) = '' or string($start) = '' or string($end) = ''">
                <xsl:value-of select="$string" />
            </xsl:when>
            <xsl:when test="not(contains($string, $char)) or not(contains($string, $start)) or not(contains($string, $end))">
                <xsl:value-of select="$string" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="result">
                    <xsl:value-of select="substring-before($string, $start)" />
                    <xsl:value-of select="$start" />
                    <xsl:value-of select="translate(substring-before(substring-after($string, $start), $end), $char, $by)" />
                    <xsl:value-of select="$end" />
                    <xsl:call-template name="replace-between">
                        <xsl:with-param name="string" select="substring-after($string, $end)" />
                        <xsl:with-param name="char" select="$char" />
                        <xsl:with-param name="by" select="$by" />
                        <xsl:with-param name="start" select="$start" />
                        <xsl:with-param name="end" select="$end" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$result" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Tokenize without exslt. -->
    <xsl:template name="tokenize">
        <xsl:param name="string" select="." />
        <xsl:param name="separator" select="''" />

        <xsl:choose>
            <xsl:when test="$string and $separator and contains($string, $separator)">
                <token>
                    <xsl:value-of select="substring-before($string,$separator)" />
                </token>
                <xsl:call-template name="tokenize">
                    <xsl:with-param name="string" select="substring-after($string, $separator)" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <token>
                    <xsl:value-of select="$string" />
                </token>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
