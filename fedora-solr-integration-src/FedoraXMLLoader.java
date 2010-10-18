package org.apache.solr.handler;

import org.apache.solr.update.processor.UpdateRequestProcessor;
import org.apache.solr.update.AddUpdateCommand;
import org.apache.solr.update.CommitUpdateCommand;
import org.apache.solr.update.RollbackUpdateCommand;
import org.apache.solr.common.params.UpdateParams;
import org.apache.solr.common.SolrException;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.common.util.ContentStream;
import org.apache.solr.common.util.ContentStreamBase;
import org.apache.solr.common.util.StrUtils;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.response.SolrQueryResponse;
import org.apache.solr.util.xslt.TransformerProvider;

import org.apache.tika.sax.BodyContentHandler;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.metadata.Metadata;
import org.apache.tika.exception.TikaException;

import org.apache.commons.io.IOUtils;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.FactoryConfigurationError;

import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;

import java.net.URL;
import java.net.URLConnection;
import java.net.MalformedURLException;

 
/**
 * JISC UX2 Fedora-Solr-integration
 * Boon Low, http://ux2.nesc.ed.ac.uk
 */

class FedoraXMLLoader extends XMLLoader {
  private XMLInputFactory inputFactory;
  private FedoraHelper fedoraHelper;
  private String fedoraServiceUrl, fedoraUsername, fedoraPassword, trustStorePassword, trustStorePath, fedoraXslt;
  private Transformer foxml_transformer = null;

  public FedoraXMLLoader(SolrQueryRequest req, UpdateRequestProcessor processor, XMLInputFactory inputFactory, String fedoraServiceUrl, String fedoraUsername, String fedoraPassword, String trustStorePath, String trustStorePassword, String fedoraXslt) {
	super(processor, inputFactory);
	this.inputFactory = inputFactory;
	this.fedoraServiceUrl = fedoraServiceUrl;
	this.fedoraUsername = fedoraUsername;
	this.fedoraPassword = fedoraPassword;
	this.trustStorePath = trustStorePath;
	this.trustStorePassword = trustStorePassword;
	this.fedoraXslt = fedoraXslt;
	this.fedoraHelper = new FedoraHelper(fedoraServiceUrl, fedoraUsername, fedoraPassword, trustStorePath, trustStorePassword);
	try {
		this.foxml_transformer = TransformerProvider.instance.getTransformer(req.getCore().getSolrConfig(), fedoraXslt, 0);
	 } catch (IOException e) {
		throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e.getMessage(), e);
	}
  }

  void processUpdate(UpdateRequestProcessor processor, XMLStreamReader parser)
          throws XMLStreamException, IOException, FactoryConfigurationError,
          InstantiationException, IllegalAccessException,
          TransformerConfigurationException {
    AddUpdateCommand addCmd = null;
    while (true) {
      int event = parser.next();
      switch (event) {
        case XMLStreamConstants.END_DOCUMENT:
          parser.close();
          return;

        case XMLStreamConstants.START_ELEMENT:
          String currTag = parser.getLocalName();
          if (currTag.equals(XmlUpdateRequestHandler.ADD)) {
            XmlUpdateRequestHandler.log.trace("SolrCore.update(add)");

            addCmd = new AddUpdateCommand();
            boolean overwrite = true;  // the default

            Boolean overwritePending = null;
            Boolean overwriteCommitted = null;
            for (int i = 0; i < parser.getAttributeCount(); i++) {
              String attrName = parser.getAttributeLocalName(i);
              String attrVal = parser.getAttributeValue(i);
              if (XmlUpdateRequestHandler.OVERWRITE.equals(attrName)) {
                overwrite = StrUtils.parseBoolean(attrVal);
              } else if (XmlUpdateRequestHandler.ALLOW_DUPS.equals(attrName)) {
                overwrite = !StrUtils.parseBoolean(attrVal);
              } else if (XmlUpdateRequestHandler.COMMIT_WITHIN.equals(attrName)) {
                addCmd.commitWithin = Integer.parseInt(attrVal);
              } else if (XmlUpdateRequestHandler.OVERWRITE_PENDING.equals(attrName)) {
                overwritePending = StrUtils.parseBoolean(attrVal);
              } else if (XmlUpdateRequestHandler.OVERWRITE_COMMITTED.equals(attrName)) {
                overwriteCommitted = StrUtils.parseBoolean(attrVal);
              } else {
                XmlUpdateRequestHandler.log.warn("Unknown attribute id in add:" + attrName);
              }
            }

            if (overwritePending != null && overwriteCommitted != null) {
              if (overwritePending != overwriteCommitted) {
                throw new SolrException(SolrException.ErrorCode.BAD_REQUEST,
                        "can't have different values for 'overwritePending' and 'overwriteCommitted'");
              }
              overwrite = overwritePending;
            }
            addCmd.overwriteCommitted = overwrite;
            addCmd.overwritePending = overwrite;
            addCmd.allowDups = !overwrite;
          } else if ("doc".equals(currTag)) {
            XmlUpdateRequestHandler.log.trace("adding doc...");
            addCmd.clear();
            addCmd.solrDoc = readDoc(parser);
            processor.processAdd(addCmd);
          } else if ("fedoraId".equals(currTag)) {
			XmlUpdateRequestHandler.log.trace("adding Fedora object...");
			try {
				processFedoraObject(parser);
			} catch (Exception e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e.getMessage(), e);
			}
		  } else if ("fedoraDir".equals(currTag)) {
			XmlUpdateRequestHandler.log.trace("adding Fedora objects from local directory...");
			try {
				processFedoraObjectsDirectory(parser);
			} catch (Exception e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e.getMessage(), e);
			}
		  } else if (XmlUpdateRequestHandler.COMMIT.equals(currTag) || XmlUpdateRequestHandler.OPTIMIZE.equals(currTag)) {
            XmlUpdateRequestHandler.log.trace("parsing " + currTag);

            CommitUpdateCommand cmd = new CommitUpdateCommand(XmlUpdateRequestHandler.OPTIMIZE.equals(currTag));

            boolean sawWaitSearcher = false, sawWaitFlush = false;
            for (int i = 0; i < parser.getAttributeCount(); i++) {
              String attrName = parser.getAttributeLocalName(i);
              String attrVal = parser.getAttributeValue(i);
              if (XmlUpdateRequestHandler.WAIT_FLUSH.equals(attrName)) {
                cmd.waitFlush = StrUtils.parseBoolean(attrVal);
                sawWaitFlush = true;
              } else if (XmlUpdateRequestHandler.WAIT_SEARCHER.equals(attrName)) {
                cmd.waitSearcher = StrUtils.parseBoolean(attrVal);
                sawWaitSearcher = true;
              } else if (UpdateParams.MAX_OPTIMIZE_SEGMENTS.equals(attrName)) {
                cmd.maxOptimizeSegments = Integer.parseInt(attrVal);
              } else if (UpdateParams.EXPUNGE_DELETES.equals(attrName)) {
                cmd.expungeDeletes = StrUtils.parseBoolean(attrVal);
              } else {
                XmlUpdateRequestHandler.log.warn("unexpected attribute commit/@" + attrName);
              }
            }

            // If waitFlush is specified and waitSearcher wasn't, then
            // clear waitSearcher.
            if (sawWaitFlush && !sawWaitSearcher) {
              cmd.waitSearcher = false;
            }
            processor.processCommit(cmd);
          } // end commit
          else if (XmlUpdateRequestHandler.ROLLBACK.equals(currTag)) {
            XmlUpdateRequestHandler.log.trace("parsing " + currTag);

            RollbackUpdateCommand cmd = new RollbackUpdateCommand();

            processor.processRollback(cmd);
          } // end rollback
          else if (XmlUpdateRequestHandler.DELETE.equals(currTag)) {
            XmlUpdateRequestHandler.log.trace("parsing delete");
            processDelete(processor, parser);
          } // end delete
          break;
      }
    }
  }

  /**
   * Given the XML stream with a fedora ID, retrieve and tranform foxml from a fedora server
   * into Solr Input document, and process it (add to index)
   */
  private void processFedoraObject(XMLStreamReader parser) throws XMLStreamException, Exception {
	String fedora_id = null;
    while (true) {
      int event = parser.next();
      switch (event) {
        case XMLStreamConstants.CHARACTERS:
		// Get Fedora PID
		  fedora_id = parser.getText();
		  transformProcessObject(fedora_id);
          break;
        case XMLStreamConstants.END_ELEMENT:
          return;
      }
    }
  }

  /**
   * Retrieve foxml from a fedora server via FedoraHelper, 
   * transform it into a Solr input doc and re-send the document
   * back to processUpdate to be processed as a solr document 
   */
  private void transformProcessObject(String fedora_id) throws Exception {
	byte[] foxml = fedoraHelper.getFoxmlFromPid(fedora_id);
	InputStream foxml_stream = new ByteArrayInputStream(foxml);
	StringWriter transformResult = new StringWriter();
	// transform foxml metadata (DC) datastream into Solr document
	foxml_transformer.transform(new StreamSource(foxml_stream), new StreamResult(transformResult));     	
	ContentStreamBase stream = new ContentStreamBase.StringStream(transformResult.toString());
	Reader reader = stream.getReader();
	foxml_stream.close();
	this.processUpdate(this.processor,  inputFactory.createXMLStreamReader(reader));
  }

  /**
   * Given a directory of Fedora Objects, recursively retrieve and tranform the Fedora Object XML,
   * into Solr Input and process it (add to index)
   */
  private void processFedoraObjectsDirectory(XMLStreamReader parser) throws XMLStreamException, Exception {
	String fedora_object_directory = null;
    while (true) {
      int event = parser.next();
      switch (event) {
        case XMLStreamConstants.CHARACTERS:
		// Get Fedora Objects Directory
		  fedora_object_directory = parser.getText();
		  if (fedora_object_directory == null) throw new IllegalArgumentException("foxml directory cannot be null");
		  File fedora_object_file_directory = new File(fedora_object_directory);
		  transformProcessObjects(fedora_object_file_directory);
          break;
        case XMLStreamConstants.END_ELEMENT:
          return;
      }
    }
  }
 
  /**
   * Process a directory of Fedora Objects recursively and send FOXML files 
   * to transformProcessObject(file) to be transformed into Solr input documents
   * and subsequently indexed
   */
 private void transformProcessObjects(File fedora_object_directory) throws Exception {
	if (fedora_object_directory.isDirectory()) {
		String[] files = fedora_object_directory.list();
		for (int i = 0; i < files.length; i++) {
			transformProcessObjects(new File(fedora_object_directory, files[i]));
		}
	} else if (fedora_object_directory.isFile()) {
		transformProcessObject(fedora_object_directory);
	}
  }
  
  /** 
   * Transform a foxml file into a Solr input doc and re-send the document
   * back to processUpdate to be processed as a solr document 
   */
  private void transformProcessObject(File fedoraxml) throws Exception {
	if (fedoraxml.isHidden()) return;
	InputStream foxml_stream =  new FileInputStream(fedoraxml);
	StringWriter transformResult = new StringWriter();
	foxml_transformer.transform(new StreamSource(foxml_stream), new StreamResult(transformResult));     	
	ContentStreamBase stream = new ContentStreamBase.StringStream(transformResult.toString());
	Reader reader = stream.getReader();
	foxml_stream.close();
	this.processUpdate(this.processor,  inputFactory.createXMLStreamReader(reader));
  }


  /**
   * Given the input stream, read a document
   * Based on the XMLLoader.readDoc, adding methods to parse rich binary documents,
   * create a fulltext 'text' field containing the extracted text, add the field to Solr doc.
   * This method makes use of the Tika java libraries from the SolrCell
   * fulltext indexing capability (in contrib/extraction)
   */
  SolrInputDocument readDoc(XMLStreamReader parser) throws XMLStreamException {
    SolrInputDocument doc = new SolrInputDocument();

    String attrName = "";
    for (int i = 0; i < parser.getAttributeCount(); i++) {
      attrName = parser.getAttributeLocalName(i);
      if ("boost".equals(attrName)) {
        doc.setDocumentBoost(Float.parseFloat(parser.getAttributeValue(i)));
      } else {
        XmlUpdateRequestHandler.log.warn("Unknown attribute doc/@" + attrName);
      }
    }

    StringBuilder text = new StringBuilder();
    String name = null;
    float boost = 1.0f;
    boolean isNull = false;

	// parameters for parsing datastream for binary
	// documents/fulltext indexing
	String datastreamMimetype = null;
	URL datastreamUrl = null;
	URLConnection datastreamConnection = null;
	InputStream datastream = null;
	ContentHandler textHandler = null;
	AutoDetectParser richDocParser = new AutoDetectParser();

    while (true) {
      int event = parser.next();
      switch (event) {
        // Add everything to the text
        case XMLStreamConstants.SPACE:
        case XMLStreamConstants.CDATA:
        case XMLStreamConstants.CHARACTERS:
          text.append(parser.getText());
          break;

        case XMLStreamConstants.END_ELEMENT:
          if ("doc".equals(parser.getLocalName())) {
            return doc;
          } else if ("field".equals(parser.getLocalName())) {
            if (!isNull) {
              doc.addField(name, text.toString(), boost);
              boost = 1.0f;
            }
          } else if ("datastream".equals(parser.getLocalName())) {
			try {
				datastreamUrl = new URL(text.toString());
			  	datastreamConnection = datastreamUrl.openConnection();
			  	datastreamMimetype = datastreamConnection.getContentType();
			  	if (datastreamMimetype.equals("image/jpeg") || datastreamMimetype.equals("audio/mpeg")) continue;
			  	datastream = datastreamConnection.getInputStream();
			  	textHandler = new BodyContentHandler(-1); // -1 to disable text limit
			  	Metadata metadata = new Metadata();
			  	richDocParser.parse(datastream, textHandler, metadata);
			  	doc.addField("fulltext", textHandler.toString(), boost);
              	boost = 1.0f;
				// XmlUpdateRequestHandler.log.trace("Fedora datastream text:  " + textHandler.toString());
			} catch (MalformedURLException e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e.getMessage() + " datastream url: " + text.toString());
			} catch (IOException e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e);
			} catch (SAXException e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e);
			} catch (TikaException e) {
				throw new SolrException(SolrException.ErrorCode.SERVER_ERROR, e.getMessage() + " datastream url: " +  text.toString());
		    } finally {
		        IOUtils.closeQuietly(datastream);
		    }
		  }	
          break;

        case XMLStreamConstants.START_ELEMENT:
          text.setLength(0);
          String localName = parser.getLocalName();
          if (!("field".equals(localName) || "datastream".equals(localName))) {
            XmlUpdateRequestHandler.log.warn("unexpected XML tag doc/" + localName);
            throw new SolrException(SolrException.ErrorCode.BAD_REQUEST,
                    "unexpected XML tag doc/" + localName);
          }
          boost = 1.0f;
          String attrVal = "";
          for (int i = 0; i < parser.getAttributeCount(); i++) {
            attrName = parser.getAttributeLocalName(i);
            attrVal = parser.getAttributeValue(i);
            if ("name".equals(attrName)) {
              name = attrVal;
            } else if ("boost".equals(attrName)) {
              boost = Float.parseFloat(attrVal);
            } else if ("null".equals(attrName)) {
              isNull = StrUtils.parseBoolean(attrVal);
            } else {
              XmlUpdateRequestHandler.log.warn("Unknown attribute doc/field/@" + attrName);
            }
          }
          break;
      }
    }
  }


}
