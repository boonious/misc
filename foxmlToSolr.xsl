<?xml version="1.0" encoding="UTF-8"?> 
<!-- $Id: demoFoxmlToLucene.xslt 5734 2006-11-28 11:20:15Z gertsp $ -->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
    xmlns:foxml="info:fedora/fedora-system:def/foxml#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	 xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
    <xsl:variable name="fedoraHost" select="'http://localhost:8080/fedora'"/>
    
    <xsl:template match="/">
		<add> 
			<doc> 
         	<xsl:attribute name="boost">2.5</xsl:attribute>
            <xsl:apply-templates /> 
         </doc>
		</add>
    </xsl:template>
    
    <xsl:template match="/foxml:digitalObject">
        <field name="id" boost="2.5"><xsl:value-of select="$PID"/></field>
        <field name="library_facet" boost="2.5">e-Science</field>
        <xsl:for-each select="foxml:objectProperties/foxml:property">
            <field>
                <xsl:attribute name="name"> 
                    <xsl:value-of select="concat('fedora_property_', substring-after(@NAME,'#'), '_t')"/>
                </xsl:attribute>
                <xsl:value-of select="@VALUE"/>
            </field>
        </xsl:for-each>
        <xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
			<xsl:if test="contains(name(),'contributor')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'coverage')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'creator')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="'author'"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="facet" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'date')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>
					<xsl:with-param name="sort" select="true()"/>
				</xsl:call-template>
				<xsl:if test="starts-with(normalize-space(text()),'20') or starts-with(normalize-space(text()),'19')">
					<field>
						<xsl:attribute name="name">
	               	<xsl:value-of select="'year_facet'"/>
	             	 </xsl:attribute>
	             	 <xsl:value-of select="substring(normalize-space(text()),1,4)"/>
	         	</field>
					<field>
						<xsl:attribute name="name">
	               	<xsl:value-of select="'pub_date'"/>
	             	 </xsl:attribute>
	             	 <xsl:value-of select="substring(normalize-space(text()),1,4)"/>
	         	</field>
				</xsl:if>
			</xsl:if>
			<xsl:if test="contains(name(),'description')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<!--xsl:if test="contains(name(),'format')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>
					<xsl:with-param name="unstem" select="true()"/>					
				</xsl:call-template>
			</xsl:if-->
			<xsl:if test="contains(name(),'identifier')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>					
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'identifier') and contains(text(), 'ISBN:')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="'isbn'"/>
					<xsl:with-param name="field_value" select="substring-after(normalize-space(text()),'ISBN:')"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>					
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'language')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>					
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'publisher')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>					
		 			<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'relation')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
		 			<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'right')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
		 			<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'source')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
		 			<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'subject')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
				</xsl:call-template>
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="'subject_topic'"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
		 			<xsl:with-param name="facet" select="true()"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'title')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="text" select="true()"/>
					<xsl:with-param name="sort" select="true()"/>	
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(name(),'type')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>	
				</xsl:call-template>
				<xsl:if test="normalize-space(text())!=''">
					<field>
						<xsl:attribute name="name">
	               	<xsl:value-of select="'format'"/>
	             	 </xsl:attribute>
	             	 <xsl:value-of select="normalize-space(text())"/>
	         	</field>
				</xsl:if>
			</xsl:if>
			<xsl:if test="contains(name(),'license')">
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="substring-after(name(),':')"/>
					<xsl:with-param name="field_value" select="normalize-space(text())"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="facet" select="true()"/>	
				</xsl:call-template>
			</xsl:if>
        </xsl:for-each>
       
		  <xsl:if test="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/dc:creator">
				<xsl:variable name="author_string">
					<xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/dc:creator">
						<xsl:value-of select="."/> <xsl:if test="position()!=last()"><xsl:value-of select="', '"/></xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:call-template name="populate_fields">
					<xsl:with-param name="field_name" select="'author'"/>
					<xsl:with-param name="field_value" select="normalize-space($author_string)"/>
					<xsl:with-param name="display" select="true()"/>
					<xsl:with-param name="sort" select="true()"/>
				</xsl:call-template>
		  </xsl:if>

        <!--xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/dc:dc/*">
            <field >
                <xsl:attribute name="name">
                    <xsl:value-of select="concat(substring-after(name(),':'), '_text')"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </field>
        </xsl:for-each-->
        
        <!--xsl:for-each select="foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/*">
            <field >
                <xsl:attribute name="name">
                   <xsl:value-of select="concat('rdf.', translate(name(), ':', '.'))"/>
                </xsl:attribute>
                <xsl:value-of select="substring-after(@rdf:resource, 'info:fedora/')"/>
                <xsl:value-of select="text()"/>
            </field>
        </xsl:for-each-->
        
        <xsl:for-each select="foxml:datastream[@CONTROL_GROUP='R']">
            <field >
                <xsl:attribute name="name">
                    <xsl:value-of select="'mimetype_facet'"/>
                </xsl:attribute>
                <xsl:value-of select="foxml:datastreamVersion[last()]/@MIMETYPE"/>
            </field>
				<field >
	         	<xsl:attribute name="name">
	            	<xsl:value-of select="'mimetype_display'"/>
	            </xsl:attribute>
	            <xsl:value-of select="foxml:datastreamVersion[last()]/@MIMETYPE"/>
	         </field>
            <field >
                <xsl:attribute name="name">
                    <xsl:value-of select="'identifier_t'"/>
                </xsl:attribute>
                <xsl:value-of select="foxml:datastreamVersion[last()]/foxml:contentLocation/@REF"/>
            </field>
        </xsl:for-each>

		 <xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M']">
            <field >
                <xsl:attribute name="name">
                    <xsl:value-of select="'mimetype_facet'"/>
                </xsl:attribute>
                <xsl:value-of select="foxml:datastreamVersion[last()]/@MIMETYPE"/>
            </field>
				<field >
	         	<xsl:attribute name="name">
	            	<xsl:value-of select="'mimetype_display'"/>
	            </xsl:attribute>
	            <xsl:value-of select="foxml:datastreamVersion[last()]/@MIMETYPE"/>
	         </field>
        </xsl:for-each>

		<xsl:if test="foxml:datastream[@CONTROL_GROUP='M']">
			<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M']">
				<xsl:variable name="content_url"><xsl:value-of select="foxml:datastreamVersion[last()]/foxml:contentLocation[ @TYPE='INTERNAL_ID']/@REF"/></xsl:variable>
				<xsl:choose>
					<xsl:when test="starts-with($content_url, 'http')">
						<datastream><xsl:value-of select="$content_url"/></datastream>
					</xsl:when>
					<xsl:otherwise>
						<datastream><xsl:value-of select="$fedoraHost"/>/get/<xsl:value-of select="$PID"/>/<xsl:value-of select="@ID"/></datastream>	
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="foxml:datastream[@CONTROL_GROUP='R']">
			<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='R']">
				<xsl:variable name="content_url"><xsl:value-of select="foxml:datastreamVersion[last()]/foxml:contentLocation[ @TYPE='INTERNAL_ID']/@REF"/></xsl:variable>
				<xsl:if test="starts-with($content_url, 'http')">
					<datastream><xsl:value-of select="$content_url"/></datastream>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		
    </xsl:template>
    
	<xsl:template name="populate_fields">
		<xsl:param name="field_name"/>
		<xsl:param name="field_value"/>
		<xsl:param name="display"/>
		<xsl:param name="text"/>		
		<xsl:param name="facet"/>
		<xsl:param name="sort"/>
		<xsl:param name="unstem"/>
		<xsl:if test="$display">
			<field>
				<xsl:attribute name="name">
	         	<xsl:value-of select="concat($field_name, '_display')"/>
				</xsl:attribute>
				<xsl:value-of select="$field_value"/>
			</field>
     	</xsl:if>
		<xsl:if test="$text">
			<field>
				<xsl:attribute name="name">
	         	<xsl:value-of select="concat($field_name, '_t')"/>
				</xsl:attribute>
				<xsl:value-of select="$field_value"/>
			</field>
    	</xsl:if>
		<xsl:if test="$facet and $field_value!=''">
			<field>
				<xsl:attribute name="name">
	         	<xsl:value-of select="concat($field_name, '_facet')"/>
				</xsl:attribute>
				<xsl:value-of select="$field_value"/>
			</field>
    	</xsl:if>
		<xsl:if test="$sort">
			<field>
				<xsl:attribute name="name">
	         	<xsl:value-of select="concat($field_name, '_sort')"/>
				</xsl:attribute>
				<xsl:value-of select="$field_value"/>
			</field>
    	</xsl:if>
		<xsl:if test="$unstem">
			<field>
				<xsl:attribute name="name">
	         	<xsl:value-of select="concat($field_name, '_unstem_search')"/>
				</xsl:attribute>
				<xsl:value-of select="$field_value"/>
			</field>
    	</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>	
