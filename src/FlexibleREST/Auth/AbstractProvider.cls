/// Token provider interface. Concrete implementations (JWT, OAuth, etc.) must implement this interface
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

/// Comma-separated list of HTTP status codes that indicate the current token was rejected by the server (default is 401 only)
Property AuthErrorStatusCodes As %String(MAXLEN = 100) [ InitialExpression = "401" ];

Method GetToken(Output token As %String) As %Status [ Abstract ]
{
}

/// Decides whether the response means "the token is no longer valid" and should trigger invalidation + a single retry.
/// Override in a concrete provider for APIs that signal auth errors differently (e.g. HTTP 200 with an error code in the body).
Method IsAuthError(pHttpRequest As %Net.HttpRequest) As %Boolean
{
	Return:'$iso(pHttpRequest.HttpResponse) 0
	Return $LISTFIND($LISTFROMSTRING(..AuthErrorStatusCodes), pHttpRequest.HttpResponse.StatusCode) > 0
}

/// Clear cache
Method Invalidate() As %Status
{
	Set gref = $NAME(^FlexibleREST.Auth.TokenCache(..TokenKey))
	Lock +@gref:..LockTimeout
	Return:'$TEST $$$ERROR($$$GeneralError, $$$FormatText("%1: lock timeout %2", $CLASSNAME(), gref))

	Kill @gref
	Lock -@gref

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
