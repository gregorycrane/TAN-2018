<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">

    <!-- Input: a class 1 file or a non-TAN XML file -->
    <!-- Template: a TAN-T (not TAN-TEI) -->
    <!-- Output: the text content of the input file proportionally divided up as the new content of the template -->

    <!-- If the input is not TAN, then there is no way for the algorithm to figure out what the correct metadata is for the output file. Errors are likely. -->


    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:output indent="yes"/>

    <!-- PARAMETERS YOU WILL WANT TO CHANGE MOST OFTEN -->
    <!-- provide the idrefs of div-types you want to delete or preserve, space delimiter -->
    <xsl:param name="delete-what-input-div-types" select="''" as="xs:string?"/>
    <xsl:param name="preserve-what-input-div-types" select="'ti'" as="xs:string?"/>

    <xsl:param name="stop-modelling-at-what-level" as="xs:integer?" select="3"/>

    <!-- A wrapper is useful when you want to subdivide by hand -->
    <xsl:param name="last-level-as-wrapper-only" as="xs:boolean" select="false()"/>

    <!-- If you're starting afresh the next parameter should be false. If you have a text that already matches the model only at its upper levels of the hierarchy, it should be true. -->
    <xsl:param name="preserve-input-div-structures-that-already-match-the-model" as="xs:boolean"
        select="false()"/>

    <!-- If you want to customize the way sentences, clauses, and words are defined, use the following variables -->
    <xsl:param name="sentence-end-regex" select="'[\.;\?!]+\p{P}*\s*'"/>
    <!--<xsl:param name="clause-end-regex" select="'\w\p{P}+\s*'"/>-->
    <!--<xsl:param name="word-end-regex" select="'\s+'"/>-->
    <xsl:param name="if-model-uses-object-refs-allow-breaks-only-where-regex" as="xs:string"
        select="$word-end-regex"/>
    <!-- In the following, you might want to use $clause-end-regex -->
    <xsl:param name="if-model-uses-semantic-refs-allow-breaks-only-where-regex" as="xs:string"
        select="$sentence-end-regex"/>

    <!-- In this conversion, the model and the template are identical -->
    <xsl:param name="template-url-relative-to-input" as="xs:string?"
        select="'ar.cat.grc.1949.minio-paluello.sem-native.xml'"/>




    <!-- THIS STYLESHEET -->

    <xsl:param name="stylesheet-iri" select="'tag:textalign.net,2015:stylesheet:remodel-via-tan-t'"/>
    <xsl:param name="change-message">
        <xsl:text>Input from </xsl:text>
        <xsl:value-of select="base-uri(/)"/>
        <xsl:text> proporitionally inserted into template at </xsl:text>
        <xsl:value-of select="$template-url-resolved"/>
    </xsl:param>



    <!-- INPUT -->
    <xsl:variable name="div-types-to-delete" select="tokenize($delete-what-input-div-types, '\s+')"/>
    <xsl:variable name="div-types-to-ignore"
        select="tokenize($preserve-what-input-div-types, '\s+')"/>

    <xsl:variable name="input-namespace-prefix" select="tan:namespace($input-namespace)"/>
    <xsl:variable name="input-namespace" select="tan:namespace(/*)"/>
    <xsl:variable name="input-precheck" as="document-node()?">
        <xsl:choose>
            <xsl:when test="$doc-class = 1">
                <xsl:sequence select="/"/>
            </xsl:when>
            <xsl:when test="not(tan:namespace($input-namespace) = ('tan', 'tei'))">
                <xsl:message
                    select="concat('Processing input in namespace ', $input-namespace-prefix)"/>
                <xsl:document>
                    <TAN-T>
                        <head>
                            <xsl:comment>metadata needs to be filled in by hand</xsl:comment>
                            <definitions/>
                        </head>
                        <body>
                            <xsl:value-of select="normalize-space(string-join(//text(), ''))"/>
                        </body>
                    </TAN-T>
                </xsl:document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat('Input at ', base-uri(/), ' is unexpected')"
                    terminate="yes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:param name="input-items" select="$input-precheck"/>
    <xsl:variable name="input-expanded"
        select="tan:expand-doc(tan:resolve-doc($input-items), 'terse')"/>
    <xsl:param name="input-base-uri" select="base-uri(/)"/>

    <!-- PASS 1 -->
    <!-- revise the input's header; if some divs should be dropped, do so -->
    <xsl:variable name="some-text-has-been-cut"
        select="exists($input-precheck//tan:div[@type = $div-types-to-delete])" as="xs:boolean"/>
    <xsl:variable name="new-see-alsos" as="element()*">
        <see-also relationship="model">
            <IRI>
                <xsl:value-of select="$template-doc/tan:TAN-T/@id"/>
            </IRI>
            <xsl:copy-of select="$template-doc/tan:TAN-T/tan:head/tan:name"/>
            <location href="{tan:uri-relative-to($template-url-resolved, $input-base-uri)}"
                when-accessed="{current-date()}"/>
        </see-also>
        <xsl:if test="$some-text-has-been-cut = false()">
            <see-also relationship="ade">
                <IRI>
                    <xsl:value-of select="root()/*/@id"/>
                </IRI>
                <xsl:copy-of select="root()/*/tan:head/tan:name"/>
                <location href="{replace($input-base-uri, '.+/([^/]+)$','$1')}"
                    when-accessed="{current-date()}"/>
            </see-also>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="this-relationship" as="element()*">
        <xsl:if test="not(exists(/*/tan:head/tan:definitions/tan:relationship[@which = 'model']))">
            <relationship xml:id="model" which="model"/>
        </xsl:if>
        <xsl:if
            test="($some-text-has-been-cut = false()) and not(exists(/*/tan:head/tan:definitions/tan:relationship[@which = 'resegmented copy']))">
            <relationship xml:id="ade" which="resegmented copy"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="input-relationships"
        select="$self-resolved/*/tan:head/tan:definitions/tan:relationship"/>
    <xsl:variable name="input-relationship-model"
        select="$input-relationships[tan:IRI = $relationship-model/tan:IRI]"/>

    <xsl:template match="tan:see-also[1]" mode="input-pass-1">
        <xsl:copy-of select="$new-see-alsos"/>
        <xsl:if test="not(tan:definition(@relationship)/@which = 'model')">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:see-also[position() gt 1]" mode="input-pass-1">
        <xsl:if test="not(tan:definition(@relationship)/@which = 'model')">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:definitions" mode="input-pass-1">
        <xsl:if test="not(exists(../tan:see-also))">
            <xsl:copy-of select="$new-see-alsos"/>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$template-doc/tan:TAN-T/tan:head/tan:definitions/tan:div-type"/>
            <xsl:apply-templates select="node() except tan:div-type" mode="#current"/>
            <xsl:if test="not(exists(tan:relationship))">
                <xsl:copy-of select="$this-relationship"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:relationship[1]" mode="input-pass-1">
        <xsl:copy-of select="$this-relationship"/>
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="tan:div" mode="input-pass-1">
        <xsl:if test="not(@type = $div-types-to-delete)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <!-- PASS 2 -->
    <!-- real work happens first in the model/template or the median template. It then gets tucked into the input document at this pass -->
    <xsl:template match="*:body" mode="input-pass-2">
        <xsl:choose>
            <xsl:when test="exists($median-template-doc-resolved)">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of
                        select="tan:copy-of-except($input-and-median-merge-reconstructed, (), ('string-length', 'string-pos'), ())"
                    />
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$preserve-input-div-structures-that-already-match-the-model">
                <xsl:apply-templates select="." mode="input-pass-2b">
                    <xsl:with-param name="model-children-divs"
                        select="$template-doc/tan:TAN-T/tan:body/tan:div"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of
                        select="tan:div-to-div-transfer(., $template-doc/tan:TAN-T/tan:body, $break-at-regex)/*"
                    />
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    <xsl:template match="*" mode="input-pass-2b">
        <xsl:param name="model-children-divs" as="element()*"/>
        <xsl:variable name="these-input-children" select="*:div"/>
        <xsl:variable name="children-that-dont-match-the-model"
            select="*:div[not(@n = $model-children-divs/@n)][not(@type = $preserve-what-input-div-types)]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="not(exists($model-children-divs))">
                    <xsl:value-of select="tan:text-join(.)"/>
                </xsl:when>
                <xsl:when
                    test="not(exists($these-input-children)) or exists($children-that-dont-match-the-model)">
                    <xsl:copy-of select="tan:div-to-div-transfer(., $model-children-divs, $break-at-regex)"/>
                </xsl:when>
                <xsl:when
                    test="
                        every $i in $these-input-children[not(@type = $div-types-to-ignore)]/@n
                            satisfies $model-children-divs/@n">
                    <xsl:for-each select="$these-input-children">
                        <xsl:variable name="this-n" select="@n"/>
                        <xsl:choose>
                            <xsl:when test="@type = $div-types-to-ignore">
                                <xsl:copy-of select="."/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="." mode="#current">
                                    <xsl:with-param name="model-children-divs"
                                        select="$model-children-divs[@n = $this-n]/tan:div"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>

                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>some condition has not been anticipated</xsl:message>
                    <xsl:message select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>


    </xsl:template>


    <!-- PASS 3 -->
    <!-- Roll back to a certain depth, if so requested -->
    <xsl:template match="*:div" mode="input-pass-3">
        <xsl:variable name="this-level" select="count(ancestor-or-self::tan:div)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="not(exists($stop-modelling-at-what-level))">
                    <xsl:apply-templates mode="#current"/>
                </xsl:when>
                <xsl:when
                    test="
                        ($this-level + 1 = $stop-modelling-at-what-level)
                        and ($last-level-as-wrapper-only = true())
                        and exists(tan:div)">
                    <div>
                        <xsl:copy-of select="tan:div[1]/@*"/>
                        <xsl:value-of select="tan:text-join(.)"/>
                    </div>
                </xsl:when>
                <xsl:when test="$this-level lt $stop-modelling-at-what-level">
                    <xsl:apply-templates mode="#current"/>
                </xsl:when>
                <xsl:when test="$this-level = $stop-modelling-at-what-level">
                    <xsl:value-of select="tan:text-join(.)"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


    <!-- MEDIAN TEMPLATE -->
    <!-- Suppose we have text A in segmentation system 1 that we want to convert to segment system 2 in text B. That is, we wish to get A2. The problem is that if A is a translation of B, the allocation of the parts could be matematically even but semantically uneven (a translator can fluctuate from verbose to terse). -->
    <!-- Suppose now there also is an identical version of B in system 1 (B1 is the model to A1 and B1 is a resegmented copy of B2.). We can use B1 to control more precisely how A1 gets allocated to B2. We approach the problem in a manner that might be unintuitive: -->
    <!-- Take B1, the median template, and spike it with shallowly copied <div>s from B2 (using tan:tree-to-sequence(). -->
    <!-- For each revised leaf div in B1, take the corresponding text from A1 and let that text proportionally replace the text around the spiked <div>s of B2. -->
    <!-- Remove the skeletal structure of B1, leaving a sequence of text nodes and elements -->
    <!-- Rebuild the hierarchy of B2 via tan:sequence-to-tree() -->

    <xsl:variable name="median-template-search-1"
        select="$self-resolved/*/tan:head/tan:see-also[@relationship = $input-relationship-model/@xml:id]"/>
    <xsl:variable name="median-template-search-2"
        select="$template-resolved/tan:TAN-T/tan:head/tan:see-also[@relationship = $template-relationship-resegmented-copy/@xml:id]"/>
    <xsl:variable name="median-template-doc-resolved" as="document-node()?"
        select="
            if ($median-template-search-1/tan:IRI = $median-template-search-2/tan:IRI) then
                $see-alsos-resolved[*/@id = $median-template-search-1/tan:IRI]
            else
                ()"/>
    <xsl:variable name="median-template-doc-expanded"
        select="tan:expand-doc($median-template-doc-resolved, 'terse')"/>
    <xsl:variable name="median-template-doc-analyzed"
        select="tan:analyze-string-length($median-template-doc-expanded)"/>
    <xsl:variable name="template-div-spikes"
        select="tan:tree-to-sequence($template-body-analyzed/*)/self::*"/>

    <xsl:variable name="input-body-with-unique-ns" as="element()?">
        <xsl:apply-templates select="$input-expanded/tan:TAN-T/tan:body" mode="unique-ns"/>
    </xsl:variable>
    <xsl:variable name="median-body-with-unique-ns" as="element()?">
        <xsl:apply-templates select="$median-template-doc-analyzed/tan:TAN-T/tan:body"
            mode="unique-ns"/>
    </xsl:variable>

    <xsl:template match="*" mode="unique-ns">
        <xsl:param name="new-n" as="xs:string?"/>
        <xsl:variable name="this-n" select="@n"/>
        <xsl:variable name="all-ns" select="*/@n"/>
        <xsl:variable name="duplicate-children-n" select="tan:duplicate-items($all-ns)"/>
        <xsl:variable name="previous-siblings-with-this-n"
            select="preceding-sibling::*[@n = $this-n]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if
                test="(string-length($new-n) gt 0) and exists($this-n) and exists($previous-siblings-with-this-n)">
                <xsl:attribute name="orig-n" select="$this-n"/>
                <xsl:attribute name="n"
                    select="concat(@n, '-', string(count($previous-siblings-with-this-n)), $new-n)"
                />
            </xsl:if>
            <xsl:choose>
                <xsl:when test="exists($duplicate-children-n)">
                    <xsl:variable name="disambiguating-char" select="tan:unique-char($all-ns)"/>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="new-n" select="$disambiguating-char"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:variable name="input-and-median-merge" as="item()*">
        <xsl:apply-templates select="$median-body-with-unique-ns" mode="median-template-merge">
            <xsl:with-param name="input-div-children" select="$input-body-with-unique-ns/tan:div"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="input-and-median-merge-reconstructed"
        select="tan:sequence-to-tree($input-and-median-merge)"/>

    <xsl:template match="text()" mode="median-template-merge"/>
    <xsl:template match="tan:body | tan:div[tan:div]" mode="median-template-merge">
        <xsl:param name="input-div-children" as="element()*"/>
        <xsl:variable name="median-div-children" select="tan:div"/>
        <xsl:choose>
            <xsl:when test="count($input-div-children) lt 1"><!-- and count($input-tokens) lt 1 -->
                <!-- If there's no input, just carry on (spiking may occur downstream) -->
                <xsl:message>out of input</xsl:message>
                <xsl:apply-templates select="tan:div" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="this-n-sequence"
                    select="tan:collate-sequences($median-div-children/@n, $input-div-children/@n)"/>
                <xsl:for-each select="$this-n-sequence">
                    <xsl:variable name="this-n" select="."/>
                    <xsl:variable name="this-input-div" select="$input-div-children[@n = $this-n]"/>
                    <xsl:variable name="this-median-div" select="$median-div-children[@n = $this-n]"/>
                    <xsl:choose>
                        <xsl:when test="not(exists($this-median-div))">
                            <xsl:message select="'input has a div lacking in the median template'"/>
                            <xsl:message select="$this-input-div"/>
                            <xsl:value-of select="tan:text-join($this-input-div)"/>
                        </xsl:when>
                        <xsl:when
                            test="not(exists($this-input-div)) and (count($input-div-children) gt 0)">
                            <xsl:message
                                select="'median template has a div anomalously lacking in input'"/>
                            <xsl:message select="$this-median-div"/>
                            <xsl:apply-templates select="$this-median-div" mode="#current"/>
                        </xsl:when>
                        <xsl:when test="exists($this-input-div/tan:div)">
                            <!-- cases where the input has further descendants to process -->
                            <xsl:apply-templates select="$this-median-div" mode="#current">
                                <xsl:with-param name="input-div-children"
                                    select="$this-input-div/tan:div"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="exists($this-input-div)">
                            <!-- cases where the input div is a leaf div -->
                            <xsl:variable name="rest-of-median-infused" as="element()*" select="tan:div-to-div-transfer($this-input-div, $this-median-div, $word-end-regex)"/>
                            <xsl:apply-templates select="$this-median-div" mode="#current">
                                <xsl:with-param name="input-infused-median" select="$rest-of-median-infused" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$this-median-div" mode="#current"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:div[not(tan:div)]" mode="median-template-merge">
        <xsl:param name="input-div-children" as="element()*"/>
        <xsl:param name="input-tokens" as="xs:string*"/>
        <xsl:param name="input-infused-median" as="element()*" tunnel="yes"/>
        <xsl:variable name="this-q" select="@q"/>
        <xsl:variable name="this-infusion" select="$input-infused-median/descendant-or-self::tan:div[@q = $this-q]"/>
        <xsl:variable name="input-div-text" select="tan:text-join($input-div-children)"/>
        <xsl:variable name="replacement-text-tokenized"
            select="tan:chop-string(($this-infusion, $input-div-text)[1], $word-end-regex)"/>
        <xsl:variable name="number-of-replacement-tokens"
            select="count($replacement-text-tokenized)"/>

        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="this-string-start-pos" select="xs:integer(@string-pos)"/>
        <xsl:variable name="this-string-length" select="xs:integer(@string-length)"/>
        <xsl:variable name="next-string-start-pos"
            select="$this-string-start-pos + $this-string-length"/>
        <xsl:variable name="relevant-spikes"
            select="
                $template-div-spikes[(xs:integer(@string-pos) ge $this-string-start-pos)
                and (xs:integer(@string-pos) lt $next-string-start-pos)]"/>
        <xsl:variable name="every-spike-pos"
            select="
                for $i in $relevant-spikes
                return
                    xs:integer($i/@string-pos)"/>
        <xsl:variable name="every-pos"
            select="distinct-values(($this-string-start-pos, $every-spike-pos))"/>
        <xsl:choose>
            <xsl:when test="exists($every-spike-pos)">
                <xsl:for-each select="$every-pos">
                    <xsl:variable name="this-pos-position" select="position()"/>
                    <xsl:variable name="this-pos" select="."/>
                    <xsl:variable name="next-pos"
                        select="($every-pos[position() = ($this-pos-position + 1)], $next-string-start-pos)[1]"/>
                    <xsl:variable name="this-segment-length" select="$next-pos - $this-pos"/>
                    <xsl:variable name="token-seq-start-pos"
                        select="floor(($this-pos - $this-string-start-pos) div $this-string-length * $number-of-replacement-tokens) + 1"/>
                    <xsl:variable name="next-token-seq-start-pos"
                        select="floor(($next-pos - $this-string-start-pos) div $this-string-length * $number-of-replacement-tokens) + 1"/>
                    <xsl:copy-of
                        select="tan:copy-of-except($relevant-spikes[@string-pos = $this-pos], (), 'next-sibling-text-length', ())"/>
                    <xsl:value-of
                        select="string-join(subsequence($replacement-text-tokenized, $token-seq-start-pos, ($next-token-seq-start-pos - $token-seq-start-pos)), '')"
                    />
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="string-join($replacement-text-tokenized, '')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>




    <!-- TEMPLATE -->
    <xsl:variable name="template-body-analyzed" as="element()?">
        <xsl:choose>
            <xsl:when test="$template-doc/tan:TAN-T">
                <xsl:copy-of select="tan:analyze-string-length($template-doc/tan:TAN-T/tan:body)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                    select="concat('Template at URL ', $template-url-relative-to-input, ' is not a TAN-T file')"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="template-language" select="$template-doc/tan:TAN-T/tan:body/@xml:lang"/>
    <xsl:variable name="template-resolved" select="tan:resolve-doc($template-doc)"/>
    <xsl:variable name="template-relationships"
        select="$template-resolved/tan:TAN-T/tan:head/tan:definitions/tan:relationship"/>
    <xsl:variable name="template-relationship-resegmented-copy"
        select="$template-relationships[tan:IRI = $relationship-resegmented-copy/tan:IRI]"/>
    <xsl:variable name="template-leaf-div-types"
        select="$template-resolved//tan:div[not(tan:div)]/@type"/>
    <xsl:variable name="majority-leaf-div-type"
        select="tan:most-common-item($template-leaf-div-types)"/>
    <xsl:variable name="majority-leaf-div-type-definition"
        select="$template-resolved/tan:TAN-T/tan:head/tan:definitions/tan:div-type[@xml:id = $majority-leaf-div-type]"/>
    <xsl:param name="template-reference-system-is-based-on-physical-features" as="xs:boolean"
        select="tokenize($majority-leaf-div-type-definition/@orig-group, ' ') = ('physical', 'material')"/>

    <xsl:variable name="break-at-regex"
        select="
            if ($template-reference-system-is-based-on-physical-features) then
                $if-model-uses-object-refs-allow-breaks-only-where-regex
            else
                $if-model-uses-semantic-refs-allow-breaks-only-where-regex"/>


    <xsl:param name="template-infused-with-revised-input" select="$input-pass-3"/>

    <xsl:variable name="output-url-infix"
        select="
            concat(if ($template-reference-system-is-based-on-physical-features) then
                'obj'
            else
                'sem', '-after-', $template-language)"/>
    <xsl:variable name="output-url-prepped"
        select="replace(replace($input-base-uri, '(\.[^\.]+$)', ''), '(sem|obj)[^.]+$', '')"/>
    <xsl:param name="output-url-relative-to-input" as="xs:string?"
        select="concat($output-url-prepped, $output-url-infix, '-', format-date(current-date(), '[Y0001]-[M01]-[D01]'), '.xml')"/>

    <!--<xsl:template match="/" priority="5">
        <!-\- diagnostics -\->
        <diagnostics>
            <!-\-<xsl:copy-of select="$self-expanded"/>-\->
            <!-\-<xsl:copy-of select="$input-precheck"/>-\->
            <!-\-<xsl:copy-of select="$input-expanded"/>-\->
            <!-\-<xsl:copy-of select="$input-body-with-unique-ns"/>-\->

            <!-\-<xsl:copy-of select="$median-template-search-1"/>-\->
            <!-\-<xsl:copy-of select="$median-template-search-2"/>-\->
            <!-\-<xsl:copy-of select="$median-body-with-unique-ns"/>-\->
            <!-\-<xsl:copy-of select="$median-template-doc-resolved"/>-\->
            <!-\-<xsl:copy-of select="$median-template-doc-expanded"/>-\->
            <!-\-<xsl:copy-of select="$median-template-doc-analyzed"/>-\->
            <!-\-<xsl:copy-of select="$input-and-median-merge"/>-\->
            <xsl:copy-of select="$input-and-median-merge-reconstructed"/>

            <!-\-<xsl:copy-of select="$input-pass-1"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-2"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-3"/>-\->

            <!-\-<xsl:copy-of select="$template-doc"/>-\->
            <!-\-<xsl:copy-of select="$template-resolved"/>-\->
            <!-\-<xsl:copy-of select="$template-body-analyzed"/>-\->
            <!-\-<xsl:copy-of select="$template-div-spikes"/>-\->

            <!-\-<xsl:copy-of select="$output-url-resolved"/>-\->

        </diagnostics>
    </xsl:template>-->

</xsl:stylesheet>