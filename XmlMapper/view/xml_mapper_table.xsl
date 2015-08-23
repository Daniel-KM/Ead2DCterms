<?xml version="1.0" encoding="utf-8"?>
<!--
Stylesheet to display an xml mapping table as an html table with a Bootstrap theme.

Includes
- Bootstrap, published under the MIT licence (see http://getbootstrap.com).
- JQuery, published under the MIT licence (see https://jquery.com).

Copyrights and licences for the third parties above can be found in the specific
files and online.

@version: 20150824
@copyright Daniel Berthereau, 2015
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
@link https://github.com/Daniel-KM/Ead2DCterms
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xsl">

    <xsl:output
        method="html"
        doctype-system="about:legacy-compat"
        indent="yes" />

    <!-- Let empty to use the default. -->
    <xsl:param name="homepage-url" select="''" />
    <xsl:param name="homepage-text" select="'Mapping Table'" />

    <!-- Urls for the menu. -->
    <xsl:param name="file-base" select="'https://github.com/Daniel-KM/Ead2DCterms/blob/master/'" />
    <xsl:param name="file-mappings">
        <xsl:choose>
            <xsl:when test="count(/child::*/to) = 1">
                <xsl:value-of select="concat(/child::*/from/@prefix, '2', /child::*/to/@prefix, '_mappings.xml')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(/child::*/from/@prefix, '2', /child::*/to[1]/@prefix, '-', /child::*/to[2]/@prefix, '_mappings.xml')" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="file-config">
        <xsl:choose>
            <xsl:when test="count(/child::*/to) = 1">
                <xsl:value-of select="concat(/child::*/from/@prefix, '2', /child::*/to/@prefix, '_config.xml')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(/child::*/from/@prefix, '2', /child::*/to[1]/@prefix, '-', /child::*/to[2]/@prefix, '_config.xml')" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <!-- Url for "powered by" link (logo is set in css if wanted). -->
    <xsl:param name="powered-by-url" select="'https://github.com/Daniel-KM/Ead2DCterms'" />
    <xsl:param name="powered-by-text" select="'EAD to Dublin Core Terms'" />

    <!-- A url for the main message. -->
    <xsl:param name="url-base" select="''" />

    <!-- Url to css and javascripts. -->
    <!--
    <xsl:param name="css-bootstrap" select="'css/bootstrap.min.css'" />
    <xsl:param name="css-bootstrap-theme" select="'css/bootstrap-theme.min.css'" />
    <xsl:param name="javascript-jquery" select="'javascripts/jquery.js'" />
    <xsl:param name="javascript-bootstrap" select="'javascripts/bootstrap.min.js'" />
    -->
    <xsl:param name="css-bootstrap" select="'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css'" />
    <xsl:param name="css-bootstrap-theme" select="'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css'" />
    <xsl:param name="javascript-jquery" select="'https://code.jquery.com/jquery-2.1.4.min.js'" />
    <xsl:param name="javascript-bootstrap" select="'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js'" />

    <!-- Constants. -->
    <xsl:variable name="url-homepage">
        <xsl:choose>
            <xsl:when test="$homepage-url != ''">
                <xsl:value-of select="$homepage-url" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÄËÏÖÜŸÇ'" />
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyzáéíóúàèìòùâêîôûäëïöüÿç'" />
    <xsl:variable name="forbidden_characters" select="':/.()#? '" />

    <xsl:template match="/">
        <html lang="en">
            <head>
                <xsl:element name="meta">
                    <xsl:attribute name="charset">utf-8</xsl:attribute>
                </xsl:element>
                <xsl:element name="meta">
                    <xsl:attribute name="http-equiv">X-UA-Compatible</xsl:attribute>
                    <xsl:attribute name="content">IE=edge</xsl:attribute>
                </xsl:element>
                <xsl:element name="meta">
                    <xsl:attribute name="name">viewport</xsl:attribute>
                    <xsl:attribute name="content">width=device-width, initial-scale=1</xsl:attribute>
                </xsl:element>
                <xsl:element name="meta">
                    <xsl:attribute name="name">description</xsl:attribute>
                    <xsl:attribute name="content">Xml mapping table from "<xsl:value-of select="/child::*/from/@name" />" to "<xsl:value-of select="/child::*/to[1]/@name" />"</xsl:attribute>
                </xsl:element>
                <link rel="icon" href="/favicon.ico" />
                <title><xsl:value-of select="$homepage-text" /></title>
                <link rel="stylesheet" href="{$css-bootstrap}" type="text/css" />
                <link rel="stylesheet" href="{$css-bootstrap-theme}" type="text/css" />
                <xsl:comment>HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries</xsl:comment>
                <xsl:comment><![CDATA[[if lt IE 9]>
        <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
        <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]]]></xsl:comment>
                <style type="text/css">
                    <xsl:text>
                    body { padding-top: 70px;}
                    footer { border-top: 1px solid #e5e5e5; color: #767676; margin-top: 100px; padding-bottom: 40px; padding-top: 40px;}
                    footer a { color: #000000;}
                    a#logo { background: transparent none no-repeat scroll 0 0 / 100% 100%; /*  padding: 8px 51px; */}
                    .vertical-space { height: 20px;}
                    .config .dl-horizontal dt { width: 200px;}
                    .config .dl-horizontal dd { margin-left: 220px;}
                    .table .dl-horizontal dt { width: 60px;}
                    .table .dl-horizontal dd { margin-left: 80px;}
                    .table dt { font-style: italic; font-weight: normal;}
                    table ul { padding-left: 20px;}
                    .mappings h2, .config h2 { border-bottom-style: inset;}
                    .tooltip-inner { text-align: initial;}
                    </xsl:text>
                </style>
            </head>
            <body>
                <nav class="navbar navbar-inverse navbar-fixed-top">
                    <div class="container-fluid">
                        <div class="navbar-header">
                            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                                <span class="sr-only">Toggle navigation</span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                            </button>
                            <a class="navbar-brand">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$url-homepage" />
                                </xsl:attribute>
                                <xsl:value-of select="$homepage-text" />
                            </a>
                        </div>
                        <div id="navbar" class="navbar-collapse collapse">
                            <p class="navbar-text">
                                <span class="label label-default">
                                    <xsl:value-of select="/child::*/from/@prefix" />
                                </span>
                                <span class="glyphicon glyphicon-chevron-right" />
                                <xsl:for-each select="/child::*/to">
                                    <span class="label label-default">
                                        <xsl:value-of select="@prefix" />
                                    </span>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </p>
                            <ul class="nav navbar-nav navbar-right">
                                <li>
                                    <xsl:if test="name(/*) = 'mappings'">
                                        <xsl:attribute name="class">
                                            <xsl:text>active</xsl:text>
                                        </xsl:attribute>
                                    </xsl:if>
                                    <a href="{$file-mappings}" title="View all mappings">
                                        <xsl:text>Mappings</xsl:text>
                                    </a>
                                </li>
                                <li>
                                    <xsl:if test="name(/*) = 'config'">
                                        <xsl:attribute name="class">
                                            <xsl:text>active</xsl:text>
                                        </xsl:attribute>
                                    </xsl:if>
                                    <a href="{$file-config}" title="View the default configuration">
                                        <xsl:text>Configuration</xsl:text>
                                    </a>
                                </li>
                            </ul>
                            <!--
                            <form class="navbar-form navbar-right">
                                <input type="text" class="form-control" placeholder="Search..." />
                            </form>
                            -->
                        </div>
                    </div>
                </nav>
                <div class="container" id="top">
                    <div class="row">
                        <div class="panel panel-default panel-success mapper-presentation">
                            <xsl:if test="$url-base != ''">
                                <div class="panel-heading">
                                    <xsl:text>This mapping table is available on </xsl:text>
                                    <em><a href="{$url-base}">
                                        <xsl:value-of select="$url-base" />
                                    </a></em>
                                    <xsl:text>.</xsl:text>
                                </div>
                            </xsl:if>
                            <div class="panel-body">
                                <a class="btn btn-default collapse-data-btn pull-right" data-toggle="collapse" href="#comment-1">
                                    <xsl:text>Show/Hide presentation </xsl:text>
                                    <span class="caret"></span>
                                </a>
                                <div id="comment-1" class="collapse in">
                                    <xsl:call-template name="nl2br">
                                        <xsl:with-param name="string" select="/comment()[1]" />
                                    </xsl:call-template>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <xsl:apply-templates select="mappings" />
                        <xsl:apply-templates select="config" />
                    </div>
                </div>
                <footer class="footer">
                    <div class="container">
                        <p>
                            <xsl:text>This file is an xml one. It may be more readable as a source.</xsl:text>
                            <br />
                            <xsl:text>Use any source text editor or, on most browsers, press Control + U, or </xsl:text>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$file-base" />
                                    <xsl:choose>
                                        <xsl:when test="name(/*) = 'mappings'">
                                            <xsl:value-of select="$file-mappings" />
                                        </xsl:when>
                                        <xsl:when test="name(/*) = 'config'">
                                            <xsl:value-of select="$file-config" />
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:text>view it</xsl:text>
                            </a>
                            <xsl:text> on Github.</xsl:text>
                        </p>
                        <p>Copyright Daniel Berthereau, 2015</p>
                        <xsl:if test="$powered-by-url != '' and $powered-by-text != ''">
                            <div class="row text-right">
                                <div class="vertical-space"></div>
                                    <p><small><a href="{$powered-by-url}">
                                        <xsl:value-of select="$powered-by-text" />
                                    </a></small></p>
                                    <a href="{$powered-by-url}" id="logo" />
                                <div class="vertical-space"></div>
                            </div>
                        </xsl:if>
                    </div>
                </footer>
                <script type="text/javascript" src="{$javascript-jquery}" />
                <script type="text/javascript" src="{$javascript-bootstrap}" />
                <script type="text/javascript">
<xsl:text>$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip({ trigger: 'hover click focus'});
});</xsl:text>
                </script>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="mappings">
        <div class="mappings mappings-tables">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <xsl:text>Mappings tables </xsl:text>
                    <span class="badge">
                        <xsl:value-of select="count(mapping)" />
                    </span>
                </div>
                <div class="panel-body">
                    <xsl:apply-templates select="." mode="mappings_list" />
                </div>
                <div class="panel-footer">
                    <p>
                        <xsl:call-template name="from-to" />
                    </p>
                    <p>
                        <xsl:text>Output Namespaces</xsl:text>
                        <xsl:call-template name="comment-previous-tooltip">
                            <xsl:with-param name="node" select="namespace" />
                        </xsl:call-template>
                        <xsl:choose>
                            <xsl:when test="namespace">
                                <ul>
                                <xsl:for-each select="namespace">
                                    <li>
                                        <xsl:value-of select="@prefix" />:
                                        <a href="{@namespace}">
                                            <xsl:value-of select="@namespace" />
                                        </a>
                                    </li>
                                </xsl:for-each>
                                </ul>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>: None (see config too)</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </p>
                    <p>
                        <xsl:text>Base identifier</xsl:text>
                        <xsl:call-template name="comment-previous-tooltip">
                            <xsl:with-param name="node" select="baseid" />
                        </xsl:call-template>
                        <xsl:text>: </xsl:text>
                        <xsl:choose>
                            <xsl:when test="baseid/@from != ''">
                                <xsl:text>Selected from the original element </xsl:text>
                                <xsl:value-of select="baseid/@from" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Defined in the config file.</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </p>
                    <p>
                        <xsl:text>Default order</xsl:text>
                        <xsl:call-template name="comment-previous-tooltip">
                            <xsl:with-param name="node" select="order" />
                        </xsl:call-template>
                        <xsl:text>: </xsl:text>
                        <xsl:call-template name="mapping-link">
                            <xsl:with-param name="name" select="order/@order" />
                        </xsl:call-template>
                    </p>
                </div>
            </div>

            <xsl:apply-templates select="mapping" />
        </div>
    </xsl:template>

    <xsl:template match="config">
        <div class="config records-tables">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <xsl:text>Records Sets </xsl:text>
                    <span class="badge">
                        <xsl:value-of select="count(records)" />
                    </span>
                </div>
                <div class="panel-body">
                <nav>
                    <ul class="pagination">
                        <xsl:for-each select="records">
                            <li><a href="#records-set-{position()}"><xsl:value-of select="position()" /></a></li>
                        </xsl:for-each>
                    </ul>
                </nav>
                </div>
                <div class="panel-footer">
                    <p>
                        <xsl:call-template name="from-to" />
                    </p>
                    <p>
                        <xsl:text>Output Namespaces</xsl:text>
                        <xsl:call-template name="comment-previous-tooltip">
                            <xsl:with-param name="node" select="namespace" />
                        </xsl:call-template>
                        <xsl:choose>
                            <xsl:when test="namespace">
                                <ul>
                                <xsl:for-each select="namespace">
                                    <li>
                                        <xsl:value-of select="@prefix" />:
                                        <a href="{@namespace}">
                                            <xsl:value-of select="@namespace" />
                                        </a>
                                    </li>
                                </xsl:for-each>
                                </ul>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>: None (see mappings too).</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </p>
                    <p>
                        <xsl:text>Base identifier</xsl:text>
                        <xsl:call-template name="comment-previous-tooltip">
                            <xsl:with-param name="node" select="baseid" />
                        </xsl:call-template>
                        <xsl:text>: </xsl:text>
                        <xsl:if test="baseid/@from != ''">
                            <xsl:text>Selected from the original element </xsl:text>
                            <xsl:value-of select="baseid/@from" />
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                        <xsl:if test="baseid/@default != ''">
                            <xsl:text>Default is </xsl:text>
                            <xsl:value-of select="baseid/@default" />
                        </xsl:if>
                        <xsl:if test="not(baseid) or (not(baseid/@from) and not(baseid/@default))">
                            <xsl:text>Defined in the mapping file.</xsl:text>
                        </xsl:if>
                    </p>
                    <p>
                        <xsl:text>Options</xsl:text>
                        <xsl:choose>
                            <xsl:when test="option">
                                <dl class="dl-horizontal">
                                    <xsl:for-each select="option">
                                        <dt><xsl:value-of select="@name" /></dt>
                                        <dd><xsl:value-of select="@value" /></dd>
                                    </xsl:for-each>
                                </dl>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>: None.</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </p>
                </div>
            </div>

            <xsl:apply-templates select="records" />
        </div>
    </xsl:template>

    <xsl:template match="mappings" mode="mappings_list">
        <div class="row">
            <div class="col-sm-4">
                <xsl:if test="mapping[not(@type) or @type = '' or @type = 'full']">
                    <xsl:text>Full</xsl:text>
                    <ul>
                        <xsl:apply-templates select="mapping[not(@type) or @type = '' or @type = 'full']"
                            mode="mappings_list" />
                    </ul>
                </xsl:if>
            </div>
            <div class="col-sm-4">
                <xsl:for-each select="mapping/@type
                            [. = 'identifier' or . = 'relation']
                            [not(. = ../preceding-sibling::mapping/@type)]">
                    <xsl:value-of select="concat(
                            translate(substring(., 1, 1), $lowercase, $uppercase),
                            substring(., 2))" />
                    <ul>
                        <xsl:apply-templates select="//mapping[@type = current()]" mode="mappings_list" />
                    </ul>
                </xsl:for-each>
            </div>
            <div class="col-sm-4">
                <xsl:for-each select="mapping/@type
                            [. != 'full' and . != 'identifier' and . != 'relation']
                            [not(. = ../preceding-sibling::mapping/@type)]">
                    <xsl:value-of select="concat(
                            translate(substring(., 1, 1), $lowercase, $uppercase),
                            substring(., 2))" />
                    <ul>
                        <xsl:apply-templates select="//mapping[@type = current()]" mode="mappings_list" />
                    </ul>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="mapping" mode="mappings_list">
        <li>
            <xsl:call-template name="mapping-link">
                <xsl:with-param name="name" select="@name" />
            </xsl:call-template>
        </li>
    </xsl:template>

    <xsl:template match="mapping">
        <div class="mappings mapping-table" id="mapping-{translate(@name, $forbidden_characters, '')}">
            <h2><xsl:value-of select="@name" /></h2>
            <div class="well well-sm">
                <a class="btn btn-default pull-right" href="#top">Top</a>
                <xsl:call-template name="comment-previous-note" />
                <p>
                    <xsl:text>Type: </xsl:text>
                    <xsl:choose>
                        <xsl:when test="not(@type) or @type = '' or @type = 'full'">
                            <xsl:text>full</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@type" />
                        </xsl:otherwise>
                    </xsl:choose>
                </p>

                <xsl:if test="@root">
                    <p>
                        <xsl:text>Root: </xsl:text>
                        <xsl:value-of select="@root" />
                    </p>
                </xsl:if>

                <xsl:if test="@base">
                    <p>
                        <xsl:text>Base: </xsl:text>
                        <xsl:value-of select="@base" />
                    </p>
                </xsl:if>

                <p>
                    <xsl:text>Order: </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@order != ''">
                            <xsl:call-template name="mapping-link">
                                <xsl:with-param name="name" select="@order" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="mapping-link">
                                <xsl:with-param name="name" select="/mappings/order/@order" />
                                <xsl:with-param name="text" select="'default'" />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </div>

            <xsl:choose>
                <xsl:when test="use">
                    <xsl:choose>
                        <xsl:when test="count(use) = 1">
                            <p>
                                <xsl:text>This mapping is based on another mapping.</xsl:text>
                            </p>
                        </xsl:when>
                        <xsl:when test="count(use) &gt; 1">
                            <p>
                                <xsl:text>This mapping is based on some other mappings.</xsl:text>
                            </p>
                        </xsl:when>
                    </xsl:choose>
                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th scope="col" style="width: 48px;">#</th>
                                <th scope="col">Use mapping</th>
                                <th scope="col">Node</th>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:apply-templates select="use" />
                        </tbody>
                    </table>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="map">
                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th scope="col" style="width: 48px;">#</th>
                                <th scope="col">
                                    <xsl:value-of select="/child::*/from/@prefix" />
                                </th>
                                <th scope="col">
                                    <xsl:value-of select="/child::*/to/@prefix" />
                                </th>
                                <th scope="col">Format</th>
                                <th scope="col">Conditions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:choose>
                                <!-- Display empty maps only for the mapping used for order. -->
                                <xsl:when test="@name = ancestor::mappings/order/@order">
                                    <xsl:apply-templates select="map" />
                                </xsl:when>
                                <!-- Don't display empty maps. -->
                                <xsl:otherwise>
                                    <xsl:apply-templates select="map[@from != '' or from or attribute or condition]" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </tbody>
                    </table>
                </xsl:when>
                <xsl:otherwise>
                    <p>
                        <xsl:text>There is no map.</xsl:text>
                    </p>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="records">
        <div class="records records-table" id="records-set-{position()}">
            <h2>Records Set #<xsl:value-of select="position()" /></h2>
            <div class="well well-sm">
                <a class="btn btn-default pull-right" href="#top">Top</a>
                <xsl:call-template name="comment-previous-note" />
                <p>
                    <xsl:text>Options</xsl:text>
                    <xsl:choose>
                        <xsl:when test="@*">
                            <dl class="dl-horizontal">
                                <xsl:for-each select="@*">
                                    <dt><xsl:value-of select="name()" /></dt>
                                    <dd><xsl:value-of select="." /></dd>
                                </xsl:for-each>
                            </dl>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>: None.</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </div>

            <xsl:choose>
                <xsl:when test="record">
                    <xsl:apply-templates select="record" />
                </xsl:when>
                <xsl:otherwise>
                    <p>
                        <xsl:text>No record is defined for this records set.</xsl:text>
                    </p>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="record">
        <h3><xsl:value-of select="position()" />. <xsl:value-of select="@name" /></h3>
        <xsl:call-template name="comment-previous-note" />
        <xsl:choose>
            <xsl:when test="use">
                <table class="table table-bordered table-striped">
                    <thead>
                        <tr>
                            <th scope="col" style="width: 48px;">#</th>
                            <th scope="col">Use mapping</th>
                            <th scope="col">Node</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:apply-templates select="use" />
                    </tbody>
                </table>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:text>The mappings that this record uses are not defined.</xsl:text>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="use">
        <tr>
            <th scope="row">
                <p>
                    <xsl:value-of select="position()" />
                </p>
            </th>
            <td>
                <p>
                    <xsl:call-template name="mapping-link">
                        <xsl:with-param name="name" select="@mapping" />
                    </xsl:call-template>
                </p>
                <xsl:call-template name="comment-previous-info" />
            </td>
            <td>
                <p>
                    <xsl:choose>
                        <xsl:when test="@node">
                            <xsl:value-of select="@node" />
                        </xsl:when>
                        <xsl:otherwise>
                            <em><xsl:text>Same as parent mapping</xsl:text></em>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="map">
        <tr>
            <th scope="row">
                <p>
                    <xsl:value-of select="position()" />
                </p>
            </th>
            <td>
                <p>
                    <xsl:choose>
                        <xsl:when test="@from != ''">
                            <xsl:value-of select="@from" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="@type = 'concatenation'">
                                        <xsl:text>Concatenation</xsl:text>
                                        <ul>
                                            <xsl:apply-templates select="from" />
                                        </ul>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>

                <xsl:call-template name="comment-previous-info" />

                <xsl:choose>
                    <!-- Attribute without "from" is displayed as a format. -->
                    <xsl:when test="attribute[@from != '']">
                        <hr />
                        <p>
                            <xsl:choose>
                                <xsl:when test="count(attribute) = 1">
                                    <xsl:text>Attribute</xsl:text>
                                </xsl:when>
                                <xsl:when test="count(attribute) &gt; 1">
                                    <xsl:text>Attributes</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                            <ul>
                                <xsl:for-each select="attribute">
                                    <li>
                                        <xsl:text>From </xsl:text>
                                        <xsl:choose>
                                            <xsl:when test="@from = ''">
                                                <em>none</em>
                                                <xsl:if test="@default">
                                                    <br />
                                                    <xsl:text>Use a default</xsl:text>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="@from" />
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:call-template name="comment-previous-info" />
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </p>
                    </xsl:when>
                </xsl:choose>
            </td>

            <td>
                <p>
                    <xsl:value-of select="@to" />
                </p>
                <xsl:choose>
                    <xsl:when test="attribute[@from != '']">
                        <hr />
                        <p>
                            <xsl:choose>
                                <xsl:when test="count(attribute) = 1">
                                    <xsl:text>Attribute</xsl:text>
                                </xsl:when>
                                <xsl:when test="count(attribute) &gt; 1">
                                    <xsl:text>Attributes</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                            <ul>
                                <xsl:for-each select="attribute">
                                    <li>
                                        <xsl:text>To </xsl:text>
                                        <xsl:value-of select="@to" />
                                        <xsl:if test="@default">
                                            <br />
                                            <xsl:text>default: </xsl:text>
                                            <xsl:value-of select="@default" />
                                            <xsl:text></xsl:text>
                                        </xsl:if>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </p>
                    </xsl:when>
                </xsl:choose>
            </td>
            <td>
                <xsl:if test="@*[name() != 'from' and name() != 'to' and name() != 'type']
                        or attribute[@from = '']">
                    <ul class="mapping-cell">
                        <xsl:apply-templates select="@*[name() != 'from' and name() != 'to' and name() != 'type']
                                | attribute[@from = '']"
                            mode="list_line" />
                    </ul>
                </xsl:if>
            </td>
            <td>
                <xsl:if test="condition">
                    <ul class="mapping-cell">
                        <xsl:for-each select="condition">
                            <li>
                                <xsl:text>On: </xsl:text>
                                <xsl:value-of select="@on" />
                                <br />
                                <xsl:text>Type: </xsl:text>
                                <xsl:value-of select="@type" />
                                <xsl:if test="@match">
                                    <br />
                                    <xsl:text>Match: </xsl:text>
                                    <xsl:value-of select="@match" />
                                </xsl:if>
                                <xsl:if test="@value">
                                    <br />
                                    <xsl:text>Value: </xsl:text>
                                    <xsl:value-of select="@value" />
                                </xsl:if>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="from">
        <li>
            <xsl:value-of select="@from" />
            <xsl:if test="@*[name() != 'from']">
                <ul>
                    <xsl:apply-templates select="@*[name() != 'from']" mode="list_line" />
                </ul>
            </xsl:if>
            <xsl:call-template name="comment-previous-info" />
        </li>
    </xsl:template>

    <xsl:template match="attribute" mode="list_line">
        <li>
            <xsl:value-of select="concat(
                    translate(substring(name(), 1, 1), $lowercase, $uppercase),
                    substring(name(), 2))" />
            <xsl:text>: </xsl:text>
            <xsl:value-of select="substring(@to, 2)" />
            <xsl:text>="</xsl:text>
            <xsl:value-of select="@default" />
            <xsl:text>"</xsl:text>
            <xsl:call-template name="comment-previous-info" />
        </li>
    </xsl:template>

    <xsl:template match="@*" mode="list_line">
        <li>
            <xsl:value-of select="concat(
                    translate(substring(name(), 1, 1), $lowercase, $uppercase),
                    substring(name(), 2))" />
            <xsl:text>: </xsl:text>
            <xsl:value-of select="." />
        </li>
    </xsl:template>

    <xsl:template match="@*" mode="list_definition">
        <dt>
            <xsl:value-of select="concat(
                    translate(substring(name(), 1, 1), $lowercase, $uppercase),
                    substring(name(), 2))" />
        </dt>
        <dd><xsl:value-of select="." /></dd>
    </xsl:template>

    <!-- =========================================================== -->
    <!--                      Special Functions                      -->
    <!-- =========================================================== -->

    <xsl:template name="from-to">
        <xsl:text>From </xsl:text>
        <strong><xsl:value-of select="from/@name" /></strong>
        <xsl:text> (namespace: </xsl:text>
        <a href="{from/@namespace}">
            <xsl:value-of select="from/@namespace" />
        </a>
        <xsl:text> [</xsl:text>
        <xsl:value-of select="from/@prefix" />
        <xsl:text>])</xsl:text>
        <br />
        <xsl:text>To </xsl:text>
        <xsl:choose>
            <xsl:when test="count(to) = 1">
                <strong><xsl:value-of select="to/@name" /></strong>
                <xsl:text> (namespace: </xsl:text>
                <a href="{to/@namespace}">
                    <xsl:value-of select="to/@namespace" />
                </a>
                <xsl:text> [</xsl:text>
                <xsl:value-of select="to/@prefix" />
                <xsl:text>]).</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <ul>
                    <xsl:for-each select="to">
                        <li>
                            <strong><xsl:value-of select="@name" /></strong>
                            <xsl:text> (namespace: </xsl:text>
                            <a href="{@namespace}">
                                <xsl:value-of select="@namespace" />
                            </a>
                            <xsl:text> [</xsl:text>
                            <xsl:value-of select="@prefix" />
                            <xsl:text>]).</xsl:text>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="mapping-link">
        <xsl:param name="name" />
        <xsl:param name="text" select="''" />

        <xsl:variable name="mapping"
            select="/mappings/mapping[@name = $name]" />

        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:if test="name(/*) != 'mappings'">
                    <xsl:value-of select="$file-mappings" />
               </xsl:if>
               <xsl:text>#mapping-</xsl:text>
               <xsl:value-of select="translate($name, $forbidden_characters, '')" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="$name" />
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="$text != ''">
                    <xsl:value-of select="$text" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$name" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- Display a note for the previous comment, if any. -->
    <xsl:template name="comment-previous-note">
        <xsl:param name="node" select="." />

        <xsl:variable name="presentation">
            <xsl:call-template name="comment-previous" />
        </xsl:variable>

        <xsl:if test="normalize-space(string($presentation))">
            <p><span class="glyphicon glyphicon-chevron-right" />
                <xsl:copy-of select="string($presentation)" />
            </p>
        </xsl:if>
    </xsl:template>

    <!-- Display a small note for the previous comment, if any. -->
    <xsl:template name="comment-previous-info">
        <xsl:param name="node" select="." />

        <xsl:variable name="presentation">
            <xsl:call-template name="comment-previous" />
        </xsl:variable>

        <xsl:if test="normalize-space(string($presentation))">
            <p><span class="glyphicon glyphicon-arrow-right" />
                <xsl:copy-of select="string($presentation)" />
            </p>
        </xsl:if>
    </xsl:template>

    <!-- Display a tooltip for the previous comment, if any. -->
    <xsl:template name="comment-previous-tooltip">
        <xsl:param name="node" select="." />

        <xsl:call-template name="tooltip">
            <xsl:with-param name="string">
                <xsl:call-template name="comment-previous">
                    <xsl:with-param name="node" select="$node" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- Get the first previous comment at same level, just before current one
    and not before another element. -->
    <xsl:template name="comment-previous">
        <xsl:param name="node" select="." />

        <xsl:variable name="comment"
            select="($node[1]/preceding-sibling::* | $node[1]/preceding-sibling::comment())[last()]/self::comment()" />

        <xsl:if test="normalize-space(string($comment))">
            <xsl:value-of select="string($comment)" />
        </xsl:if>
    </xsl:template>

    <!-- Display a tooltip for a string, if any. -->
    <xsl:template name="tooltip">
        <xsl:param name="string" select="." />

        <xsl:if test="normalize-space($string)">
            <xsl:text> </xsl:text>
            <a href="javascript://" data-toggle="tooltip" rel="popover">
                <xsl:attribute name="title" >
                    <xsl:value-of select="$string" />
                </xsl:attribute>
                <span class="glyphicon glyphicon-info-sign" />
            </a>
        </xsl:if>
    </xsl:template>

    <!-- Recursive replace each new line by a <br />. -->
    <xsl:template name="nl2br">
        <xsl:param name="string" />
        <xsl:choose>
            <xsl:when test="contains($string, '&#xA;')">
                <xsl:value-of select="substring-before($string, '&#xA;')" />
                <br />
                <xsl:text>&#xA;</xsl:text>
                <xsl:call-template name="nl2br">
                    <xsl:with-param name="string"
                        select="substring-after($string, '&#xA;')" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
