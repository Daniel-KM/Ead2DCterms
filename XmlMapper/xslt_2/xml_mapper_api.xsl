<?xml version="1.0" encoding="UTF-8"?>
<!--
Map a file in a xml format into another one via a mapping schema.

This version uses xslt version 2.0.

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

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:mapper="http://mapper"
    xmlns:dynx="http://dynx"

    exclude-result-prefixes="xsl fn xs mapper dynx">

    <!-- Import the generic helpers. -->
    <xsl:import href="xml_mapper_helpers.xsl" />

    <!-- Import dynamic xpath evaluator. -->
    <xsl:import href="dynamic_xpath_evaluator.xsl" />

    <!-- Parameters -->
    <xsl:param name="configuration" as="xs:string?" select="''" />

    <!-- Constants. -->
    <xsl:variable name="config" as="node()" select="document($configuration)/config" />

    <xsl:variable name="mappings" as="node()"
        select="document($config/option[@name = 'mappings']/@value)/mappings" />

    <!-- Variables used for partial processing. -->
    <xsl:variable name="unique_record" as="xs:string?" select="''" />
    <xsl:variable name="skip_mapping_types" as="element()?" />

    <!-- The main xml source to process. -->
    <xsl:variable name="input" as="node()" select="/" />

    <xsl:variable name="output_prefix" select="
            if ($config/option[@name = 'output_prefix']/@value = 'false'
                or $mappings/to[1]/@prefix = ''
                or $mappings/to[1]/@namespace = '')
            then ''
            else concat($mappings/to[1]/@prefix, ':')" />

    <xsl:variable name="base_id" as="xs:string">
        <xsl:choose>
            <xsl:when test="normalize-space(dynx:get-node($config/baseid/@from, $input)) != ''">
                <xsl:value-of select="normalize-space(dynx:get-node($config/baseid/@from, $input))" />
            </xsl:when>
            <xsl:when test="normalize-space(dynx:get-node($mappings/baseid/@from, $input)) != ''">
                <xsl:value-of select="normalize-space(dynx:get-node($mappings/baseid/@from, $input))" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$config/baseid/@default" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ==============================================================
    Main Templates
    =============================================================== -->

    <xsl:template match="/">
        <xsl:apply-templates select="." mode="mapper" />
    </xsl:template>

    <xsl:template match="/" mode="mapper">
        <xsl:apply-templates select="$config
                /records[not(@process) or @process = 'true']"
            mode="process_records" />
    </xsl:template>

    <xsl:template match="config/records" mode="process_records">
        <xsl:variable name="element" as="xs:string" select="
                if (@element != '')
                then @element
                else if ($config/option[@name = 'default_element_root']/@value != '')
                    then $config/option[@name = 'default_element_root']/@value
                    else 'records'" />

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

        </xsl:element>
    </xsl:template>

    <xsl:template match="config/records/record" mode="process_record">
        <xsl:variable name="main_mapping" as="element()"
            select="mapper:get-main-mapping-of-record(.)" />

        <xsl:apply-templates select="$mappings/mapping[@name = $main_mapping/@mapping]"
            mode="mapping">
            <xsl:with-param name="record" select="." />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Process one mapping for one configured type of record:
    - create one or multiple records from the source, via this main mapping and
    all dependant ones;
    - process conditions on the resulting mapped records. -->
    <xsl:template match="mappings/mapping" mode="mapping">
        <xsl:param name="record" as="element()" />

        <xsl:variable name="mapping" as="element()" select="." />

        <xsl:variable name="element" as="xs:string" select="
                if ($record/@element != '')
                then $record/@element
                else if ($config/option[@name = 'default_element_record']/@value != '')
                    then $config/option[@name = 'default_element_record']/@value
                    else 'record'" />

        <xsl:variable name="records"
            select="if (@root != '') then dynx:get-node(@root, $input) else $input" />

        <xsl:for-each select="$records">
            <xsl:element name="{$element}">
                <xsl:if test="(not($record/../@record_name) or $record/../@record_name = 'true')
                    and $record/@name != ''">
                    <xsl:attribute name="type">
                        <xsl:value-of select="$record/@name" />
                    </xsl:attribute>
                </xsl:if>

                <!-- First, do all of the mapping for the record. -->
                <xsl:variable name="mapped">
                    <xsl:apply-templates select="." mode="mapping_source">
                        <xsl:with-param name="record" select="$record" />
                        <xsl:with-param name="mapping" select="$mapping" />
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
        <xsl:param name="record" as="element()" />
        <xsl:param name="mapping" as="element()" />

        <xsl:variable name="source_base" select="mapper:get-source($mapping/@base, .)" />

        <xsl:if test="not(empty($source_base))">
            <xsl:apply-templates select="$mapping/map[not(@type) or @type = 'simple']" mode="simple">
                <xsl:with-param name="source" select="$source_base" />
            </xsl:apply-templates>

            <xsl:apply-templates select="$mapping/map[@type = 'concatenation']" mode="concatenation">
                <xsl:with-param name="source" select="$source_base" />
            </xsl:apply-templates>
        </xsl:if>

        <xsl:variable name="source_current" select="." />

        <!-- Process mappings included in the main mapping. -->
        <xsl:for-each select="$mapping/use">
            <xsl:variable name="use_mapping" as="element()*"
                select="$mappings/mapping
                        [@name = current()/@mapping]
                        [not(@type) or not(@type = $skip_mapping_types/skip/@type)]
                    " />

            <xsl:if test="$use_mapping">
                <xsl:apply-templates select="mapper:get-source(@node, $source_current)"
                    mode="mapping_source">
                    <xsl:with-param name="record" select="$record" />
                    <xsl:with-param name="mapping" select="$use_mapping" />
                </xsl:apply-templates>
            </xsl:if>
        </xsl:for-each>

        <!-- Process mappings included in the configuration of the record one
        time only. -->
        <xsl:variable name="main_mapping" as="element()"
            select="mapper:get-main-mapping-of-record($record)" />
        <xsl:if test="$mapping/@name = $main_mapping/@mapping">
            <xsl:for-each select="$record/use
                    [@mapping != $main_mapping/@mapping]
                    [not(@type) or @type != 'base']
                    [not(@process) or @process = 'true']">
                <xsl:variable name="use_mapping" as="element()*"
                    select="$mappings/mapping
                            [@name = current()/@mapping]
                            [not(@type) or not(@type = $skip_mapping_types/skip/@type)]
                        " />

                <xsl:if test="$use_mapping">
                    <xsl:apply-templates select="mapper:get-source(@node, $source_current)"
                        mode="mapping_source">
                        <xsl:with-param name="record" select="$record" />
                        <xsl:with-param name="mapping" select="$use_mapping" />
                   </xsl:apply-templates>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Process the base mapping for one direct map. -->
    <xsl:template match="mappings/mapping/map" mode="simple">
        <xsl:param name="source" as="node()*" select="$input" />

        <xsl:variable name="map" as="element()" select="." />

        <xsl:variable name="values" select="mapper:get-node-from(@from, $source)" />

        <xsl:for-each select="$values">
            <xsl:variable name="value_conditions_source">
                <xsl:call-template name="mapping-conditions-source">
                    <xsl:with-param name="map" select="$map" />
                    <xsl:with-param name="value" select="." />
                </xsl:call-template>
            </xsl:variable>

            <xsl:if test="normalize-space($value_conditions_source) != ''">
                <xsl:variable name="value" as="item()?">
                    <xsl:apply-templates select="$value_conditions_source" mode="format_value">
                        <xsl:with-param name="format" select="$map" />
                    </xsl:apply-templates>
                </xsl:variable>

                <xsl:call-template name="create-mapped-element">
                    <xsl:with-param name="map" select="$map" />
                    <xsl:with-param name="value" select="$value" />
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Process the mapping for a map with a list of values to concatenate. -->
    <xsl:template match="mappings/mapping/map" mode="concatenation">
        <xsl:param name="source" as="node()*" select="$input" />

        <xsl:variable name="map" as="element()" select="." />

        <xsl:variable name="concatened">
            <xsl:apply-templates select="from">
                <xsl:with-param name="source" select="$source" />
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="values">
            <xsl:choose>
                <xsl:when test="count($concatened/node()) = 0">
                </xsl:when>
                <!-- Avoids whitespaces that are added between texts. -->
                <xsl:when test="count($concatened/node()) = count($concatened/text())">
                    <xsl:copy-of select="string-join($concatened/text(), '')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$concatened" />
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
        <xsl:param name="map" as="element()" />
        <xsl:param name="value" as="item()*" />

        <xsl:variable name="prefix" as="xs:string?" select="
                if (contains($map/@to, ':'))
                then substring-before($map/@to, ':')
                else ''" />

        <xsl:choose>
            <xsl:when test="$prefix != ''">
                <xsl:variable name="namespace" as="xs:string?" select="$mappings
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
        <xsl:param name="map" as="element()" />
        <xsl:param name="value" as="item()*" />

        <xsl:apply-templates select="$map/attribute">
            <xsl:with-param name="value" select="." />
        </xsl:apply-templates>

        <xsl:sequence select="$value" />
    </xsl:template>

    <!-- Process the base mapping for multiple values for one map. -->
    <xsl:template match="mappings/mapping/map/from">
        <xsl:param name="source" as="node()*" select="$input" />

        <xsl:variable name="from" as="element()" select="." />

        <xsl:variable name="values" select="mapper:get-node-from(@from, $source)" />

        <xsl:for-each select="$values">
            <xsl:apply-templates select="." mode="format_value">
                <xsl:with-param name="format" select="$from" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- Add an attribute to an element. -->
    <xsl:template match="mappings/mapping/map/attribute">
        <xsl:param name="value" as="item()?" />

        <xsl:variable name="from" select="substring(@from, 2)" />

        <xsl:choose>
            <xsl:when test="$from != '' and $value/@*[local-name() = $from] != ''">
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
        <xsl:param name="name" as="xs:string?" />
        <xsl:param name="value" as="xs:string?" />

        <xsl:choose>
            <xsl:when test="$name =''">
            </xsl:when>

            <xsl:when test="contains($name, ':')">
                <xsl:variable name="attribute" as="xs:string?" select="substring-after($name, ':')" />
                <xsl:variable name="prefix" as="xs:string?" select="substring(substring-before($name, ':'), 2)" />
                <xsl:variable name="namespace" as="xs:string?" select="$mappings
                        /child::*
                            [local-name() = 'to' or local-name() = 'namespace']
                            [@prefix = $prefix]
                        /@namespace" />
              <xsl:attribute name="{$attribute}" namespace="{$namespace}">
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
        <xsl:param name="map" as="element()" />
        <xsl:param name="value" as="item()*" />

        <xsl:choose>
            <xsl:when test="$map/condition/@on = 'source'">
                <xsl:choose>
                    <xsl:when test="$map/condition/@type = 'except_match'">
                        <xsl:variable name="not_matches">
                            <xsl:apply-templates select="$value" mode="mapping_conditions_except_match">
                                <xsl:with-param name="map" select="$map" />
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:if test="normalize-space($not_matches) != ''">
                            <xsl:sequence select="if ($value instance of attribute()) then string($value) else $not_matches" />
                        </xsl:if>
                    </xsl:when>

                    <xsl:when test="$map/condition/@type = 'except_only'">
                        <xsl:variable name="value_except">
                            <xsl:apply-templates select="$value" mode="mapping_conditions_except_only">
                                <xsl:with-param name="map" select="$map" />
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:if test="normalize-space($value_except) != ''">
                            <xsl:sequence select="if ($value instance of attribute()) then string($value) else $value" />
                        </xsl:if>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:sequence select="if ($value instance of attribute()) then string($value) else $value" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="if ($value instance of attribute()) then string($value) else $value" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@*" mode="mapping_conditions_except_match">
        <xsl:param name="map" as="element()" />

        <xsl:value-of select=".[not(index-of(
                tokenize($map/condition/@match, '\|'),
                .))]" />
    </xsl:template>

    <xsl:template match="node()" mode="mapping_conditions_except_match">
        <xsl:param name="map" as="element()" />

        <xsl:sequence select="node()[not(index-of(
                tokenize($map/condition/@match, '\|'),
                .))]" />
    </xsl:template>

    <xsl:template match="node()" mode="mapping_conditions_except_only">
        <xsl:param name="map" as="element()" />

        <xsl:copy>
            <xsl:apply-templates
                select="node()[not(index-of(
                    tokenize($map/condition/@match, '\|'),
                    local-name()))]"
                mode="mapping_conditions_except_only">
                <xsl:with-param name="map" select="$map" />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- ==============================================================
    Templates to process conditions on resulting mapped record.
    =============================================================== -->

    <!-- Apply options on resulting mapped record. -->
    <xsl:template match="/" mode="mapping_result">
        <xsl:param name="record" as="element()" />
        <xsl:param name="mapping" as="element()" />

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
                    <xsl:sequence select="$mapped_A" />
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
                    <xsl:sequence select="$mapped_B" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Remove empty values if wished. -->
        <xsl:variable name="mapped_D">
            <xsl:choose>
                <xsl:when test="$record/@remove_empty = 'true'
                        or (not($record/@remove_empty)
                            and (not($record/../@remove_empty) or $record/../@remove_empty = 'true'))">
                    <xsl:sequence select="$mapped_C/*[node() != '']" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$mapped_C" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Order according to the mapping file. -->
        <xsl:variable name="mapping_order" select="
                if (exists($mapping/@order))
                then $mapping/@order
                else $mappings/order/@order" />
        <xsl:variable name="mapped_last">
            <xsl:choose>
                <xsl:when test="not($record/../@order) or $record/../@order = 'true'
                        and $mappings/mapping[@name = $mapping_order]">
                    <xsl:for-each select="$mappings/mapping[@name = $mapping_order]/map">
                        <xsl:if test="count(preceding-sibling::*[@to = current()/@to]) = 0">
                            <xsl:choose>
                                <xsl:when test="contains(@to, ':')">
                                    <xsl:sequence select="$mapped_D/*[name() = current()/@to]" />
                                </xsl:when>
                                <xsl:when test="$output_prefix != ''">
                                    <xsl:variable name="current_to" select="concat($output_prefix, current()/@to)" />
                                    <xsl:copy-of select="$mapped_D/*[name() = $current_to]" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="$mapped_D/*[local-name() = current()/@to]" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$mapped_D" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Last, return the result of process on the mapped record. -->
        <xsl:sequence select="$mapped_last" />
    </xsl:template>

    <!-- Process conditions on the result. -->
    <!-- Warning: conditions are checked on the result, wherever they came from. -->
    <xsl:template match="/" mode="mapping_conditions_result">
        <xsl:param name="record" as="element()" />
        <xsl:param name="mapping" as="element()" />

        <xsl:variable name="maps" as="element()*">
            <xsl:call-template name="list-maps">
                <xsl:with-param name="record" select="$record" />
                <xsl:with-param name="mapping" select="$mapping" />
            </xsl:call-template>
        </xsl:variable>

        <!-- Copy all mapped elements without condition on result. -->
        <xsl:sequence select="node()[not(local-name() = $maps[condition/@on = 'result']/@to)]" />

        <!-- Process all conditions. -->
        <xsl:apply-templates select="$maps[condition/@on = 'result']"
            mode="mapping_conditions_result_dispatch">
            <xsl:with-param name="mapped" select="." />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Dispatch conditions on result. -->
    <xsl:template match="mappings/mapping/map" mode="mapping_conditions_result_dispatch">
        <xsl:param name="mapped" as="node()" />

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
    <xsl:template match="mappings/mapping/map" mode="mapping_conditions_result_default">
        <xsl:param name="mapped" as="node()" />

        <xsl:variable name="map" as="element()" select="." />

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
    <xsl:template match="mappings/mapping/map" mode="mapping_conditions_result_add">
        <xsl:param name="mapped" as="node()" />

        <xsl:variable name="map" as="element()" select="." />

        <xsl:for-each select="condition[@on = 'result'][@type = 'add']">
            <xsl:call-template name="create-mapped-element">
                <xsl:with-param name="map" select="$map" />
                <xsl:with-param name="value" select="string(@value)" />
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Helper to check existing results. -->
    <xsl:template match="mappings/mapping/map" mode="mapping_conditions_result_different">
        <xsl:param name="mapped" as="node()" />

        <xsl:sequence select="$mapped/*[local-name() = current()/@to]
                [not(. = $mapped/*[local-name() = current()/condition/@match])]" />
    </xsl:template>

    <!-- ==============================================================
    Internal Helpers.
    =============================================================== -->

    <xsl:function name="mapper:get-node-from" as="item()*">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:call-template name="get-node-from">
            <xsl:with-param name="xpath" select="$xpath" />
            <xsl:with-param name="node" select="$node" />
        </xsl:call-template>
    </xsl:function>

    <xsl:template name="get-node-from">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="node" as="node()*" />

        <xsl:variable name="path" as="xs:string?" select="normalize-space($xpath)" />

        <xsl:call-template name="get-node">
            <xsl:with-param name="xpath" select="$path" />
            <xsl:with-param name="node" select="
                    if (starts-with($path, '/') and not(starts-with($path, '//')))
                    then $input
                    else $node" />
        </xsl:call-template>
    </xsl:template>

    <xsl:function name="mapper:get-main-mapping-of-record">
        <xsl:param name="record" as="element()" />

        <xsl:sequence select="
                if ($record/use[@type = 'base'][not(@process) or @process = 'true'])
                then $record/use[@type = 'base'][not(@process) or @process = 'true'][1]
                else $record/use[not(@process) or @process = 'true'][1]" />
    </xsl:function>

    <xsl:function name="mapper:get-source">
        <xsl:param name="xpath" as="xs:string?" />
        <xsl:param name="source" as="node()*" />

        <xsl:variable name="path" as="xs:string?" select="normalize-space($xpath)" />

        <xsl:sequence select="
                if ($path != '')
                then if (starts-with($path, '/') and not(starts-with($path, '//')))
                    then dynx:get-node($path, $input)
                    else dynx:get-node($path, $source)
                else $source" />
    </xsl:function>

    <xsl:template name="list-maps">
        <xsl:param name="record" as="element()" />
        <xsl:param name="mapping" as="element()" />

        <!-- Add maps included in the current mapping. -->
        <xsl:sequence select="$mapping/map" />

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
        <xsl:variable name="main_mapping" as="element()"
            select="mapper:get-main-mapping-of-record($record)" />
        <xsl:if test="$mapping/@name = $main_mapping/@mapping">
            <xsl:for-each select="$record/use
                    [@mapping != $main_mapping/@mapping]
                    [not(@type) or @type != 'base']
                    [not(@process) or @process = 'true']">
                <xsl:variable name="use_mapping" as="element()*"
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
    <xsl:template match="@*|node()" mode="format_value">
        <xsl:param name="format" as="element()" />

        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="empty(.)">
                    <xsl:if test="$format/@default != ''">
                        <xsl:value-of select="$format/@default" />
                    </xsl:if>
                </xsl:when>
                <xsl:when test=". instance of text()
                        or . instance of attribute()
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
                    <xsl:sequence select="node()" />
                </xsl:when>
                <xsl:when test="$format/@mode = 'full_copy'">
                    <xsl:sequence select="." />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="content">
            <xsl:choose>
                <xsl:when test="empty($value)">
                </xsl:when>
                <!-- Texts are managed separately to avoid added whitespaces. -->
                <xsl:when test="count($value/*) = 0">
                    <xsl:sequence select="concat(
                        $format/@prepend,
                        if ($format/@format != '')
                        then replace($format/@format, '%1', $value)
                        else $value,
                        $format/@append)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$format/@prepend" />
                    <xsl:sequence select="$value" />
                    <xsl:value-of select="$format/@append" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="$content">
            <xsl:sequence select="mapper:wrap-value($content, $format/@wrap)" />
        </xsl:if>
    </xsl:template>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <xsl:function name="mapper:get-identifier" as="xs:string*">
        <xsl:param name="node" as="node()*" />

        <xsl:apply-templates select="$node" mode="get-identifier" />
    </xsl:function>

    <!-- Helper to get the identifier of one node or a sequence of nodes. -->
    <!-- To be overridden. -->
    <xsl:template match="/|*" mode="get-identifier">
        <xsl:param name="base_xpath" as="xs:string?" select="''" />

        <xsl:text></xsl:text>
    </xsl:template>

    <!-- Helper to get the ancestor of a node in order to manage hierarchical relations. -->
    <xsl:function name="mapper:get-ancestor" as="node()?">
        <xsl:param name="node" as="node()?" />

        <xsl:call-template name="get-ancestor">
            <xsl:with-param name="node" select="$node" />
        </xsl:call-template>
    </xsl:function>

    <!-- Helper to get the ancestor of a node in order to manage hierarchical relations. -->
    <!-- To be overridden. -->
    <xsl:template name="get-ancestor">
        <xsl:param name="node" as="node()?" select="." />

        <xsl:choose>
            <xsl:when test="empty($node)">
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$node/.." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper to get the base id from the config file. -->
    <xsl:function name="mapper:get-base-id" as="xs:string">
        <xsl:value-of select="$base_id" />
    </xsl:function>

    <!-- ==============================================================
    Helpers for the dynamic xpath evaluator.
    =============================================================== -->

    <!-- Extra functions for dynamic xpath evaluator. -->
    <xsl:template name="get-node-extra-function">
        <xsl:param name="function" as="xs:string" />
        <xsl:param name="arguments" as="item()*" />

        <xsl:choose>
            <xsl:when test="$function = 'mapper:copy-except'">
                <xsl:sequence select="mapper:copy-except($arguments[1], $arguments[2])" />
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-absolute-xpath'">
                <xsl:value-of select="mapper:get-absolute-xpath($arguments[1])" />
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-base-id'">
                <xsl:value-of select="mapper:get-base-id()" />
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-identifier'">
                <xsl:sequence select="mapper:get-identifier($arguments)" />
            </xsl:when>

            <xsl:when test="$function = 'mapper:get-ancestor'">
                <xsl:sequence select="mapper:get-ancestor($arguments[1])" />
            </xsl:when>

            <!-- Currently, the dynamic xpath evaluator doesn't allow a function
            inside a function. -->
            <xsl:when test="$function = 'mapper:get-ancestor-identifier'">
                <xsl:sequence select="mapper:get-identifier(mapper:get-ancestor($arguments[1]))" />
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
        <xsl:param name="function" as="xs:string" />
        <xsl:param name="arguments" as="item()*" />
    </xsl:template>

</xsl:stylesheet>
