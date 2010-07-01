<?xml version="1.0" encoding="UTF-8"?> 
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
    xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	
    <xsl:template match="marc:collection">
		<marc:collection> 
      	<xsl:apply-templates select="marc:record" /> 
		</marc:collection>
    </xsl:template>

    <xsl:template match="marc:record">
		<marc:record>
	    	<xsl:copy-of select="marc:controlfield" />
			<xsl:apply-templates select="marc:datafield" />
			<xsl:variable name="field653">
				<xsl:for-each select="marc:datafield[@tag='653']">
					<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="field650a">
				<xsl:for-each select="marc:datafield[@tag='650']">
					<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="$field653!='' or $field650a!=''">
				<marc:subject_t>
					<xsl:value-of select="$field653" />
					<xsl:value-of select="$field650a" />
				</marc:subject_t>
			</xsl:if>
		</marc:record>
	 </xsl:template>
	
	 <xsl:template match="marc:datafield">
		<xsl:choose>
				<xsl:when test="@tag='245'">
					<xsl:variable name="field245b"><xsl:value-of select="marc:subfield[@code='b']"/></xsl:variable>
					<xsl:variable name="field240a"><xsl:value-of select="../marc:datafield[@tag='240']/marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field240b"><xsl:value-of select="../marc:datafield[@tag='240']/marc:subfield[@code='b']"/></xsl:variable>
					<xsl:variable name="field700t"><xsl:value-of select="../marc:datafield[@tag='700']/marc:subfield[@code='t']"/></xsl:variable>		
					<marc:title_display>
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</marc:title_display>
					<marc:subtitle_display>
						<xsl:value-of select="$field245b"/>
					</marc:subtitle_display>
					<marc:title_t>
						<xsl:value-of select="marc:subfield[@code='a']"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field245b"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field240a"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field240b"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field700t"/>
					</marc:title_t>
				</xsl:when>
				<xsl:when test="@tag='100'">
					<xsl:variable name="field110a"><xsl:value-of select="../marc:datafield[@tag='110']/marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field111a"><xsl:value-of select="../marc:datafield[@tag='111']/marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field130a"><xsl:value-of select="../marc:datafield[@tag='130']/marc:subfield[@code='a']"/></xsl:variable>
					
					<marc:author_display>
						<xsl:value-of select="marc:subfield[@code='a']"/>
						<xsl:if test="$field110a!=''">, <xsl:value-of select="$field110a"/> </xsl:if>
					</marc:author_display>
					<marc:author_facet>
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</marc:author_facet>
					<marc:author_t>
						<xsl:value-of select="marc:subfield[@code='a']"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field110a"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field111a"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field130a"/>
					</marc:author_t>
				</xsl:when>
				<xsl:when test="@tag='260'">
					<xsl:variable name="field260a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field260b"><xsl:value-of select="marc:subfield[@code='b']"/></xsl:variable>
					<xsl:variable name="field260c"><xsl:value-of select="substring(marc:subfield[@code='c'],1,4)"/></xsl:variable>
										
					<marc:publisher_display>
						<xsl:value-of select="$field260b"/>
						<xsl:if test="$field260a!=''">, <xsl:value-of select="$field260a"/> </xsl:if>
					</marc:publisher_display>
					
					<marc:publisher_t>
						<xsl:value-of select="$field260b"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field260a"/>
					</marc:publisher_t>
				
					<xsl:if test="$field260c!=''">
						<marc:pub_date>
							 <xsl:value-of select="$field260c"/>
						</marc:pub_date>
						<marc:year_facet>
							 <xsl:value-of select="$field260c"/>
						</marc:year_facet>
						<marc:year_multisort_i>
							 <xsl:value-of select="$field260c"/>
						</marc:year_multisort_i>
					</xsl:if>
				</xsl:when>
				<xsl:when test="@tag='300'">
					<xsl:variable name="field300a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<xsl:if test="$field300a!=''">
						<marc:material_type_display>
							 <xsl:value-of select="$field300a"/>
						</marc:material_type_display>
						<marc:material_type_t>
							 <xsl:value-of select="$field300a"/>
						</marc:material_type_t>
					</xsl:if>
				</xsl:when>
				<xsl:when test="@tag='500' or @tag='550'">
					<xsl:variable name="field500a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field550a"><xsl:value-of select="../marc:datafield[@tag='550']/marc:subfield[@code='a']"/></xsl:variable>
					<marc:notes_t>
						<xsl:value-of select="$field500a"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field550a"/>
					</marc:notes_t>
				</xsl:when>
				<xsl:when test="@tag='240'">
					<xsl:variable name="field240a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field240b"><xsl:value-of select="marc:subfield[@code='b']"/></xsl:variable>
					<marc:uniform_title_display>
						<xsl:value-of select="$field240a"/>
					</marc:uniform_title_display>
					<marc:uniform_subtitle_display>
						<xsl:value-of select="$field240b"/>
					</marc:uniform_subtitle_display>
					<marc:uniform_title_t>
						<xsl:value-of select="$field240a"/>
						<xsl:text> </xsl:text><xsl:value-of select="$field240b"/>
					</marc:uniform_title_t>
				</xsl:when>
				<xsl:when test="@tag='650'">
					<xsl:variable name="field650a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field650b"><xsl:value-of select="marc:subfield[@code='b']"/></xsl:variable>
					<xsl:variable name="field650c"><xsl:value-of select="marc:subfield[@code='c']"/></xsl:variable>
					<xsl:variable name="field650d"><xsl:value-of select="marc:subfield[@code='d']"/></xsl:variable>
					<xsl:variable name="field650x"><xsl:value-of select="marc:subfield[@code='x']"/></xsl:variable>
					<xsl:variable name="field650y"><xsl:value-of select="marc:subfield[@code='y']"/></xsl:variable>
					<xsl:variable name="field650z"><xsl:value-of select="marc:subfield[@code='z']"/></xsl:variable>
					<xsl:variable name="field651a"><xsl:value-of select="../marc:datafield[@tag='651']/marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field651x"><xsl:value-of select="../marc:datafield[@tag='651']/marc:subfield[@code='x']"/></xsl:variable>
					<xsl:variable name="field651y"><xsl:value-of select="../marc:datafield[@tag='651']/marc:subfield[@code='y']"/></xsl:variable>
					<xsl:variable name="field651z"><xsl:value-of select="../marc:datafield[@tag='651']/marc:subfield[@code='z']"/></xsl:variable>
					<xsl:variable name="field655a"><xsl:value-of select="../marc:datafield[@tag='655']/marc:subfield[@code='a']"/></xsl:variable>
					<xsl:variable name="field655y"><xsl:value-of select="../marc:datafield[@tag='655']/marc:subfield[@code='y']"/></xsl:variable>
					<xsl:variable name="field655z"><xsl:value-of select="../marc:datafield[@tag='655']/marc:subfield[@code='z']"/></xsl:variable>
					<marc:subject_topic_facet>
						<xsl:value-of select="$field650a"/>
					</marc:subject_topic_facet>
					<marc:subject_era_facet>
						<xsl:if test="$field650d!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650d"/></xsl:if>
						<xsl:if test="$field650y!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650y"/></xsl:if>
						<xsl:if test="$field651y!=''"><xsl:text> </xsl:text><xsl:value-of select="$field651y"/></xsl:if>
						<xsl:if test="$field655y!=''"><xsl:text> </xsl:text><xsl:value-of select="$field655y"/></xsl:if>
					</marc:subject_era_facet>
					<marc:subject_geographic_facet>
						<xsl:if test="$field650c!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650c"/></xsl:if>
						<xsl:if test="$field650z!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650z"/></xsl:if>
						<xsl:if test="$field651a!=''"><xsl:text> </xsl:text><xsl:value-of select="$field651a"/></xsl:if>
						<xsl:if test="$field651x!=''"><xsl:text> </xsl:text><xsl:value-of select="$field651x"/></xsl:if>
						<xsl:if test="$field651z!=''"><xsl:text> </xsl:text><xsl:value-of select="$field651z"/></xsl:if>
						<xsl:if test="$field655z!=''"><xsl:text> </xsl:text><xsl:value-of select="$field655z"/></xsl:if>						
					</marc:subject_geographic_facet>
					<marc:topic_form_genre_facet>
						<xsl:value-of select="$field650a"/>
						<xsl:if test="$field650b!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650b"/></xsl:if>
						<xsl:if test="$field650x!=''"><xsl:text> </xsl:text><xsl:value-of select="$field650x"/></xsl:if>
						<xsl:if test="$field655a!=''"><xsl:text> </xsl:text><xsl:value-of select="$field655a"/></xsl:if>
					</marc:topic_form_genre_facet>
				</xsl:when>
				<xsl:when test="@tag='700'">
					<xsl:variable name="field700t"><xsl:value-of select="marc:subfield[@code='t']"/></xsl:variable>
					<marc:title_added_entry_display>
						<xsl:value-of select="$field700t"/>
					</marc:title_added_entry_display>
				</xsl:when>
				<xsl:when test="@tag='020'">
					<xsl:variable name="field020a"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
					<marc:isbn_display>
						<xsl:value-of select="$field020a"/>
					</marc:isbn_display>
					<marc:isbn_t>
						<xsl:value-of select="$field020a"/>
					</marc:isbn_t>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="."/>
				</xsl:otherwise>
		</xsl:choose>
    </xsl:template>
	
</xsl:stylesheet>	
