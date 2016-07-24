<?xml version="1.0" encoding="UTF-8"?>
<!--
Supprime les notices et métadonnées inutiles d'un fichier Calames, avant import
dans Omeka.

Le but consiste à :
- importer uniquement les notices des documents numérisés, pas les autres, ni la
hiérarchie ;
- rassembler les sous-composants d'un composant "cote" dans la description ;
- récupérer le maximum de données des sous-composants dans des index (sujets,
dates, lieux, noms).

Le but n'est de faire un import inversable : certaines données sont perdues lors
de la conversion.

Remarques :
- Un seul DSC
- Les composants de classement supérieurs sont supprimés, y compris les données
qu'ils contiennent (noms géographiques, dates...). A réinclure dans chaque
composant ?
- Pas de sous-cote (composant "cote" inclus dans un autre composant "cote").
- Les sous-composants ont été catalogués sous la forme d'un index avec des
numéros de pages (unitid), un titre (unittitle) et éventuellement une
description (scope content). Ils sont convertis en une table des matières sous
la forme "arrangement / list / defitem".
- Les index ne reprennent pas les termes du composant principal ni des
composants de classement, mais uniquement ceux des sous-composants.

@version 20160728
@copyright Daniel Berthereau, 2016, pour Mines ParisTech
@license CeCILL v2.1 http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:my="http://localhost/my"
    xmlns:ead="http://www.loc.gov/ead"

    exclude-result-prefixes="xsl xs my">

    <xsl:output
        omit-xml-declaration="no"
        encoding="UTF-8"
        indent="yes" />

    <xsl:strip-space elements="*" />

    <!-- Templates. -->

    <!-- Identity template. -->
    <xsl:template match="@*|node()" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Niveau de classement à supprimer (niveau supérieur). -->
    <xsl:template match="ead:archdesc/ead:dsc/ead:c[ead:did/ead:unitid/@type != 'cote']">
        <xsl:comment> Niveau supprimé (<xsl:value-of select="@id" />) </xsl:comment>
        <xsl:apply-templates select="ead:c" />
    </xsl:template>

    <!-- Conservation des composants "cote". -->
    <xsl:template match="ead:c[ead:did/ead:unitid/@type = 'cote']">
        <xsl:comment> Document numérisé (<xsl:value-of select="@id" />) </xsl:comment>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()[not(self::ead:c)]" />

            <!-- Intégration des sous-composants. -->
            <xsl:if test="ead:c">

                <!-- Création de la table des matières des sous-composants. -->
                <xsl:element name="arrangement" namespace="http://www.loc.gov/ead">
                    <xsl:element name="list" namespace="http://www.loc.gov/ead">
                        <xsl:attribute name="type">deflist</xsl:attribute>
                        <xsl:apply-templates select="ead:c" />
                    </xsl:element>
                </xsl:element>

                <!-- Création de l'index des sujets. -->
                <xsl:if test="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                        //ead:subject">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:element name="list" namespace="http://www.loc.gov/ead">
                            <xsl:attribute name="type">simple</xsl:attribute>
                            <xsl:element name="head" namespace="http://www.loc.gov/ead">Sujets</xsl:element>
                            <xsl:apply-templates select="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                                    //ead:subject" mode="item" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <!-- Création de l'index des dates (hors unitdate et chronlist,
                qui sont repris ailleurs). -->
                <xsl:if test="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                        //ead:date[not(parent::ead:chronitem)]">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:element name="list" namespace="http://www.loc.gov/ead">
                            <xsl:attribute name="type">simple</xsl:attribute>
                            <xsl:element name="head" namespace="http://www.loc.gov/ead">Dates</xsl:element>
                            <xsl:apply-templates select="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                                    //ead:date[not(parent::ead:chronitem)]" mode="item" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <!-- Création de l'index des lieux. -->
                <xsl:if test="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                        //ead:geogname">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:element name="list" namespace="http://www.loc.gov/ead">
                            <xsl:attribute name="type">simple</xsl:attribute>
                            <xsl:element name="head" namespace="http://www.loc.gov/ead">Lieux</xsl:element>
                            <xsl:apply-templates select="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                                    //ead:geogname" mode="item" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <!-- Création de l'index des noms (personnes, organisations...). -->
                <xsl:if test="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                    /descendant::element()
                            [self::ead:name
                            |self::ead:corpname
                            |self::ead:persname
                            |self::ead:famname
                            ]
                       ">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:element name="list" namespace="http://www.loc.gov/ead">
                            <xsl:attribute name="type">simple</xsl:attribute>
                            <xsl:element name="head" namespace="http://www.loc.gov/ead">Noms</xsl:element>
                            <xsl:apply-templates select="descendant::ead:c[ead:did/ead:unitid/@type != 'cote']
                        /descendant::element()
                            [self::ead:name
                            |self::ead:corpname
                            |self::ead:persname
                            |self::ead:famname
                            ]" mode="item" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <!-- Création de l'index des langues ? -->

            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- Transformation de chaque sous-composant en un élément d'index
    (récursif). -->
    <xsl:template match="ead:c/ead:c[ead:did/ead:unitid/@type != 'cote']">
        <xsl:comment> Partie (<xsl:value-of select="@id" />) </xsl:comment>

        <!-- Copie du titre et du numéro de page et des description, dates et
        autres éléments éventuels. -->
        <xsl:element name="defitem" namespace="http://www.loc.gov/ead">
            <xsl:element name="label" namespace="http://www.loc.gov/ead">
                <xsl:value-of select="ead:did/ead:unitid" />
            </xsl:element>
            <xsl:element name="item" namespace="http://www.loc.gov/ead">
                <xsl:value-of select="ead:did/ead:unittitle" />
                <xsl:if test="ead:did/ead:unitdate">
                    <xsl:element name="p" namespace="http://www.loc.gov/ead">
                        <xsl:element name="date" namespace="http://www.loc.gov/ead">
                            <xsl:apply-templates select="
                                ead:did/ead:unitdate/@*[not(self::ead:datechar|self::ead:label)]
                                |ead:did/ead:unitdate/node()" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="ead:scopecontent">
                    <xsl:element name="p" namespace="http://www.loc.gov/ead">
                        <xsl:element name="emph" namespace="http://www.loc.gov/ead">
                            <xsl:value-of select="ead:scopecontent" />
                        </xsl:element>
                    </xsl:element>
                </xsl:if>
                <!-- Autres éléments. -->
                <xsl:if test="node()[not(self::ead:c|self::ead:did|self::ead:scopecontent)]">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:apply-templates select="node()[not(self::ead:c|self::ead:did|self::ead:scopecontent)]" />
                    </xsl:element>
                </xsl:if>
                <!-- Sous sous-composants. -->
                <xsl:if test="ead:c">
                    <xsl:element name="list" namespace="http://www.loc.gov/ead">
                        <xsl:attribute name="type">deflist</xsl:attribute>
                        <xsl:apply-templates select="ead:c" />
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- Transformation d'un élément en un élément d'index. -->
    <xsl:template match="node()" mode="item">
        <xsl:element name="item" namespace="http://www.loc.gov/ead">
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" />
            </xsl:copy>
        </xsl:element>
    </xsl:template>

    <!-- Fonctions -->

</xsl:stylesheet>
