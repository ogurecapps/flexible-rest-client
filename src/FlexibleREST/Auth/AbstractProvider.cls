/// Token provider interface; concrete implementations (JWT, OAuth, etc.) must implement this interface
Class FlexibleREST.Auth.AbstractProvider Extends %RegisteredObject [ Abstract ]
{

Property TokenKey As %String;

/// IP address of the server to send HTTP requests to.
Property HTTPServer As %String(MAXLEN = 1000) [ Required ];

/// TCP Port on the server to send HTTP requests to (will use 80 by default, or 443 if SSLConfig is specified)
Property HTTPPort As %Integer(MAXVAL = 65535, MINVAL = 0);

/// Timeout for getting a response from the server (the timeout for opening the connection to the server is always 5 seconds). Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 30, Required ];

Property SSLConfig As %String;

/// Set this to the timeout to use when writing to the remote HTTP server.<br>
/// The default is -1 means it will wait indefinitely for the remote server to accept the
/// written data, change it to another value to specify the timeout in seconds.
Property WriteTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

Property LockTimeout As %Integer;

Method GetToken(Output token As %String) As %Status [ Abstract ]
{
}

/// Clear cache
Method Invalidate() As %Status
{
	Set gref = $NAME(^FlexibleREST.Auth.TokenCache(..TokenKey))
	Lock +@gref:..LockTimeout
	Set locked = $TEST
	Kill @gref
	Lock:locked -@gref

	Return $$$OK
}

Method Configure(pSettings) As %Status
{
	Set key = "", log = ""
	For {
		Set key = $ORDER(pSettings(key)) Quit:key=""
		Set value = $GET(pSettings(key))
		Set:value'="" log = log_$SELECT(log="":"",1:", ")_key_"="_$SELECT(key="Password":"***", 1:value)
		
		Try {
			Set $PROPERTY($THIS, key) = value
		} Catch ex {
            Return ex.AsStatus()
        }
	}

	Do ..Trace("Parameters set: "_log, "Configure")
	
	Return $$$OK
}

Method BuildHttpRequest() As %Net.HttpRequest
{
	Set httpReq = ##class(%Net.HttpRequest).%New()
	Set httpReq.Server = ..HTTPServer
	Set httpReq.Port = ..HTTPPort
	Set httpReq.Timeout = ..ResponseTimeout
	Set httpReq.SSLConfiguration = ..SSLConfig
	Set httpReq.Https = (httpReq.SSLConfiguration '= "")
	Set httpReq.WriteTimeout = ..WriteTimeout

	Return httpReq
}

/// The following methods are used to write to the Event Log outside business hosts
Method Error(text As %String, method As %String = "TokenProvider") 
{
	Do ##class(Ens.Util.Log).LogError(..TokenKey, method, text)
}

Method Warn(text As %String, method As %String = "TokenProvider") 
{
	Do ##class(Ens.Util.Log).LogWarning(..TokenKey, method, text)
}

Method Info(text As %String, method As %String = "TokenProvider") 
{
	Do ##class(Ens.Util.Log).LogInfo(..TokenKey, method, text)
}

Method Trace(text As %String, method As %String = "TokenProvider")
{
	Do ##class(Ens.Util.Log).LogTrace(..TokenKey, method, text)
}

}
