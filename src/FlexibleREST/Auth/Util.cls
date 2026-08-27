/// Common utils
Class FlexibleREST.Auth.Util Extends %RegisteredObject
{

/// The difference between day 0 in Unix and Cache
Parameter SHIFTINDAYS = 47117;

ClassMethod Mask(data As %String) As %String [ CodeMode = expression ]
{
$SELECT(data="":"", 1:$EXTRACT(data, 1, 10)_"..."_"("_$LENGTH(data)_" chars)")
}

ClassMethod GetCanonicalURL(pSSLConfig As %String, pServer As %String, pPort As %String, pURL As %String) As %String [ CodeMode = expression ]
{
$SELECT(pSSLConfig="":"http", 1:"https")_"://"_pServer_$SELECT(pPort="":"", 1:":"_pPort)_pURL
}

ClassMethod NowUnix() As %Numeric [ CodeMode = expression ]
{
(($PIECE($ZTIMESTAMP, ",") - ..#SHIFTINDAYS) * 86400) + $PIECE($ZTIMESTAMP, ",", 2)
}

ClassMethod ISO8601ToUnix(pTimestamp As %String) As %Numeric
{
	Set dateStr = $PIECE(pTimestamp, "T", 1)
	Set timeStr = $PIECE($PIECE(pTimestamp, "T", 2), ".", 1)
	Set days = $ZDATEH(dateStr, 3)
	Set secs = $ZTIMEH(timeStr, 1)
	
	Return ((days - ..#SHIFTINDAYS) * 86400) + secs
}

/// Retrieve a JSON field, with support for nesting
ClassMethod GetByPath(json As %DynamicObject, path As %String) As %String [ CodeMode = expression ]
{
$XECUTE($$$FormatText("(json) Quit json.%1", path), json)
}

}
