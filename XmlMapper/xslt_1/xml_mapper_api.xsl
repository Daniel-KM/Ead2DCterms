<?xml version="1.0" encoding="UTF-8"?>
<!--
Map a file in a xml format into another one via a mapping schema.

This version uses xslt 1.1 + extension (downgrade of xslt 2, same structure).

See other notes inside xml_mapper.xsl.

Internal notes:
This mapper is built from practical true mappings used in libraries (EAD and
Dublin Core). Furthermore, it aims to be manageable by a non-specialist of xsl
and only by a table or the xml mapping file. So some features that may be
interesting in an ideal mapper are not implemented, because there are currently
useless.

TODO
- Add a unit test, not only official ones.
- Option for one or multiple outputs (xslt 2).
- Main prefix issue: use a default prefix, then change the output prefix?
- Add a dispatch mechanism (from one content to multiple elements)
- See notes about the dynamic xpath evaluator.
- Finalize inversion of templates (always match on source instead of mapping).
- Check deduplication with same values, but different tags.
- Convert "mapper:copy-except" into a standard identify template.

Notes
- Conditional result doesn't check the source, so each result condition applies to
all of identical elements.

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

    <!-- Import the generic helpers. -->
    <xsl:import href="xml_mapper_helpers.xsl" />

    <!-- Import dynamic xpath evaluator. -->
    <xsl:import href="dynamic_xpath_evaluator.xsl" />

    <!-- Parameters -->
    <xsl:param name="configuration" select="''" />

    <!-- Constants. -->
    <xsl:variable name="config" select="document($configuration)/config" />

    <xsl:variable name="mappings"
        select="document($config/option[@name = 'mappings']/@value)/mappings" />

    <!-- Variables used for partial processing. -->
    <xsl:variable name="unique_record" select="''" />
    <xsl:variable name="skip_mapping_types">
        <skip />
    </xsl:variable>

    <!-- The main xml source to process. -->
    <xsl:variable name="input" select="/" />

    <xsl:variable name="output_prefix">
        <xsl:choose>
            <xsl:when test="$config/option[@name = 'output_prefix']/@value = 'false'
                    or $mappings/to[1]/@prefix = ''
                    or $mappings/to[1]/@namespace = ''">
                <xsl:value-of select="''" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($mappings/to[1]/@prefix, ':')" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="base_id_config">
        <xsl:call-template name="get-node">
            <xsl:with-param name="xpath" select="$config/baseid/@from" />
            <xsl:with-param name="node" select="$input" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="base_id_mappings">
        <xsl:call-template name="get-node">
            <xsl:with-param name="xpath" select="$mappings/baseid/@from" />
            <xsl:with-param name="node" select="$input" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="base_id">
        <xsl:choose>
            <xsl:when test="normalize-space($base_id_config) != ''">
                <xsl:value-of select="normalize-space($base_id_config)" />
            </xsl:when>
            <xsl:when test="normalize-space($base_id_mappings) != ''">
                <xsl:value-of select="normalize-space($base_id_mappings)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$config/baseid/@default" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ==============================================================
    Main Templates
    =============================================================== -->

    <xsl:template match="/*" mode="mapper">
        <xsl:apply-templates select="$config
                /records[not(@process) or @process = 'true']"
            mode="process_records" />
    </xsl:template>

    <xsl:template match="config/records" mode="process_records">
        <!-- The root element and namespaces should be set in the main mapper. -->
        <!--
        <xsl:variable name="element" as="xs:string" select="
                if (@element != '')
                then @element
                else if ($config/option[@name = 'default_element_root']/@value != '')
                    then $config/option[@name = 'default_element_root']/@value
                    else 'records'" />
        -->
        <!--
        <xsl:variable name="element">
            <xsl:choose>
                <xsl:when test="@element != ''">
                    <xsl:value-of select="@element" />
                </xsl:when>
                <xsl:when test="$config/option[@name = 'default_element_root']/@value != ''">
                    <xsl:value-of select="$config/option[@name = 'default_element_root']/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>records</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:element name="{$element}">
            <xsl:for-each select="$mappings/to[@namespace != '']">
                <xsl:namespace name="{@prefix}" select="@namespace" />
            </xsl:for-each>
            <xsl:for-each select="$mappings/namespace[@namespace != '']">
                <xsl:namespace name="{@prefix}" select="@namespace" />
            </xsl:for-each>
            <xsl:for-each select="$config/namespace[@namespace != '']">
                <xsl:namespace name="{@prefix}" select="@namespace" />
            </xsl:for-each>
        -->

            <xsl:choose>
                <xsl:when test="$unique_record != ''">
                    <xsl:apply-templates select="record
                            [not(@process) or @process = 'true']
                            [@name = $unique_record]
                            [1]"
                        mode="process_record" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="record
                            [not(@process) or @process = 'true']"
                        mode="process_record" />
                </xsl:otherwise>
            </xsl:choose>

        <!--
        </xsl:element>
        -->
    </xsl:template>

    <xsl:template match="config/records/record" mode="process_record">
        <!--
        <xsl:variable name="main_mapping" as="element()"
            select="mapper:get-main-mapping-of-record(.)" />
        -->
        <xsl:variable name="main_mapping_position">
            <xsl:call-template name="get-position-of-main-mapping-of-record">
                <xsl:with-param name="record" select="." />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="main_mapping"
                select="use[position() = $main_mapping_position]" />

        <xsl:if test="$main_mapping/@mapping != ''">
            <xsl:apply-templates select="$mappings/mapping[@name = $main_mapping/@mapping]"
                mode="mapping">
                <xsl:with-param name="record" select="." />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- Process one mapping for one configured type of record:
    - create one or multiple records from the source, via this main mapping and
    all dependant ones;
    - process conditions on the resulting mapped records. -->
    <xsl:template match="mappings/mapping" mode="mapping">
        <xsl:param name="record" />

        <xsl:variable name="mapping" select="." />

        <xsl:variable name="element">
            <!--
                if ($record/@element != '')
                then $record/@element
                else if ($config/option[@name = 'default_element_record']/@value != '')
                    then $config/option[@name = 'default_element_record']/@value
                    else 'record'" />
            -->
            <xsl:choose>
                <xsl:when test="$record/@element != ''">
                    <xsl:value-of select="$record/@element" />
                </xsl:when>
                <xsl:when test="$config/option[@name = 'default_element_record']/@value != ''">
                    <xsl:value-of select="$config/option[@name = 'default_element_record']/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>record</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="records">
            <!--
            select="if (@root != '') then dynx:get-node(@root, $input) else $input" />
            -->
            <xsl:choose>
                <xsl:when test="@root != ''">
                    <xsl:call-template name="get-sequence">
                        <xsl:with-param name="xpath" select="@root" />
                        <xsl:with-param name="node" select="$input" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <node xpath="">
                        <xsl:copy-of select="$input" />
                    </node>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:for-each select="$records/node">
            <xsl:element name="{$element}">
                <xsl:if test="(not($record/../@record_name) or $record/../@record_name = 'true')
                    and $record/@name != ''">
                    <xsl:choose>
                        <xsl:when test="$record/@record_name_key != ''">
                            <xsl:attribute name="{$record/@record_name_key}">
                                <xsl:value-of select="$record/@name" />
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="$record/../@record_name_key != ''">
                            <xsl:attribute name="{$record/../@record_name_key}">
                                <xsl:value-of select="$record/@name" />
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="type">
                                <xsl:value-of select="$record/@name" />
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>

                <!-- First, do all of the mapping for the record. -->
                <xsl:variable name="mapped">
                    <xsl:apply-templates select="node()" mode="mapping_source">
                        <xsl:with-param name="record" select="$record" />
                        <xsl:with-param name="mapping" select="$mapping" />
                        <xsl:with-param name="source_xpath" select="@xpath" />
                    </xsl:apply-templates>
                </xsl:variable>

                <!-- Second, apply options on the resulting mapped record.-->
                <xsl:apply-templates select="$mapped" mode="mapping_result">
                    <xsl:with-param name="record" select="$record" />
                    <xsl:with-param name="mapping" select="$mapping" />
                </xsl:apply-templates>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <!-- ==============================================================
    Helpers to map one source into one mapped record via one mapping and sub-mappings.
    =============================================================== -->

    <!-- Process the base mapping. -->
    <xsl:template match="/|*" mode="mapping_source">
        <xsl:param name="record" />
        <xsl:param name="mapping" />
        <!-- This value is needed only to manage specific axis in xslt 1. -->
        <xsl:param name="source_xpath" select="''" />

        <xsl:variable name="source_base">
            <!--
            select="mapper:get-source($mapping/@base, .)" />
            -->
            <xsl:call-template name="get-source">
                <xsl:with-param name="xpath" select="$mapping/@base" />
                <xsl:with-param name="source" select="." />
                <xsl:with-param name="previous_xpath" select="$source_xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="name($source_base/node()[1]) != ''">
            <xsl:variable name="source_xpath_use_base">
                <xsl:call-template name="combine-xpaths">
                    <xsl:with-param name="previous_xpath" select="$source_xpath" />
                    <xsl:with-param name="xpath" select="$mapping/@base" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:apply-templates select="$mapping/map[not(@type) or @type = 'simple']" mode="simple">
                <xsl:with-param name="source" select="$source_base" />
                <xsl:with-param name="source_xpath" select="$source_xpath_use_base" />
            </xsl:apply-templates>

            <xsl:apply-templates select="$mapping/map[@type = 'concatenation']" mode="concatenation">
                <xsl:with-param name="source" select="$source_base" />
                <xsl:with-param name="source_xpath" select="$source_xpath_use_base" />
            </xsl:apply-templates>
        </xsl:if>

        <xsl:variable name="source_current" select="." />

        <!-- Process mappings included in the main mapping. -->
        <xsl:for-each select="$mapping/use">
            <xsl:variable name="use_mapping"
                select="$mappings/mapping
                        [@name = current()/@mapping]
                        [not(@type) or not(@type = $skip_mapping_types/skip/@type)]
                    " />

            <xsl:if test="$use_mapping">
                <!--
                <xsl:apply-templates select="mapper:get-source(@node, $source_current)"
                -->
                <xsl:variable name="source_use">
                    <xsl:call-template name="get-source">
                        <xsl:with-param name="xpath" select="@node" />
                        <xsl:with-param name="source" select="$source_current" />
                        <xsl:with-param name="previous_xpath" select="$source_xpath" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="source_xpath_use">
                    <xsl:call-template name="combine-xpaths">
                        <xsl:with-param name="previous_xpath" select="$source_xpath" />
                        <xsl:with-param name="xpath" select="@node" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:apply-templates select="$source_use"
                    mode="mapping_source">
                    <xsl:with-param name="record" select="$record" />
                    <xsl:with-param name="mapping" select="$use_mapping" />
                    <xsl:with-param name="source_xpath" select="$source_xpath_use" />
               </xsl:apply-templates>
           </xsl:if>
        </xsl:for-each>

        <!-- Process mappings included in the configuration of the record one
        time only. -->
        <!--
        <xsl:variable name="main_mapping"
            select="mapper:get-main-mapping-of-record($record)" />
        -->
        <xsl:variable name="main_mapping_position">
            <xsl:call-template name="get-position-of-main-mapping-of-record">
                <xsl:with-param name="record" select="$record" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="main_mapping"
                select="$record/use[position() = $main_mapping_position]" />
        <xsl:if test="$mapping/@name = $main_mapping/@mapping">
            <xsl:for-each select="$record/use
                    [@mapping != $main_mapping/@mapping]
                    [not(@type) or @type != 'base']
                    [not(@process) or @process = 'true']">
                <xsl:variable name="use_mapping"
                    select="$mappings/mapping
                            [@name = current()/@mapping]
                            [not(@type) or not(@type = $skip_mapping_types/skip/@type)]
                        " />

                <xsl:if test="$use_mapping">
                    <!--
                    <xsl:apply-templates select="mapper:get-source(@node, $source_current)"
                    -->
                    <xsl:variable name="source_use">
                        <xsl:call-template name="get-source">
                            <xsl:with-param name="xpath" select="@node" />
                            <xsl:with-param name="source" select="$source_current" />
                            <xsl:with-param name="previous_xpath" select="$source_xpath" />
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:variable name="source_xpath_use">
                        <xsl:call-template name="combine-xpaths">
                            <xsl:with-param name="previous_xpath" select="$source_xpath" />
                            <xsl:with-param name="xpath" select="@node" />
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:apply-templates select="$source_use"
                        mode="mapping_source">
                        <xsl:with-param name="record" select="$record" />
                        <xsl:with-param name="mapping" select="$use_mapping" />
                        <xsl:with-param name="source_xpath" select="$source_xpath_use" />
                   </xsl:apply-templates>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Process the base mapping for one direct map. -->
    <xsl:template match="mappings/mapping/map" mode="simple">
        <xsl:param name="source" select="$input" />
        <!-- This value is needed only to manage specific axis in xslt 1. -->
        <xsl:param name="source_xpath" select="''" />

        <xsl:variable name="map" select="." />

        <xsl:variable name="values">
            <!--
            select="mapper:get-node-from(@from, $source)" />
            -->
            <xsl:call-template name="get-node-values">
                <xsl:with-param name="xpath" select="@from" />
                <xsl:with-param name="node" select="$source" />
                <xsl:with-param name="source_xpath" select="$source_xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="$values">
            <xsl:variable name="value_conditions_source">
                <xsl:call-template name="mapping-conditions-source">
                    <xsl:with-param name="map" select="$map" />
                    <xsl:with-param name="value" select="." />
                </xsl:call-template>
            </xsl:variable>

            <xsl:if test="normalize-space($value_conditions_source) != ''">
                <xsl:for-each select="$value_conditions_source/node()">
                    <xsl:variable name="value">
                        <xsl:apply-templates select="." mode="format_value">
                            <xsl:with-param name="format" select="$map" />
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:call-template name="create-mapped-element">
                        <xsl:with-param name="map" select="$map" />
                        <xsl:with-param name="value" select="$value" />
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Process the mapping for a map with a list of values to concatenate. -->
    <xsl:template match="mappings/mapping/map" mode="concatenation">
        <xsl:param name="source" select="$input" />
        <!-- This value is needed only to manage specific axis in xslt 1. -->
        <xsl:param name="source_xpath" select="''" />

        <xsl:variable name="map" select="." />

        <xsl:variable name="concatened">
            <xsl:apply-templates select="from">
                <xsl:with-param name="source" select="$source" />
                <xsl:with-param name="source_xpath" select="$source_xpath" />
            </xsl:apply-templates>
        </xsl:variable>

        <!-- Issues can occurs with some xslt parsers, because whitespaces may
        be managed differently, even if values are "copied-of". -->
        <xsl:variable name="values">
            <xsl:choose>
                <xsl:when test="count($concatened/node()) = 0">
                </xsl:when>
                <!-- Avoids whitespaces that are added between texts. -->
                <xsl:when test="count($concatened/node()) = count($concatened/text())">
                    <xsl:call-template name="string-join-with-empty">
                        <xsl:with-param name="strings" select="$concatened" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$concatened" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- There can be only one concatenation. -->
        <xsl:if test="$values/node()">
            <xsl:call-template name="create-mapped-element">
                <xsl:with-param name="map" select="$map" />
                <xsl:with-param name="value" select="$values" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Create one mapped element, with or without the prefix of the namespace. -->
    <xsl:template name="create-mapped-element">
        <xsl:param name="map" />
        <xsl:param name="value" />

        <xsl:variable name="prefix">
            <xsl:choose>
                <xsl:when test="contains($map/@to, ':')">
                    <xsl:value-of select="substring-before($map/@to, ':')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$prefix != ''">
                <xsl:variable name="namespace" select="$mappings
                        /child::*
                            [local-name() = 'to' or local-name() = 'namespace']
                            [@prefix = $prefix]
                        /@namespace" />
                <xsl:element name="{$map/@to}"
                        namespace="{$namespace}">
                    <xsl:call-template name="create-mapped-value">
                        <xsl:with-param name="map" select="$map" />
                        <xsl:with-param name="value" select="$value" />
                    </xsl:call-template>
                </xsl:element>
            </xsl:when>

            <xsl:when test="$output_prefix != ''">
                <xsl:element name="{concat($output_prefix, $map/@to)}"
                        namespace="{$mappings/to[1]/@namespace}">
                    <xsl:call-template name="create-mapped-value">
                        <xsl:with-param name="map" select="$map" />
                        <xsl:with-param name="value" select="$value" />
                    </xsl:call-template>
                </xsl:element>
            </xsl:when>

            <xsl:otherwise>
                <xsl:element name="{$map/@to}">
                    <xsl:call-template name="create-mapped-value">
                        <xsl:with-param name="map" select="$map" />
                        <xsl:with-param name="value" select="$value" />
                    </xsl:call-template>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="create-mapped-value">
        <xsl:param name="map" />
        <xsl:param name="value" />

        <xsl:apply-templates select="$map/attribute">
            <xsl:with-param name="value" select="." />
        </xsl:apply-templates>

        <xsl:copy-of select="$value" />
    </xsl:template>

    <!-- Process the base mapping for multiple values for one map. -->
    <xsl:template match="mappings/mapping/map/from">
        <xsl:param name="source" select="$input" />
        <!-- This value is needed only to manage specific axis in xslt 1. -->
        <xsl:param name="source_xpath" select="''" />

        <xsl:variable name="from" select="." />

        <xsl:variable name="values">
            <!--
            select="mapper:get-node-from(@from, $source)" />
            -->
            <xsl:call-template name="get-node-values">
                <xsl:with-param name="xpath" select="@from" />
                <xsl:with-param name="node" select="$source" />
                <xsl:with-param name="source_xpath" select="$source_xpath" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="$values/node()">
            <xsl:apply-templates select="." mode="format_value">
                <xsl:with-param name="format" select="$from" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- Add an attribute to an element. -->
    <xsl:template match="mappings/mapping/map/attribute">
        <xsl:param name="value" />

        <xsl:variable name="from" select="substring(@from, 2)" />

        <xsl:choose>
            <xsl:when test="$from != '' and $value/@*[name() = $from] != ''">
                <xsl:call-template name="create-mapped-attribute">
                    <xsl:with-param name="name" select="@to" />
                    <xsl:with-param name="value"
                        select="$value/@*[local-name() = $from]" />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="@default">
                <xsl:call-template name="create-mapped-attribute">
                    <xsl:with-param name="name" select="@to" />
                    <xsl:with-param name="value" select="@default" />
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- Helper to add an attribute to an element, with or without prefix. -->
    <xsl:template name="create-mapped-attribute">
        <xsl:param name="name" />
        <xsl:param name="value" />

        <xsl:choose>
            <xsl:when test="$name =''">
            </xsl:when>

            <xsl:when test="contains($name, ':')">
                <xsl:variable name="attribute" select="substring-after($name, ':')" />
                <xsl:variable name="prefix" select="substring(substring-before($name, ':'), 2)" />
                <xsl:variable name="namespace" select="$mappings
                        /child::*
                            [local-name() = 'to' or local-name() = 'namespace']
                            [@prefix = $prefix]
                        /@namespace" />
                <xsl:attribute name="{substring($name, 2)}" namespace="{$namespace}">
                    <xsl:value-of select="$value" />
                </xsl:attribute>
            </xsl:when>

            <xsl:otherwise>
                <xsl:attribute name="{substring($name, 2)}">
                    <xsl:value-of select="$value" />
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Process conditions on the source. -->
    <xsl:template name="mapping-conditions-source">
        <xsl:param name="map" />
        <xsl:param name="value" />

        <xsl:choose>
            <xsl:when test="$map/condition/@on = 'source'">
                <xsl:choose>
                    <xsl:when test="$map/condition/@type = 'except_match'">
                        <xsl:variable name="not_matches">
                            <!-- TODO Manage multiple values. -->
                            <xsl:call-template name="mapping_conditions_except_match">
                                <xsl:with-param name="map" select="$map" />
                                <xsl:with-param name="value" select="$value" />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:if test="normalize-space($not_matches) != ''">
                            <xsl:call-template name="copy-check-node">
                                <xsl:with-param name="value" select="$not_matches" />
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:when>

                    <xsl:when test="$map/condition/@type = 'except_only'">
                        <xsl:variable name="value_except">
                            <!-- TODO Manage attributes. -->
                            <xsl:apply-templates select="$value" mode="mapping_conditions_except_only">
                                <xsl:with-param name="map" select="$map" />
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:if test="normalize-space($value_except) != ''">
                            <!--
                            <xsl:copy-of select="if ($value instance of attribute()) then string($value) else $value" />
                            -->
                            <xsl:call-template name="copy-check-node">
                                <xsl:with-param name="value" select="$value" />
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:when>

                    <xsl:otherwise>
                        <!--
                        <xsl:copy-of select="if ($value instance of attribute()) then string($value) else $value" />
                        -->
                        <xsl:call-template name="copy-check-node">
                            <xsl:with-param name="value" select="$value" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!--
                <xsl:copy-of select="if ($value instance of attribute()) then string($value) else $value" />
                -->
                <xsl:call-template name="copy-check-node">
                    <xsl:with-param name="value" select="$value" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="copy-check-node">
        <xsl:param name="value" />

        <xsl:choose>
            <xsl:when test="count($value/*) + count($value/@*) + count($value/namespace::*) = 0">
                <xsl:copy-of select="string($value)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$value" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="mapping_conditions_except_match">
        <xsl:param name="map" />
        <xsl:param name="value" />

        <xsl:if test="not(contains(
                concat('|', $map/condition/@match, '|'),
                concat('|', $value, '|')))">
                <xsl:value-of select="." />
        </xsl:if>
    </xsl:template>

    <xsl:template match="/|node()" mode="mapping_conditions_except_only">
        <xsl:param name="map" />
        <xsl:copy>
            <!--
                select="node()[not(index-of(
                    tokenize($map/condition/@match, '\|'),
                    local-name()))]"
            -->
            <xsl:apply-templates
                select="node()[not(contains(
                    concat('|', $map/condition/@match, '|'),
                    concat('|', local-name(), '|')))]"
                mode="mapping_conditions_except_only">
                <xsl:with-param name="map" select="$map" />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- ==============================================================
    Templates to process conditions on resulting mapped record.
    =============================================================== -->

    <!-- Apply options on resulting mapped record. -->
    <xsl:template match="/|*" mode="mapping_result">
        <xsl:param name="record" />
        <xsl:param name="mapping" />

        <!-- Process conditions on the result if any. -->
        <xsl:variable name="mapped_A">
            <xsl:apply-templates select="." mode="mapping_conditions_result">
                <xsl:with-param name="record" select="$record" />
                <xsl:with-param name="mapping" select="$mapping" />
            </xsl:apply-templates>
        </xsl:variable>

        <!-- TODO Convert all of these process into simple templates. -->
        <!-- Normalize spaces if wished. -->
        <xsl:variable name="mapped_B">
            <xsl:choose>
                <xsl:when test="$record/@normalize_space = 'true'
                        or (not($record/@normalize_space)
                            and (not($record/../@normalize_space) or $record/../@normalize_space = 'true'))">
                    <xsl:apply-templates select="$mapped_A" mode="normalize_space" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$mapped_A" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Remove duplicates if wished. -->
        <xsl:variable name="mapped_C">
            <xsl:choose>
                <xsl:when test="$record/@deduplicate = 'true'
                        or (not($record/@deduplicate)
                            and (not($record/../@deduplicate) or $record/../@deduplicate = 'true'))">
                    <xsl:apply-templates select="$mapped_B" mode="deduplicate_flat_tree" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$mapped_B" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Remove empty values if wished. -->
        <xsl:variable name="mapped_D">
            <xsl:choose>
                <xsl:when test="$record/@remove_empty = 'true'
                        or (not($record/@remove_empty)
                            and (not($record/../@remove_empty) or $record/../@remove_empty = 'true'))">
                    <xsl:copy-of select="$mapped_C/*[node() != '']" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$mapped_C" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Order according to the mapping file. -->
        <xsl:variable name="mapping_order">
            <!--
                if (exists($mapping/@order))
                then $mapping/@order
                else $mappings/order/@order" />
            -->
            <xsl:choose>
                <xsl:when test="$mapping/@order">
                    <xsl:value-of select="$mapping/@order" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$mappings/order/@order" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="mapped_last">
            <xsl:choose>
                <xsl:when test="not($record/../@order) or $record/../@order = 'true'
                        and $mappings/mapping[@name = $mapping_order]">
                    <xsl:for-each select="$mappings/mapping[@name = $mapping_order]/map">
                        <xsl:if test="count(preceding-sibling::*[@to = current()/@to]) = 0">
                            <xsl:choose>
                                <xsl:when test="contains(@to, ':')">
                                    <xsl:copy-of select="$mapped_D/*[name() = current()/@to]" />
                                </xsl:when>
                                <xsl:when test="$output_prefix != ''">
                                    <xsl:variable name="current_to" select="concat($output_prefix, current()/@to)" />
                                    <xsl:copy-of select="$mapped_D/*[name() = $current_to]" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$mapped_D/*[local-name() = current()/@to]" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$mapped_D" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Last, return the result of process on the mapped record. -->
        <xsl:copy-of select="$mapped_last" />
    </xsl:template>

    <!-- Process conditions on the result. -->
    <!-- Warning: conditions are checked on the result, wherever they came from. -->
    <xsl:template match="/" mode="mapping_conditions_result">
        <xsl:param name="record" />
        <xsl:param name="mapping" />

        <xsl:variable name="maps">
            <xsl:call-template name="list-maps">
                <xsl:with-param name="record" select="$record" />
                <xsl:with-param name="mapping" select="$mapping" />
            </xsl:call-template>
        </xsl:variable>

        <!-- Copy all mapped elements without condition on result. -->
        <xsl:copy-of select="node()[not(local-name() = $maps/map[condition/@on = 'result']/@to)]" />

        <!-- Process all conditions. -->
        <xsl:apply-templates select="$maps/map[condition/@on = 'result']"
            mode="mapping_conditions_result_dispatch">
            <xsl:with-param name="mapped" select="." />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Dispatch conditions on result. -->
    <xsl:template match="map" mode="mapping_conditions_result_dispatch">
        <xsl:param name="mapped" />

        <xsl:choose>
            <xsl:when test="condition[@on = 'result']/@type = 'default'">
                <xsl:apply-templates select="." mode="mapping_conditions_result_default">
                    <xsl:with-param name="mapped" select="$mapped" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="condition[@on = 'result']/@type = 'add'">
                <xsl:apply-templates select="." mode="mapping_conditions_result_add">
                    <xsl:with-param name="mapped" select="$mapped" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="condition[@on = 'result']/@type = 'different'">
                <xsl:apply-templates select="." mode="mapping_conditions_result_different">
                    <xsl:with-param name="mapped" select="$mapped" />
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- Add a default value when an element doesn't exist in source. -->
    <xsl:template match="map" mode="mapping_conditions_result_default">
        <xsl:param name="mapped" />

        <xsl:variable name="map" select="." />

        <xsl:if test="not($mapped/*[local-name() = current()/@to])">
            <xsl:for-each select="condition[@on = 'result'][@type = 'default']">
                <xsl:call-template name="create-mapped-element">
                    <xsl:with-param name="map" select="$map" />
                    <xsl:with-param name="value" select="string(@value)" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Add a default value when an element doesn't exist in source. -->
    <xsl:template match="map" mode="mapping_conditions_result_add">
        <xsl:param name="mapped" />

        <xsl:variable name="map" as="element()" select="." />

        <xsl:for-each select="condition[@on = 'result'][@type = 'add']">
            <xsl:call-template name="create-mapped-element">
                <xsl:with-param name="map" select="$map" />
                <xsl:with-param name="value" select="string(@value)" />
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Helper to check existing results. -->
    <xsl:template match="map" mode="mapping_conditions_result_different">
        <xsl:param name="mapped" />

        <xsl:copy-of select="$mapped/*[local-name() = current()/@to]
                [not(. = $mapped/*[local-name() = current()/condition/@match])]" />
    </xsl:template>

    <!-- ==============================================================
    Internal Helpers.
    =============================================================== -->

    <xsl:template name="get-node-values">
        <xsl:param name="xpath" />
        <xsl:param name="node" />
        <xsl:param name="source_xpath" />

        <xsl:variable name="path" select="normalize-space($xpath)" />

        <xsl:choose>
            <xsl:when test="string($source_xpath) != '' and $source_xpath != '/'">
                <xsl:choose>
                    <xsl:when test="$path = 'mapper:get-absolute-xpath(.)'">
                        <xsl:value-of select="$source_xpath" />
                    </xsl:when>

                    <xsl:when test="'mapper:get-identifier(.)' = substring($path, string-length($path) - string-length('mapper:get-identifier(.)') + 1)">
                        <xsl:variable name="nodes">
                            <xsl:choose>
                                <xsl:when test="normalize-space(substring-before($path, '/mapper:get-identifier')) != ''">
                                    <xsl:call-template name="get-node-from">
                                        <xsl:with-param name="xpath"
                                            select="normalize-space(substring-before($path, '/mapper:get-identifier'))" />
                                        <xsl:with-param name="node" select="$node" />
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$node" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:call-template name="get-identifier">
                            <xsl:with-param name="node" select="$nodes" />
                            <xsl:with-param name="base_xpath" select="$source_xpath" />
                        </xsl:call-template>
                    </xsl:when>

                    <xsl:when test="$path = 'mapper:get-ancestor-identifier(.)'">
                        <xsl:call-template name="get-ancestor-identifier-via-xpath">
                            <xsl:with-param name="xpath" select="$source_xpath" />
                        </xsl:call-template>
                    </xsl:when>

                    <!-- Not a special case, so default. -->
                    <xsl:otherwise>
                        <xsl:call-template name="get-node-from">
                            <xsl:with-param name="xpath" select="$path" />
                            <xsl:with-param name="node" select="$node" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <xsl:otherwise>
                <xsl:call-template name="get-node-from">
                    <xsl:with-param name="xpath" select="$path" />
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-node-from">
        <xsl:param name="xpath" />
        <xsl:param name="node" />

        <xsl:variable name="path" select="normalize-space($xpath)" />

        <xsl:choose>
            <xsl:when test="starts-with($path, '/') and not(starts-with($path, '//'))">
                <xsl:call-template name="get-node">
                    <xsl:with-param name="xpath" select="$path" />
                    <xsl:with-param name="node" select="$input" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="get-node">
                    <xsl:with-param name="xpath" select="$path" />
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-main-mapping-of-record">
        <xsl:param name="record" />

        <!--
        <xsl:sequence select="
                if ($record/use[@type = 'base'][not(@process) or @process = 'true'])
                then $record/use[@type = 'base'][not(@process) or @process = 'true'][1]
                else $record/use[not(@process) or @process = 'true'][1]" />
        -->
        <xsl:choose>
            <xsl:when test="$record/use[@type = 'base'][not(@process) or @process = 'true']">
                <xsl:copy-of select="$record/use[@type = 'base'][not(@process) or @process = 'true'][1]" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$record/use[not(@process) or @process = 'true'][1]" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Get the position of the "use" element inside a record.
    This allows to get around a limit of xslt 1 (no sequence of node set).
    -->
    <xsl:template name="get-position-of-main-mapping-of-record">
        <xsl:param name="record" />

        <xsl:choose>
            <xsl:when test="$record/use[@type = 'base'][not(@process) or @process = 'true']">
                <xsl:value-of select="count($record
                        /use[@type = 'base'][not(@process) or @process = 'true'][1]
                        /preceding-sibling::use)
                        + 1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="count($record
                        /use[not(@process) or @process = 'true'][1]
                        /preceding-sibling::use)
                        + 1" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-source">
        <xsl:param name="xpath" />
        <xsl:param name="source" />
        <xsl:param name="previous_xpath" />

        <!--
        <xsl:sequence select="
                if ($path != '')
                then if (starts-with($path, '/') and not(starts-with($path, '//')))
                    then dynx:get-node($path, $input)
                    else dynx:get-node($path, $source)
                else $source" />
        -->
        <xsl:choose>
            <xsl:when test="normalize-space($xpath) != ''">
                <xsl:variable name="absolute_xpath">
                    <xsl:call-template name="combine-xpaths">
                        <xsl:with-param name="previous_xpath" select="$previous_xpath" />
                        <xsl:with-param name="xpath" select="$xpath" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="result">
                    <xsl:call-template name="get-sequence">
                        <xsl:with-param name="xpath" select="$absolute_xpath" />
                        <xsl:with-param name="node" select="$input" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$result/node/node()" />
            </xsl:when>

            <xsl:otherwise>
                <xsl:copy-of select="$source" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper to combine the previous path and the new path, where the latter
    can be relative or absolute. -->
    <xsl:template name="combine-xpaths">
        <xsl:param name="previous_xpath" />
        <xsl:param name="xpath" />

        <xsl:variable name="path" select="normalize-space($xpath)" />

        <xsl:choose>
            <xsl:when test="starts-with($path, '//')">
                <xsl:value-of select="concat($previous_xpath, $path)" />
            </xsl:when>
            <xsl:when test="starts-with($path, '/')">
                <xsl:value-of select="$path" />
            </xsl:when>
            <xsl:when test="string($path) = ''">
                <xsl:value-of select="$previous_xpath" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($previous_xpath, '/', $path)" />
            </xsl:otherwise>
         </xsl:choose>
    </xsl:template>

    <xsl:template name="list-maps">
        <xsl:param name="record" />
        <xsl:param name="mapping" />

        <!-- Add maps included in the current mapping. -->
        <xsl:copy-of select="$mapping/map" />

        <!-- Add maps included in the "use" of the current mapping. -->
        <xsl:for-each select="$mapping/use">
            <xsl:call-template name="list-maps">
                <xsl:with-param name="record" select="$record" />
                <xsl:with-param name="mapping"
                    select="$mappings/mapping[@name = current()/@mapping]" />
            </xsl:call-template>
        </xsl:for-each>

        <!-- Add maps included in mappings included in the configuration of the
        record one time only. -->
        <!--
        <xsl:variable name="main_mapping"
            select="mapper:get-main-mapping-of-record($record)" />
        -->
        <xsl:variable name="main_mapping_position">
            <xsl:call-template name="get-position-of-main-mapping-of-record">
                <xsl:with-param name="record" select="." />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="main_mapping"
            select="$record/use[position() = $main_mapping_position]" />
        <xsl:if test="$mapping/@name = $main_mapping/@mapping">
            <xsl:for-each select="$record/use
                    [@mapping != $main_mapping/@mapping]
                    [not(@type) or @type != 'base']
                    [not(@process) or @process = 'true']">
                <xsl:variable name="use_mapping"
                    select="$mappings/mapping[@name = current()/@mapping]" />

                <xsl:if test="$use_mapping">
                    <xsl:call-template name="list-maps">
                        <xsl:with-param name="record" select="$record" />
                        <xsl:with-param name="mapping" select="$use_mapping" />
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Format a resulting value (prepend or append string, wrap...). -->
    <xsl:template match="/|@*|node()" mode="format_value">
        <xsl:param name="format" />

        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="count(*) + count(@*) + count(namespace::*) = 0
                        and normalize-space(.) = ''">
                    <xsl:if test="$format/@default != ''">
                        <xsl:value-of select="$format/@default" />
                    </xsl:if>
                </xsl:when>
                <!--
                <xsl:when test=". instance of text()
                        or . instance of attribute()
                -->
                <xsl:when test="count(*) + count(@*) + count(namespace::*) = 0
                        or $format/@mode = 'value'">
                    <xsl:value-of select="." />
                </xsl:when>
                <xsl:when test="not($format/@mode) or $format/@mode = 'node'">
                    <xsl:apply-templates select="node()" mode="copy_without_namespace" />
                </xsl:when>
                <xsl:when test="$format/@mode = 'copy'">
                    <xsl:apply-templates select="." mode="copy_without_namespace" />
                </xsl:when>
                <xsl:when test="$format/@mode = 'full_node'">
                    <xsl:copy-of select="node()" />
                </xsl:when>
                <xsl:when test="$format/@mode = 'full_copy'">
                    <xsl:copy-of select="." />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="content">
            <xsl:choose>
                <xsl:when test="count($value/*) + count($value/@*) + count($value/namespace::*) = 0
                        and normalize-space($value) = ''">
                </xsl:when>
                <!-- Texts are managed separately to avoid added whitespaces. -->
                <xsl:when test="count($value/*) = 0">
                    <xsl:variable name="replace">
                        <xsl:choose>
                            <xsl:when test="$format/@format != ''">
                                <xsl:call-template name="substring-replace">
                                    <xsl:with-param name="string" select="$format/@format" />
                                    <xsl:with-param name="replace" select="'%1'" />
                                    <xsl:with-param name="with" select="$value" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$value" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:copy-of select="concat(
                        $format/@prepend,
                        $replace,
                        $format/@append)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$format/@prepend" />
                    <xsl:copy-of select="$value" />
                    <xsl:value-of select="$format/@append" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="string($content) != ''">
            <xsl:call-template name="wrap-value">
                <xsl:with-param name="value" select="$content" />
                <xsl:with-param name="wrap" select="$format/@wrap" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <xsl:template name="get-identifier">
        <xsl:param name="node" />
        <xsl:param name="base_xpath" select="''" />

        <xsl:apply-templates select="$node/node()" mode="get-identifiers">
            <xsl:with-param name="base_xpath" select="$base_xpath" />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <xsl:template match="/|*" mode="get-identifiers">
        <xsl:param name="base_xpath" select="''" />

        <node>
            <xsl:apply-templates select="." mode="get-identifier">
                <xsl:with-param name="base_xpath" select="$base_xpath" />
            </xsl:apply-templates>
        </node>
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <!-- To be overridden. -->
    <xsl:template match="/|*" mode="get-identifier">
        <xsl:param name="base_xpath" select="''" />

        <xsl:text></xsl:text>
    </xsl:template>

    <!-- Helper to get the ancestor of a node in order to manage hierarchical relations. -->
    <!-- To be overridden. -->
    <xsl:template name="get-ancestor">
        <xsl:param name="node" select="." />

        <xsl:choose>
            <xsl:when test="not($node)">
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$node/.." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper to get the ancestor identifier of a node in order to manage hierarchical relations. -->
    <!-- To be overridden. -->
    <xsl:template name="get-ancestor-identifier-via-xpath">
        <xsl:param name="xpath" select="''" />

        <xsl:call-template name="remove-last-part-of-xpath">
            <xsl:with-param name="xpath" select="$xpath" />
        </xsl:call-template>
    </xsl:template>

    <!-- Helper to get the base id from the config file. -->
    <xsl:template name="get-base-id">
        <xsl:value-of select="$base_id" />
    </xsl:template>

    <!-- ==============================================================
    Helpers for the dynamic xpath evaluator.
    =============================================================== -->

    <!-- Extra functions for dynamic xpath evaluator. -->
    <xsl:template name="get-node-extra-function">
        <xsl:param name="function" />
        <xsl:param name="arguments" />

        <xsl:choose>
            <xsl:when test="$function = 'mapper:copy-except'">
                <xsl:call-template name="copy-except">
                    <xsl:with-param name="elements" select="$arguments/argument[1]/text()" />
                    <xsl:with-param name="node" select="$arguments/argument[2]/node()" />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-absolute-xpath'">
                <xsl:call-template name="get-absolute-xpath">
                    <xsl:with-param name="node" select="$arguments/argument[1]/node()"  />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-base-id'">
                <xsl:call-template name="get-base-id" />
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-identifier'">
                <xsl:call-template name="get-identifier">
                    <xsl:with-param name="node" select="$arguments/argument" />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-ancestor'">
                <xsl:call-template name="get-ancestor">
                    <xsl:with-param name="node" select="$arguments/argument[1]/node()" />
                </xsl:call-template>
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-ancestor-identifier'">
                <xsl:variable name="ancestor">
                    <xsl:call-template name="get-node-extra-function">
                        <xsl:with-param name="function" select="'mapper:get-ancestor'" />
                        <xsl:with-param name="arguments" select="$arguments" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:apply-templates select="$ancestor" mode="get-identifier" />
            </xsl:when>

            <xsl:otherwise>
                <xsl:call-template name="get-node-extra-function-mapper">
                    <xsl:with-param name="function" select="$function" />
                    <xsl:with-param name="arguments" select="$arguments" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- This template may be overridden if needed. -->
    <xsl:template name="get-node-extra-function-mapper">
        <xsl:param name="function" />
        <xsl:param name="arguments" />
    </xsl:template>

</xsl:stylesheet>
