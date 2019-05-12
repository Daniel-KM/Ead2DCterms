EAD to Dublin Core Metadata Terms
=================================

[ead2dcterms] is a standalone tool to convert XML metadata of a finding aid in
[EAD] to a list of records in [Dublin Core] terms.

[EAD] is an xml format designed to describe collections of archives in a
structural way: the collection, the boxes, the folders, the pieces, the papers,
the pages, etc., so the user can find easily what he/she wants. It can be filled
only by a specialist with a special application. The format contains not only
metadata, but semantic and textual content, so it can be printed or displayed in
a browser directly with a simple stylesheet.

[Dublin Core] and its revision "DCMI Metadata Terms" is a format designed to
describe any document, any object, and anything else. This is a simple and flat
format, so anybody can use and read it. It manages metadata firstly, not textual
content.

If an [official mapping] was established for EAD 1.0 and Dublin Core, none has
been approved for EAD 2002 and Dublin Core Metadata Terms. So, this app is not
only a tool to convert metadata, but a mapping table too.

This tool is integrated in [Omeka Classic] and [Omeka S], an open source
platform for publishing collections online, via the plugins [Ead] and
[Archive Folder] and the [module EAD].


Xslt mapper
-----------

The conversion uses a simple [XSLT] stylesheet either in version 1 or version 2
(recommended, because it's simpler and about ten to twenty faster). XSLT is the
functional language designed to process XML files, and is managed by the [W3C].

The mapper is built around a dynamic xpath evaluator, so the conversion process
is  completely separated from the mapping itself. By this way, the mapping is a
simple xml file that anybody can modify quickly and easily, without change in
the engine.

The engine has been checked against the two official examples of the EAD model
and some other ones, but because interpretations of the format may differ
between people, in particular between archivists and librarians, it should be
adapted if the configuration is not enough.

Important: The xslt 1 version works only with some extensions, not with a parser
that follows strictly the standard. The extension should add the possibility to
interpret a tree fragment as a node set.


Mapping table
-------------

The mapping is done between the EAD 2002 and the full list of Dublin Core
(formerly "qualified", "extended" or "refined"). It can be downgraded to the 15
basic terms with the provided stylesheet. For EAD metadata formatted with a
previous standard, an upgrade to EAD 2002 should be done before with the
official stylesheets.

Globally, an EAD finding aid is converted into multiple Dublin Core records:
- one, two (default) or three records for main informations of the finding aid
  (header, front matter and archival description);
- possible records for the main description of Subordinate Components), mainly
  to simplify grouping;
- records for each component (level) and item;
- related records for each digital archival object (dao, daoloc, pointers...).

Records are linked to other ones with the terms that define a relation.

Generally, textual contents are mapped with the term "description" and other
data are mapped with the matching Dublin Core term.

The output format is a simple and flat xml file that can be used by any other
process.

The mapping takes some ideas from other open source converters built by:

- Scholars' Lab at the University of Virginia Library, for the [Ead Importer],
  designed to import finding aids in [Omeka], an open source digital library;
- [Anaphore], for another tool used by the open source digital library [Pleade].

These tools work fine. The main issues of them are that they are designed for
the integration with another tool, the lack of documentation about the mapping,
the partial coverage and the non-reversibility of the elements, and the mixture
of the code and the mapping, making them heavy to maintain and hard to adapt to
multiple interpretations of the EAD format.


Configuration
-------------

Because the two formats are very different (document vs data oriented), because
there is no more official mapping between them, and because there are lot of
interpretation of the EAD format, two xml files are used to parameter the
conversion and to adapt it to needs.

The main one is [ead2dcterms_mappings.xml]. It describes each couple of
metadata, for example that the EAD element "unittitle" is mapped to the
Dublin Core  term "title". Multiple mappings are prepared for some elements,
mostly identifiers and relations, because there are a lot of possibilities.

The second one, [ead2dcterms_config.xml], describes how the mappings are mixed
together to build each record.

This couple of xml files allows to manage any interpretation or use of EAD by a
simple change. Anyway, any conversion should be checked.

See them for further details and current limits. They can be displayed as xml
with any text editor, or as a table via a browser (simply download the tool and
open the same files with your prefered browser).

Any xslt parser can be used. If you haven't one, you can use the open source
[jEdit] with the plugins "Xslt", "Saxon", "Xml" and "XQuery". It is available on
any operating system (Linux, Mac or Windows). When installed, select "Plugins" >
"plugins options" > "Xslt" and set "Saxon 9" as xslt processor and xpath engine.
To process an xml file, select "Plugins" > "Xslt" > "Activate 3-Way Mode", then
select the xml file as source, the file "ead2dcterms.xsl" as stylesheet, and a
new untitled buffer as result. Finally, click the button "Transform Xml".


Notes
-----

* Use of official examples

Official examples of EAD 2002 are provided for tests, but they may not be xml
compliant with current parsers. So they are provided without the doctype and the
entities and with the namespace too.

* Integration in Omeka

In [Omeka], the items are the base records and an item can contain multiple
files. In EAD, the file is a true object and the base record, and can contain
multiple items. The plugin [Ead4Omeka] takes care of this point.

* XSLT 1 version

The xslt 1 version works only with some extensions, not with a parser that
follows strictly the standard. The parser should be able to interpret a tree
fragment as a node set.


Warning
-------

Use it at your own risk.

It’s always recommended to backup your files and your databases and to check
your archives regularly so you can roll back if needed.


Troubleshooting
---------------

See online issues on the [page of issues] on GitHub.


License
-------

This module is published under the [CeCILL v2.1] licence, compatible with
[GNU/GPL] and approved by [FSF] and [OSI].

This software is governed by the CeCILL license under French law and abiding by
the rules of distribution of free software. You can use, modify and/ or
redistribute the software under the terms of the CeCILL license as circulated by
CEA, CNRS and INRIA at the following URL "http://www.cecill.info".

As a counterpart to the access to the source code and rights to copy, modify and
redistribute granted by the license, users are provided only with a limited
warranty and the software’s author, the holder of the economic rights, and the
successive licensors have only limited liability.

In this respect, the user’s attention is drawn to the risks associated with
loading, using, modifying and/or developing or reproducing the software by the
user in light of its specific status of free software, that may mean that it is
complicated to manipulate, and that also therefore means that it is reserved for
developers and experienced professionals having in-depth computer knowledge.
Users are therefore encouraged to load and test the software’s suitability as
regards their requirements in conditions enabling the security of their systems
and/or data to be ensured and, more generally, to use and operate it in the same
conditions as regards security.

The fact that you are presently reading this means that you have had knowledge
of the CeCILL license and that you accept its terms.


Contact
-------

Current maintainers:

* Daniel Berthereau (see [Daniel-KM] on GitHub)


Copyright
---------

* Copyright Daniel Berthereau, 2015-2019


[Ead2DCterms]: https://github.com/Daniel-KM/Ead2DCterms
[EAD]: https://loc.gov/ead
[Dublin Core]: http://dublincore.org
[Omeka Classic]: https://omeka.org/classic
[Omeka S]: https://omeka.org/s
[Ead]: https://github.com/Daniel-KM/Omeka-plugin-Ead
[Archive Folder]: https://github.com/Daniel-KM/Omeka-plugin-ArchiveFolder
[module EAD]: https://github.com/Daniel-KM/Omeka-S-module-Ead
[XSLT]: https://www.w3.org/standards/xml/transformation
[W3C]: https://www.w3.org/
[official mapping]: http://www.loc.gov/ead/ag/agappb.html#sec3
[Anaphore]: https://github.com/Anaphore/joai_xsl
[Pleade]: http://www.pleade.com
[Ead Importer]: https://github.com/scholarslab/EadImporter
[ead2dcterms_config.xml]: https://github.com/Daniel-KM/Ead2DCterms_config.xml
[ead2dcterms_mappings.xml]: https://github.com/Daniel-KM/Ead2DCterms_mappings.xml
[jEdit]: http://www.jedit.org
[page of issues]: https://github.com/Daniel-KM/Ead2DCterms/issues
[CeCILL v2.1]: https://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html
[GNU/GPL]: https://www.gnu.org/licenses/gpl-3.0.html
[FSF]: https://www.fsf.org
[OSI]: http://opensource.org
[Daniel-KM]: https://github.com/Daniel-KM "Daniel Berthereau"
