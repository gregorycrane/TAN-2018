<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    <xsl:import href="incl/chop-string.xsl"/>
    <xsl:param name="chop-at-regex" select="$clause-end-regex"/>
    <xsl:param name="keep" select="'last'"/>
    <xsl:param name="shallow-skip" select="true()"/>
</xsl:stylesheet>
