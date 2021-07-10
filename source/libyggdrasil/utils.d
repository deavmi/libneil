module libyggdrasil.utils;

import std.json : JSONValue, JSONException; 

/**
* I don't want to re-write this all the time
*/
public bool attemptString(JSONValue nodeInfo, string* var, string key)
{
    try
    {
        *var = nodeInfo[key].str();
        return true;
    }
    catch(JSONException e)
    {
        /* Non-existent key or wrong type */

        return false;
    }
}