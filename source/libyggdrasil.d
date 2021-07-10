module libyggdrasil;

import std.stdio;
import std.json;
import std.socket;
import std.string;
import std.conv : to;
import libchonky : ChonkReader;

public final class BuildInfo
{
	private string _version = "none", arch = "none", platform = "none", name = "none";

	this(JSONValue nodeInfo)
	{
		/* Attempt extraction */
		extractInfo(nodeInfo);
	}

	private void extractInfo(JSONValue nodeInfo)
	{
		attemptString(nodeInfo, &_version, "buildversion");
		attemptString(nodeInfo, &arch, "buildarch");
		attemptString(nodeInfo, &platform, "buildplatform");
		attemptString(nodeInfo, &name, "buildname");
	}

	/**
	* I don't want to re-write this all the time
	*/
	private void attemptString(JSONValue nodeInfo, string* var, string key)
	{
		try
		{
			*var = nodeInfo[key].str();
		}
		catch(JSONException e)
		{
			/* Non-existent key or wrong type */
		}
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

public class NodeInfo
{
	private JSONValue nodeInfoJSON;
	private JSONValue operatorBlock;
	private string nodeName = "<no name>";
	private string groupName = "<no name>";
	private string country = "<no name>";
	private string key;
	/* TODO: Standardise */
	/**
	* Name
	* Owner
	* Contact
	* Group
	*/
	this(JSONValue nodeInfoJSON)
	{
		/* We only do one query (so it will be first) */
		writeln(nodeInfoJSON);
		if(nodeInfoJSON.type == JSONType.null_)
		{
			return;
		}
		key = nodeInfoJSON.object().keys[0];
		this.nodeInfoJSON = nodeInfoJSON[key];

		
		parse();
		
	}
	
	public string getName()
	{
		return nodeName;
	}

	public string getGroupName()
	{
		return groupName;
	}

	public string getCountry()
	{
		return country;
	}

	public string getAddress()
	{
		return "unavailable";
	}

	public string getKey()
	{
		return key;
	}

	public JSONValue getOperatorBlock()
	{
		return operatorBlock;
	}

	public JSONValue getFullJSON()
	{
		return nodeInfoJSON;
	}

	private void parse()
	{
		foreach(string item; nodeInfoJSON.object().keys)
		{
			if(cmp(item, "name") == 0)
			{
				nodeName = nodeInfoJSON["name"].str();
			}
			else if(cmp(item, "operator") == 0)
			{
				operatorBlock = nodeInfoJSON["operator"];
			}
			else if(cmp(item, "group") == 0)
			{
				groupName = nodeInfoJSON["group"].str();
			}
			else if(cmp(item, "location") == 0)
			{
				country = nodeInfoJSON["location"].str();
			}
		}
	
	}

	public BuildInfo getBuildInfo()
	{
		return new BuildInfo(nodeInfoJSON);
	}


	public override string toString()
	{
		return key~" (Name: "~nodeName~", Group: "~groupName~", Operator: "~to!(string)(operatorBlock)~")";
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
		YggdrasilRequest req = new YggdrasilRequest(RequestType.NODEINFO, key);

		JSONValue resp = sillyWillyRequest(peer, req);

		if(resp.type == JSONType.null_)
		{
			return null;
		}
		else
		{
			return new NodeInfo(resp);	
		}
	}

	public YggdrasilNode[] getPeers()
	{
		YggdrasilNode[] peers;

		YggdrasilRequest req = new YggdrasilRequest(RequestType.GETPEERS, key);
		JSONValue resp = sillyWillyRequest(peer, req);

		if(resp.type != JSONType.null_)
		{
			foreach(JSONValue ckey; resp[resp.object().keys[0]]["keys"].array())
			{
				string ckeyStr = ckey.str();
				peers ~= new YggdrasilNode(peer, ckeyStr);
			}
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
		bool status = true;

		/* TODO: Implement me */

		return status;
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

		/* Fetch data over socket and set */
		
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