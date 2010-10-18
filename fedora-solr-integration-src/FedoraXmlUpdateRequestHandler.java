package org.apache.solr.handler;

import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.update.processor.UpdateRequestProcessor;
import org.apache.solr.common.util.NamedList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JISC UX2 Fedora-Solr-integration
 * Boon Low, http://ux2.nesc.ed.ac.uk
 * Add XML documents transformed from Fedora (FedoraXMLLoader) to solr using the STAX XML parser.
 */

public class FedoraXmlUpdateRequestHandler extends XmlUpdateRequestHandler {
  public static Logger log = LoggerFactory.getLogger(FedoraXmlUpdateRequestHandler.class);

 // Required for interacting with a Fedora server
  private String fedoraServiceUrl, fedoraUsername, fedoraPassword, trustStorePassword, trustStorePath, fedoraXslt;

  public void init(NamedList args) {
    super.init(args);
	log.trace("Initialising Fedora Update Request Handler...");
	
	// Parameter from config files	
	fedoraServiceUrl = (String) args.get("serviceUrl");
	fedoraUsername = (String) args.get("username");
	fedoraPassword = (String) args.get("password");
	trustStorePath = (String) args.get("trustStorePath");
	trustStorePassword = (String) args.get("trustStorePass");
	fedoraXslt = (String) args.get("fedoraXslt");
  }

  protected ContentStreamLoader newLoader(SolrQueryRequest req, UpdateRequestProcessor processor) {
	// return the Fedora XML Loader, passing the relevant parameters in stylesheet names, helper class
	return new FedoraXMLLoader(req, processor, inputFactory, fedoraServiceUrl, fedoraUsername, fedoraPassword, trustStorePath, trustStorePassword, fedoraXslt);
  }
 
}



