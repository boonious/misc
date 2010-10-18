package org.apache.solr.handler;

import java.io.File;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.rmi.RemoteException;
import java.util.logging.Logger;

import org.apache.axis.AxisFault;

import fedora.client.FedoraClient;
import fedora.server.access.FedoraAPIA;
import fedora.server.management.FedoraAPIM;
import fedora.server.types.gen.MIMETypedStream;

public class FedoraHelper {
	public static Logger log = Logger.getLogger(FedoraHelper.class.getName());
	private FedoraClient fedoraClient;
	private String trustStorePass;
	private String trustStorePath;
//	private TransformerToText ttt;
	
	public FedoraHelper(String fedoraSoap, String fedoraUser, String fedoraPass, String trustStorePath, String trustStorePass) {
		try {
			fedoraClient = getFedoraClient(fedoraSoap, fedoraUser, fedoraPass);
		//	ttt = new TransformerToText();
		} catch (Exception e) {
			throw new RuntimeException("Can't create fedoraClient", e);
		}
		this.trustStorePath = trustStorePath;
		this.trustStorePass = trustStorePass;
	}
	
	public byte[] getFoxmlFromPid(String pid) throws Exception {
		log.info("getFoxmlFromPid" + " pid=" + pid);
		FedoraAPIM apim = getAPIM(trustStorePath, trustStorePass);
		try {
			return apim.export(pid, "info:fedora/fedora-system:FOXML-1.1", "public");
		} catch (RemoteException e) {
			throw e;
		}
	}
	/*
	public String getDatastreamText(String pid, String dsId) throws Exception {
        StringBuffer dsBuffer = new StringBuffer();
        String mimetype = "";
        byte[] ds = null;
        if (dsId != null) {
            try {
                FedoraAPIA apia = getAPIA(trustStorePath, trustStorePass );
                MIMETypedStream mts = apia.getDatastreamDissemination(pid,dsId, null);
                if (mts==null) return "";
                ds = mts.getStream();
                mimetype = mts.getMIMEType();
            } catch (AxisFault e) {
                if (e.getFaultString().indexOf("DatastreamNotFoundException")>-1 ||
                        e.getFaultString().indexOf("DefaulAccess")>-1)
                    return new String();
                else
                    throw new Exception(e.getFaultString()+": "+e.toString());
            } catch (RemoteException e) {
                throw new Exception(e.getClass().getName()+": "+e.toString());
            }
        }
        if (ds != null) {
            dsBuffer = ttt.getText(ds, mimetype);
        }
		return stripNonValidXMLCharacters(dsBuffer.toString());
	}
	*/
	public String getRedirectedUrlContent(String urlString) throws Exception {
	    StringBuffer dsBuffer = new StringBuffer();
        String mimetype = "";
        byte[] ds = null;
        
	    try {
            URL url = new URL(urlString);
            URLConnection connection = url.openConnection();
            mimetype = connection.getContentType();
            if (mimetype.equals("text/plain") || mimetype.equals("text/xml") 
            || mimetype.equals("text/html") || mimetype.equals("application/pdf")
            || mimetype.equals("application/vnd.ms-powerpoint")) {
                InputStream is = connection.getInputStream();
                long length = connection.getContentLength();
                ds = new byte[(int)length];
                int offset = 0;
                int numRead = 0;
                while ((offset < ds.length) && ((numRead=is.read(ds,offset, ds.length-offset)) >= 0)) {
                    offset += numRead;
                }
                is.close();
		    } else { return ""; }
         } catch (Exception e) { }
         
        if (ds != null) {
          //  dsBuffer = ttt.getText(ds, mimetype);
        }
		return stripNonValidXMLCharacters(dsBuffer.toString());
	}
	
	// Boon Low: for stripping invalid XML characters
	// Ref. http://cse-mjmcl.cse.bris.ac.uk/blog/2007/02/14/1171465494443.html
	public String stripNonValidXMLCharacters(String in) {
        StringBuffer out = new StringBuffer(); // Used to hold the output.
        char current; // Used to reference the current character.

        if (in == null || ("".equals(in))) return ""; // vacancy test.
        for (int i = 0; i < in.length(); i++) {
            current = in.charAt(i); // NOTE: No IndexOutOfBoundsException caught here; it should not happen.
            if ((current == 0x9) ||
                (current == 0xA) ||
                (current == 0xD) ||
                ((current >= 0x20) && (current <= 0xD7FF)) ||
                ((current >= 0xE000) && (current <= 0xFFFD)) ||
                ((current >= 0x10000) && (current <= 0x10FFFF)))
                out.append(current);
        }
        return out.toString();
    }    
	
	private FedoraClient getFedoraClient(String fedoraSoap, String fedoraUser, String fedoraPass) throws Exception {
		try {
			String baseURL = getBaseURL(fedoraSoap);
			FedoraClient client = new FedoraClient(baseURL, fedoraUser, fedoraPass);
			return client;
		} catch (Exception e) {
			throw e;
		}
	}

	private String getBaseURL(String fedoraSoap) throws Exception {
		final String end = "/services";
		if (fedoraSoap.endsWith(end)) {
			return fedoraSoap.substring(0, fedoraSoap.length() - end.length());
		} else {
			throw new Exception("Unable to determine baseURL from fedoraSoap" + " value (expected it to end with '" + end + "'): " + fedoraSoap);
		}
	}

	
	private FedoraAPIM getAPIM(String trustStorePath, String trustStorePass) throws Exception {
		if (trustStorePath != null)
			System.setProperty("javax.net.ssl.trustStore", trustStorePath);
		if (trustStorePass != null)
			System.setProperty("javax.net.ssl.trustStorePassword", trustStorePass);
		try {
			return fedoraClient.getAPIM();
		} catch (Exception e) {
			throw new Exception("Error getting API-M stub", e);
		}
	}
	
	private FedoraAPIA getAPIA(String trustStorePath, String trustStorePass) throws Exception {
		if (trustStorePath != null)
			System.setProperty("javax.net.ssl.trustStore", trustStorePath);
		if (trustStorePass != null)
			System.setProperty("javax.net.ssl.trustStorePassword", trustStorePass);
		try {
			return fedoraClient.getAPIA();
		} catch (Exception e) {
			throw new Exception("Error getting API-A stub", e);
		}
	}
}
