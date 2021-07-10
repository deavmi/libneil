module libyggdrasil.libyggdrasil;

import libyggdrasil.utils : attemptString;

import std.stdio;
import std.json;
import std.socket;
import std.string;
import std.conv : to;
import libchonky : ChonkReader;



public final class BuildInfo
{
	private ubyte wellFormed = 0;
	private string _version = "none", arch = "none", platform = "none", name = "none";

	this(JSONValue nodeInfo)
	{
		/* Attempt extraction */
		extractInfo(nodeInfo);
	}

	private void extractInfo(JSONValue nodeInfo)
	{
		if(attemptString(nodeInfo, &_version, "buildversion"))
		{
			wellFormed++;
		}
		if(attemptString(nodeInfo, &arch, "buildarch"))
		{
			wellFormed++;
		}
		if(attemptString(nodeInfo, &platform, "buildplatform"))
		{
			wellFormed++;
		}
		if(attemptString(nodeInfo, &name, "buildname"))
		{
			wellFormed++;
		}
	}

	public bool isWellFormed()
	{
		return wellFormed == 4;
	}

	public string getVersion()
	{
		return _version;
	}

	public string getName()
	{
		return name;
	}

	public string getPlatform()
	{
		return platform;
	}

	public string getArchitecture()
	{
		return arch;
	}

}

public final class NodeService
{
	private string serviceName;
	private string protocol;
	private ushort[] ports;
	
	this(string serviceName, string protocol, ushort[] ports)
	{
		this.serviceName = serviceName;
		this.protocol = protocol;
		this.ports = ports;
	}

	public string getName()
	{
		return serviceName;
	}

	public string getProtocol()
	{
		return protocol;
	}

	public ushort[] getPorts()
	{
		return ports;
	}
}

public class NodeInfo
{
	/* Key of the node this NodeInfo is associated with */
	private string key;

	/**
	* NodeInfo data
	*/
	private ubyte wellFormed = 0;
	private JSONValue nodeInfoJSON;
	private string name = "<no name>";
	private string group = "<no name>";
	private string location = "<no name>";
	private string contact = "<no name>";


	/**
	* Given the response JSON this will extract the
	* key, NodeInfo as a whole and also attempt to extract
	* standardized aspects of the NodeInfo
	*/
	this(JSONValue nodeInfoJSON)
	{
		/* Save the key from the response */
		key = nodeInfoJSON.object().keys[0];

		/* Extract the entry */
		this.nodeInfoJSON = nodeInfoJSON[key];

		/* Attempt to parse the standardized parts */
		parse();
	}
	
	public string getName()
	{
		return name;
	}

	public string getGroupName()
	{
		return group;
	}

	public string getCountry()
	{
		return location;
	}

	public string getKey()
	{
		return key;
	}

	public JSONValue getFullJSON()
	{
		return nodeInfoJSON;
	}

	private void parse()
	{
	
				if(attemptString(nodeInfoJSON, &name, "name"))
				{
					wellFormed++;
				}
		
				if(attemptString(nodeInfoJSON, &contact, "contact"))
				{
					wellFormed++;
				}
			
				if(attemptString(nodeInfoJSON, &group, "group"))
				{
					wellFormed++;
				}
			
				if(attemptString(nodeInfoJSON, &location, "location"))
				{
					wellFormed++;
				}
			
			
		
	}

	public bool isWellFormed()
	{
		return wellFormed == 4;
	}

	public BuildInfo getBuildInfo()
	{
		return new BuildInfo(nodeInfoJSON);
	}


	public override string toString()
	{
		/* TODO: */
		return ""; 
	}
}

public final class DHTInfo
{
	this()
	{
		/* TODO: Implement me */
	}
}

/**
* YggdrasilNode
*
* Given a key
*/
public class YggdrasilNode
{
	private YggdrasilPeer peer;
	
	private string key;
	private JSONValue selfInfo;
	private JSONValue nodeInfo;
	
	
	this(YggdrasilPeer peer, string key)
	{
		this.peer = peer;
		this.key = key;
	}

	public NodeInfo getNodeInfo()
	{
		/* Create the NodeInfo request */
		YggdrasilRequest req = new YggdrasilRequest(RequestType.NODEINFO, key);

		/* Make the request */
		YggdrasilResponse resp = makeRequest(peer, req);

		/* Create a new NodeInfo object */
		return new NodeInfo(resp.getJSON());
	}

	public DHTInfo getDHT()
	{
		/* Create the getDHT request */
		YggdrasilRequest req = new YggdrasilRequest(RequestType.GETDHT, key);

		/* Make the request */
		YggdrasilResponse resp = makeRequest(peer, req);

		/* TODO: Implement me */
		return null;
	}

	public YggdrasilNode[] getPeers()
	{
		/* Peers */
		YggdrasilNode[] peers;

		/* Create the getPeers request */
		YggdrasilRequest req = new YggdrasilRequest(RequestType.GETPEERS, key);

		/* Make the request */
		YggdrasilResponse resp = makeRequest(peer, req);

		/* Get the JSON and process the list */
		JSONValue respJSON = resp.getJSON();

		foreach(JSONValue ckey; respJSON[respJSON.object().keys[0]]["keys"].array())
		{
			string ckeyStr = ckey.str();
			peers ~= new YggdrasilNode(peer, ckeyStr);
		}

		return peers;
	}

	public string getKey()
	{
		return key;
	}

	public override string toString()
	{
		/* TODO: Fetch getNodeInfo, if possible, else leave key */		
		return getNodeInfo().toString();
	}


	/**
	* Checks if the node is online
	*
	* This is implemented by doing a getDHT()
	*/
	public bool ping()
	{
		try
		{
			/* Attempt to do getDHT */
			getDHT();
			return true;
		}
		catch(YggdrasilException)
		{
			return false;
		}
	}
}

/**
* YggdrasilNode
*
* This represents a peer of which we can
* connect to its control socket using TCP
*/
public class YggdrasilPeer
{
	private Address yggdrasilAddress;

	this(Address yggdrasilAddress)
	{
		this.yggdrasilAddress = yggdrasilAddress;	
	}

	public Address getAddress()
	{
		return yggdrasilAddress;
	}

	private void initData()
	{
		/* TODO: Add exception throwing here */

			
	}

	public YggdrasilNode fetchNode(string key)
	{
		return new YggdrasilNode(this, key);		
	}
}

public enum RequestType
{
	NODEINFO, GETDHT, GETPEERS, GETSELF
}

public final class YggdrasilRequest
{
	private RequestType requestType;
	private string key;

	this(RequestType requestType, string key)
	{
		this.requestType = requestType;
		this.key = key;
	} 


	public JSONValue generateJSON()
	{
		JSONValue requestBlock;

		/* Set the key of the node to request from */
		requestBlock["key"] = key;

		if(requestType == RequestType.NODEINFO)
		{
			requestBlock["request"] = "getnodeinfo";
		}
		else if(requestType == RequestType.GETSELF)
		{
			requestBlock["request"] = "debug_remotegetself";
		}
		else if(requestType == RequestType.GETPEERS)
		{
			requestBlock["request"] = "debug_remotegetpeers";
		}
		else if(requestType == RequestType.GETDHT)
		{
			requestBlock["request"] = "debug_remotegetdht";
		}
		


		return requestBlock;
	}
}

public final class YggdrasilResponse
{
	private JSONValue responseBlock;

	this(JSONValue responseBlock)
	{
		this.responseBlock = responseBlock;
	}

	public JSONValue getJSON()
	{
		return responseBlock;
	}
}

public final class YggdrasilException : Exception
{
	public enum ErrorType
	{
		CONTROL_SOCKET_ERROR,
		JSON_PARSE_ERROR,
		TIMED_OUT
	}

	private ErrorType errType;

	this(ErrorType errType)
	{
		super("YggdrasilError: "~to!(string)(errType));
		this.errType = errType;
	}

	public ErrorType getError()
	{
		return errType;
	}
}

public YggdrasilResponse makeRequest(YggdrasilPeer peer, YggdrasilRequest request)
{
	/* The response */
	YggdrasilResponse response;

	/* Communication socket */
	Socket controlSocket;

	try
	{
		/* Attempt to create the socket and connect it */
		controlSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
		controlSocket.connect(peer.getAddress());

		/* Make the request */
		JSONValue requestBlock = request.generateJSON();
		controlSocket.send(cast(byte[])toJSON(requestBlock));

		/* Await reply till socket closes */
		ChonkReader reader = new ChonkReader(controlSocket);
		byte[] buffer;
		reader.receiveUntilClose(buffer);

		/* Parse the response */
		JSONValue responseBlock;
		try
		{
			/* Parse the JSON */
			responseBlock = parseJSON(cast(string)buffer);

			/* Check status of request */
			if(cmp(responseBlock["status"].str(), "success"))
			{
				/* Extract response */
				JSONValue reuqestResponse = responseBlock["response"];

				/* Create the YggdrasilResponse object */
				response = new YggdrasilResponse(reuqestResponse);

				/* Close the socket */
				controlSocket.close();
			}
			else
			{
				throw new YggdrasilException(YggdrasilException.ErrorType.TIMED_OUT);
			}
		}
		catch(JSONException e)
		{
			throw new YggdrasilException(YggdrasilException.ErrorType.JSON_PARSE_ERROR);
		}
	}
	catch(SocketOSException e)
	{
		throw new YggdrasilException(YggdrasilException.ErrorType.CONTROL_SOCKET_ERROR);
	}

	return response;
}