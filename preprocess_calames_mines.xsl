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

Cet outil est adapté aux documents des mines, qui est une simple liste de
documents (mémoires étudiants). Les sous-composants de ces documents sont de
simples descriptifs et toujours rattachés au document principal.

Concrètement :
- Seules les notices des documents présentant un champ EAD <processinfo> qui
contient le texte défini ci-dessous au niveau d'une cote (uniquement au premier
niveau ici) sont concernées par ce mapping et la conversion consécutive.
- Certaines valeurs sont simplifiées ou concaténées.
- Certaines valeurs sont initialisées (droits, type...).

Remarques :
- Un seul DSC
- Les composants de classement supérieurs sont supprimés, y compris les données
qu'ils contiennent (noms géographiques, dates...). A réinclure dans chaque
composant ?
- Pas de sous-cote (composant "cote" inclus dans un autre composant "cote").
- Les sous-composants ont été catalogués sous la forme d'un index avec des
numéros de pages (unitid), un titre (unittitle) et éventuellement une
description (scope content). Ils sont convertis en une table des matières en
texte brut ou sous la forme "arrangement / list / defitem", selon le paramètre
"format_liste".
- Les index ne reprennent pas les termes du composant principal ni des
composants de classement, mais uniquement ceux des sous-composants.
- Si on choisit le format "brut", ne pas normaliser les espaces dans ead2dcterms_config.xml.

@version 20160912
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

    <!-- Paramètres. -->

    <!--
    Texte du processinfo des composants à conserver.
    Remarques :
    - Seul le texte brut de processinfo est testé, sans espace de début ou de fin.
    - Le texte de processinfo peut contenir d'autre texte.
    -->
    <xsl:param name="processinfo_texte">
        <xsl:text>Document devant être numérisé en 2016 dans le cadre d'un partenariat avec la BnF</xsl:text>
    </xsl:param>

    <!-- Conversion en texte brut ou conservation des éléments ead ("ead", par
    défaut, ou "brut").
    L'utilisation du texte brut passe mieux en Dublin Core, mais s'éloigne du
    format original, qu'il n'est cependant pas possible d'afficher directement
    sur une page web en html sans une feuille css spécifique et qui n'est donc
    pas recommandé.
    -->
    <xsl:param name="format_liste">brut</xsl:param>

    <!-- Ajoute les identifiants de chaque composant, supprimé ou non ("true"
    ou "false"). De toute façon, ils sont supprimés lors de l'import Omeka.
    -->
    <xsl:param name="ajouter_commentaire">true</xsl:param>

    <!-- Constantes. -->

    <!-- Saut de ligne (standard Linux / Mac). -->
    <!-- Il est utilisé pour les commentaires, non indentés automatiquement. -->
    <xsl:variable name="end_of_line">
        <xsl:text>&#x0A;</xsl:text>
    </xsl:variable>

    <!-- Templates. -->

    <!-- Identity template. -->
    <xsl:template match="@*|node()" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Niveau de classement à supprimer (niveau supérieur sans cote). -->
    <xsl:template match="ead:archdesc/ead:dsc/ead:c
            [not(ead:did/ead:unitid/@type = 'cote')]
            ">
        <xsl:if test="$ajouter_commentaire = 'true'" >
            <xsl:value-of select="$end_of_line" />
            <xsl:comment> Niveau supprimé (<xsl:value-of select="@id" />) </xsl:comment>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$processinfo_texte = ''">
                <xsl:apply-templates select="ead:c" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="ead:c" mode="filtre" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Traitement avec filtre des composants.
    Ce template est séparé afin de l'adapter facilement pour d'autres critères.
    -->
    <xsl:template match="ead:c" mode="filtre">
        <xsl:choose>
            <xsl:when test="$processinfo_texte
                    and normalize-space(ead:processinfo)
                    and contains(normalize-space(ead:processinfo), $processinfo_texte)">
                <xsl:apply-templates select="." />
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$ajouter_commentaire = 'true'" >
                    <xsl:value-of select="$end_of_line" />
                    <xsl:comment> Document à ne pas traiter (<xsl:value-of select="@id" />) </xsl:comment>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Conservation des composants "cote", sachant qu'ils sont toujours au 2e
    niveau. -->
    <xsl:template match="ead:dsc/ead:c/ead:c
            [ead:did/ead:unitid/@type = 'cote']
            ">
        <xsl:if test="$ajouter_commentaire = 'true'" >
            <xsl:value-of select="$end_of_line" />
            <xsl:comment> Document numérisé (<xsl:value-of select="@id" />) </xsl:comment>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()[not(self::ead:c)]" />
            <!-- Intégration des sous-composants si présents. -->
            <xsl:if test="ead:c">
                <xsl:choose>
                    <xsl:when test="$format_liste = 'brut'">
                        <xsl:apply-templates select="." mode="brut" />
                    </xsl:when>
                    <!-- Le format par défaut est le format "ead". -->
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="ead" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- Format "ead" (conservation des éléments de l'EAD). -->

    <!-- Conservation des documents (1er niveau). -->
    <xsl:template match="ead:c" mode="ead">
        <!-- Création de la table des matières des sous-composants. -->
        <xsl:element name="arrangement" namespace="http://www.loc.gov/ead">
            <xsl:element name="list" namespace="http://www.loc.gov/ead">
                <xsl:attribute name="type">deflist</xsl:attribute>
                <xsl:apply-templates select="ead:c" mode="ead" />
            </xsl:element>
        </xsl:element>

        <!-- Création de l'index des sujets. -->
        <xsl:if test="descendant::ead:c
                //ead:subject">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Sujets</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:subject" mode="item" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des dates (hors unitdate et chronlist,
        qui sont repris ailleurs). -->
        <xsl:if test="descendant::ead:c
                //ead:date[not(parent::ead:chronitem)]">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Dates</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:date[not(parent::ead:chronitem)]" mode="item" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des lieux. -->
        <xsl:if test="descendant::ead:c
                //ead:geogname">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Lieux</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:geogname" mode="item" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des noms (personnes, organisations...). -->
        <xsl:if test="descendant::ead:c
            /descendant::element()
                    [self::ead:name
                    | self::ead:corpname
                    | self::ead:persname
                    | self::ead:famname
                    ]
               ">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Noms</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                /descendant::element()
                    [self::ead:name
                    | self::ead:corpname
                    | self::ead:persname
                    | self::ead:famname
                    ]" mode="item" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des langues ? -->
    </xsl:template>

    <!-- Transformation de chaque sous-composant en un élément d'index
    (récursif), sachant que les documents sont au 2e niveau et donc les sous-
    composants au 3e niveau. -->
    <xsl:template match="ead:c/ead:c/ead:c" mode="ead">
        <xsl:if test="$ajouter_commentaire = 'true'" >
            <xsl:value-of select="$end_of_line" />
            <xsl:comment> Partie (<xsl:value-of select="@id" />) </xsl:comment>
        </xsl:if>

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
                                ead:did/ead:unitdate/@*[not(self::ead:datechar | self::ead:label)]
                                | ead:did/ead:unitdate/node()" />
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
                <xsl:if test="node()[not(self::ead:c | self::ead:did | self::ead:scopecontent)]">
                    <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                        <xsl:apply-templates select="node()
                            [not(self::ead:c | self::ead:did | self::ead:scopecontent)]" />
                    </xsl:element>
                </xsl:if>
                <!-- Sous sous-composants. -->
                <xsl:if test="ead:c">
                    <xsl:element name="list" namespace="http://www.loc.gov/ead">
                        <xsl:attribute name="type">deflist</xsl:attribute>
                        <xsl:apply-templates select="ead:c" mode="ead" />
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

    <!-- Format "brut" (texte brut). -->

    <!-- Conservation des documents (1er niveau). -->
    <xsl:template match="ead:c" mode="brut">
        <!-- Création de la table des matières des sous-composants. -->
        <xsl:element name="arrangement" namespace="http://www.loc.gov/ead">
            <xsl:apply-templates select="ead:c" mode="brut" />
        </xsl:element>

        <!-- Création de l'index des sujets. -->
        <xsl:if test="descendant::ead:c
                //ead:subject">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Sujets</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:subject" mode="item_brut" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des dates (hors unitdate et chronlist,
        qui sont repris ailleurs). -->
        <xsl:if test="descendant::ead:c
                //ead:date[not(parent::ead:chronitem)]">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Dates</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:date[not(parent::ead:chronitem)]" mode="item_brut" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des lieux. -->
        <xsl:if test="descendant::ead:c
                //ead:geogname">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Lieux</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                            //ead:geogname" mode="item_brut" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des noms (personnes, organisations...). -->
        <xsl:if test="descendant::ead:c
            /descendant::element()
                    [self::ead:name
                    | self::ead:corpname
                    | self::ead:persname
                    | self::ead:famname
                    ]
               ">
            <xsl:element name="odd" namespace="http://www.loc.gov/ead">
                <xsl:element name="list" namespace="http://www.loc.gov/ead">
                    <xsl:attribute name="type">simple</xsl:attribute>
                    <xsl:element name="head" namespace="http://www.loc.gov/ead">Noms</xsl:element>
                    <xsl:apply-templates select="descendant::ead:c
                /descendant::element()
                    [self::ead:name
                    | self::ead:corpname
                    | self::ead:persname
                    | self::ead:famname
                    ]" mode="item_brut" />
                </xsl:element>
            </xsl:element>
        </xsl:if>

        <!-- Création de l'index des langues ? -->
    </xsl:template>

    <!-- Transformation de chaque sous-composant en un élément d'index
    (récursif), sachant que les documents sont au 2e niveau et donc les sous-
    composants au 3e niveau. -->
    <xsl:template match="ead:c/ead:c/ead:c" mode="brut">
        <xsl:if test="$ajouter_commentaire = 'true'" >
            <xsl:value-of select="$end_of_line" />
            <xsl:comment> Partie (<xsl:value-of select="@id" />) </xsl:comment>
        </xsl:if>

        <!-- Copie du titre et du numéro de page et des description, dates et
        autres éléments éventuels. -->
        <xsl:value-of select="$end_of_line" />
        <xsl:value-of select="substring('***************************', 1, number(my:niveau_composant(.)))" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="ead:did/ead:unitid" />
        <xsl:value-of select="$end_of_line" />
        <xsl:value-of select="ead:did/ead:unittitle" />
        <xsl:value-of select="$end_of_line" />
        <xsl:if test="ead:did/ead:unitdate">
            <xsl:text>  Date</xsl:text>
            <xsl:value-of select="$end_of_line" />
            <xsl:apply-templates select="
                ead:did/ead:unitdate/@*[not(self::ead:datechar | self::ead:label)]
                | ead:did/ead:unitdate/node()" />
        </xsl:if>
        <xsl:if test="ead:scopecontent">
            <xsl:value-of select="ead:scopecontent" />
            <xsl:value-of select="$end_of_line" />
        </xsl:if>
        <!-- Autres éléments. -->
        <xsl:if test="node()[not(self::ead:c | self::ead:did | self::ead:scopecontent)]">
            <xsl:apply-templates select="node()
                [not(self::ead:c | self::ead:did | self::ead:scopecontent)]" />
        </xsl:if>
        <!-- Sous sous-composants. -->
        <xsl:if test="ead:c">
            <xsl:text>  * </xsl:text>
            <xsl:apply-templates select="ead:c" mode="brut" />
        </xsl:if>
    </xsl:template>

    <!-- Transformation d'un élément en un élément d'index. -->
    <xsl:template match="node()" mode="item_brut">
        <xsl:text>  </xsl:text>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Fonctions -->
    <xsl:function name="my:niveau_composant" as="xs:string">
        <xsl:param name="base" />
        <xsl:value-of select="count($base/ancestor::ead:*) - 4" />
    </xsl:function>

</xsl:stylesheet>
