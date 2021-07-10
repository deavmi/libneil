module libyggdrasil.utils;

import std.json : JSONValue, JSONException; 

/**
* I don't want to re-write this all the time
*/
public void attemptString(JSONValue nodeInfo, string* var, string key)
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