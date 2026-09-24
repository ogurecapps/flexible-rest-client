/// Custom OAuth-like provider
Class FlexibleREST.Auth.CustomProvider Extends (FlexibleREST.Auth.AbstractProvider, FlexibleREST.Auth.Util)
{

Property TokenURL As %String(MAXLEN = 128);

Property RefreshURL As %String(MAXLEN = 128);

Property Skew As %Integer;
 
Property Username As %String;
 
Property Password As %String;
 
Property GrantType As %String(MAXLEN = 64);

Property Scope As %String(MAXLEN = 512);
 
Property AuthStyle As %String;
 
Property RequestFormat As %String;
 
Property ClientIdFieldName As %String(MAXLEN = 128);

Property ClientSecretFieldName As %String(MAXLEN = 128);

Property TokenField As %String(MAXLEN = 128);
 
Property ExpiresField As %String(MAXLEN = 128);

Property RefreshTokenField As %String(MAXLEN = 128);

Property RefreshTokenExpiresField As %String(MAXLEN = 128);

Property ExpiresAsDate As %Boolean;
 
Property DefaultTTL As %Integer;

Property RefreshAuthStyle As %String;

Property RefreshMethod As %String;

Property LoginMethod As %String;
 
Property TokenAsPlainText As %Boolean;

Property TokenExpiresFromJWT As %Boolean;

/// Process-local cache
Property %Token As %String(MAXLEN = "") [ Internal ];
 
Property %TokenExpiresAt As %Numeric [ Internal, InitialExpression = 0 ];

Property %RefreshToken As %String(MAXLEN = "") [ Internal ];

Property %RefreshTokenExpiresAt As %Numeric [ Internal, InitialExpression = 0 ];

Method GetToken(Output token As %String) As %Status
{
	Return:..TokenKey="" $$$ERROR($$$GeneralError, $$$FormatText("%1: TokenKey is not set", $CLASSNAME()))
	Return:..TokenURL="" $$$ERROR($$$GeneralError, $$$FormatText("%1: TokenURL is not set", $CLASSNAME()))
	
	Set tSC = $$$OK
	Set gref = $NAME(^FlexibleREST.Auth.TokenCache(..TokenKey))

	// Process-local cache
	If (..%Token '= "") && (..%TokenExpiresAt > (..NowUnix() + ..Skew)) {
		Set token = "Bearer "_..%Token
		Return $$$OK
	}

	// Disk cache
	Set row = $GET(@gref)
	If (row '= "") {
		Do ..Trace("Token data has been restored from disk cache", "GetToken")
		Do ..UpdateProcessCache(row)
		
		If (..%Token '= "") && (..%TokenExpiresAt > (..NowUnix() + ..Skew)) {
			Set token = "Bearer "_..%Token
			Return $$$OK	
		}
	}
 
	// Use a lock since the operation may have PoolSize > 1
	Lock +@gref:..LockTimeout
	Return:'$TEST $$$ERROR($$$GeneralError, $$$FormatText("%1: lock timeout %2", $CLASSNAME(), gref))

	Try {
		Set row = $GET(@gref)	// The token may have been refreshed while we were waiting for the lock
		If (row '= "") && ($LISTGET(row, 2) > (..NowUnix() + ..Skew)) {
			Do ..UpdateProcessCache(row)
		} Else {
			$$$ThrowOnError(..Fetch(.row))
			Set @gref = row
			Do ..UpdateProcessCache(row)
		}
		Set token = "Bearer "_..%Token
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
 
	Lock -@gref
	Return tSC
}

Method UpdateProcessCache(list As %List)
{
	Set ..%Token = $LISTGET(list, 1)
	Set ..%TokenExpiresAt = $LISTGET(list, 2)
	Set ..%RefreshToken = $LISTGET(list, 3)
	Set ..%RefreshTokenExpiresAt = $LISTGET(list, 4)

	Do ..Trace(
		$$$FormatText("Updated process cache: %Token = %1, %TokenExpiresAt = %2, %RefreshToken = %3, %RefreshTokenExpiresAt = %4", ..Mask(..%Token), ..%TokenExpiresAt, ..Mask(..%RefreshToken), ..%RefreshTokenExpiresAt),
		"UpdateProcessCache")
}

Method Fetch(Output list As %List) As %Status
{
	Set useRefresh = (..%RefreshToken '= "") && (..%RefreshTokenExpiresAt >= (..NowUnix() + ..Skew))
	Do ..Trace($SELECT(useRefresh:"Using refresh token", 1:"Using full token"), "Fetch")

	Set httpReq = ..BuildHttpRequest()
	Set tSC = $SELECT(useRefresh: ..FetchByRefreshToken(.httpReq), 1: ..FetchByToken(.httpReq))
	Return:$$$ISERR(tSC) tSC

	If useRefresh && $iso(httpReq.HttpResponse) && '..IsOK(httpReq.HttpResponse.StatusCode) {
		Do ..Warn($$$FormatText("Refresh token rejected (HTTP %1). Falling back to full token fetch", httpReq.HttpResponse.StatusCode), "Fetch")
		Do ..Invalidate()
		Set useRefresh = 0

		Set httpReq = ..BuildHttpRequest()
		Set tSC = ..FetchByToken(.httpReq)
		Return:$$$ISERR(tSC) tSC
	}

	Return:'$iso(httpReq.HttpResponse) $$$ERROR($$$GeneralError, "Http response is null on token fetching")
	Return:'$iso(httpReq.HttpResponse.Data) $$$ERROR($$$GeneralError, "Http response data is null on token fetching")
	Return:'..IsOK(httpReq.HttpResponse.StatusCode) $$$ERROR($$$GeneralError, $$$FormatText("Invalid HTTP code on token fetching: %1", httpReq.HttpResponse.StatusCode))

	If ..TokenAsPlainText {
		Set tSC = ..BodyTokensExtract(httpReq.HttpResponse.Data, .list)
	} Else {
		Set json = {}.%FromJSON(httpReq.HttpResponse.Data)
		Do ..TraceTokenResponse(json, useRefresh)
		Set tSC = ..JSONTokensExtract(json, .list)
	}
	Return:$$$ISERR(tSC) tSC

	Return $$$OK
}

Method JWTExpiresExtract(token As %String, Output expiresAt As %Integer) As %Status
{
	Set payload = $PIECE(token, ".", 2)
	Return:payload="" $$$ERROR($$$GeneralError, $$$FormatText("Malformed JWT: expected 3 dot-separated segments (%1)", token))

	Try {
		Set claims = {}.%FromJSON(..Base64UrlDecode(payload))
	} Catch ex {
		Return $$$ERROR($$$GeneralError, $$$FormatText("Failed to decode JWT payload: %1", ex.DisplayString()))
	}

	Do ..Trace($$$FormatText("JWT claims.exp = %1", claims.exp), "JWTExpiresExtract")

	Set expiresAt = $SELECT(claims.exp="":..NowUnix() + ..DefaultTTL, 1:claims.exp)
	Return $$$OK
}

Method BodyTokensExtract(body As %Stream.Object, Output list As %List) As %Status
{
	Set token = $ZSTRIP(body.Read(body.Size), "<>W")
	Return:token="" $$$ERROR($$$GeneralError, "Empty string in response body")

	If ..TokenExpiresFromJWT {
		Set tSC = ..JWTExpiresExtract(token, .tokenExpiresAt)
		Return:$$$ISERR(tSC) tSC
	} Else {
		Set tokenExpiresAt = ..NowUnix() + ..DefaultTTL
	}

	Do ..Trace($$$FormatText("Read from the body: token = %1, exp = %2", ..Mask(token), tokenExpiresAt), "BodyTokensExtract")

	Set list = $LISTBUILD(token, +tokenExpiresAt, "", "")
	Return $$$OK
}

Method TraceTokenResponse(json As %DynamicObject, isRefresh As %Boolean)
{
	Set body = json.%ToJSON()
	Set token = ..GetByPath(json, ..TokenField)
	Set refreshToken = $SELECT(..RefreshTokenField="":"", 1:..GetByPath(json, ..RefreshTokenField))
	Set:token'="" body = $REPLACE(body, token, ..Mask(token))
	Set:refreshToken'="" body = $REPLACE(body, refreshToken, ..Mask(refreshToken))

	Do ..Trace("Response: "_body, $SELECT(isRefresh:"FetchByRefreshToken", 1:"FetchByToken"))
}

Method JSONTokensExtract(json As %DynamicObject, Output list As %List) As %Status
{
	Set token = ..GetByPath(json, ..TokenField)
	Return:token="" $$$ERROR($$$GeneralError, $$$FormatText("Field '%1' not found in JSON: %2", ..TokenField, json.%ToJSON()))
	
	If ..TokenExpiresFromJWT {
		Set tSC = ..JWTExpiresExtract(token, .tokenExpiresAt)
		Return:$$$ISERR(tSC) tSC
	} Else {
		Set expires = $SELECT(..ExpiresField="":"", 1:..GetByPath(json, ..ExpiresField))
		If expires = "" {
			Set tokenExpiresAt = ..NowUnix() + ..DefaultTTL
		} Else {
			Set tokenExpiresAt = $SELECT(..ExpiresAsDate: ..ISO8601ToUnix(expires), 1: ..NowUnix() + expires)
		}
	}
	
	Set refreshToken = $SELECT(..RefreshTokenField="":"", 1:..GetByPath(json, ..RefreshTokenField))
	Set refreshTokenExpiresAt = ""
	
	If (refreshToken '= "") {
		Set refreshExpires = $SELECT(..RefreshTokenExpiresField="":"", 1:..GetByPath(json, ..RefreshTokenExpiresField))
		If (refreshExpires = "") {
			Set refreshTokenExpiresAt = ..NowUnix() + ..DefaultTTL
		} Else {
			Set refreshTokenExpiresAt = $SELECT(..ExpiresAsDate: ..ISO8601ToUnix(refreshExpires), 1: ..NowUnix() + refreshExpires)
		}
	}

	Set list = $LISTBUILD(token, +tokenExpiresAt, refreshToken, +refreshTokenExpiresAt)
	Return $$$OK
}

Method FetchByRefreshToken(ByRef httpReq As %Net.HttpRequest) As %Status
{
	If ..RefreshAuthStyle = "header" {
		Do httpReq.SetHeader("Authorization", "Bearer "_..%RefreshToken)
	} ElseIf ..RefreshAuthStyle = "parameters" {
		Do httpReq.SetParam(..RefreshTokenField, ..%RefreshToken)
	} Else {
		Set json = {}.%Set(..RefreshTokenField, ..%RefreshToken)
		Set tSC = ..BodySet(.httpReq, json)
		Return:$$$ISERR(tSC) tSC
	}

	Do ..Trace(..RefreshMethod_" "_..GetCanonicalURL(..SSLConfig, ..HTTPServer, ..HTTPPort, ..RefreshURL), "FetchByRefreshToken")
	Return $SELECT(..RefreshMethod="POST":httpReq.Post(..RefreshURL), 1:httpReq.Get(..RefreshURL))
}

Method FetchByToken(ByRef httpReq As %Net.HttpRequest) As %Status
{
	If ..AuthStyle = "basic" {
		Set httpReq.Username = ..Username
		Set httpReq.Password = ..Password
	} ElseIf ..AuthStyle = "body" {
		If ..RequestFormat = "json" {
			Set tSC = ..BodySet(.httpReq, ..BuildJSON())
			Return:$$$ISERR(tSC) tSC
		} Else {	// form
			Do ..BuildFormData(.httpReq)
		}	
	} ElseIf ..AuthStyle = "parameters" {
		Do httpReq.SetParam(..ClientIdFieldName, ..Username)
  		Do httpReq.SetParam(..ClientSecretFieldName, ..Password)
		Do:..GrantType'="" httpReq.SetParam("grant_type", ..GrantType)
		Do:..Scope'="" httpReq.SetParam("scope", ..Scope)
	}

	Do ..Trace(..LoginMethod_" "_..GetCanonicalURL(..SSLConfig, ..HTTPServer, ..HTTPPort, ..TokenURL), "FetchByToken")
	
	If ..LoginMethod = "POST" {
		Set tSC = httpReq.Post(..TokenURL)
	} ElseIf ..LoginMethod = "GET" {
		Set tSC = httpReq.Get(..TokenURL)
	} Else {
		Set tSC = $$$ERROR($$$GeneralError, "Unsupported login method: "_..LoginMethod)
	}

	Return tSC
}

Method Invalidate() As %Status
{
	Set tSC = ##super()
	Return:$$$ISERR(tSC) tSC

	Set ..%Token = "", ..%TokenExpiresAt = 0, ..%RefreshToken = "", ..%RefreshTokenExpiresAt = 0
	Return $$$OK
}

Method BodySet(ByRef httpReq As %Net.HttpRequest, body As %DynamicObject) As %Status
{
	Set stream = ##class(%Stream.GlobalCharacter).%New()
	Do body.%ToJSON(stream)
	Do httpReq.SetHeader("Content-Length", stream.Size)
	Do httpReq.SetHeader("Host", httpReq.Server)
	Do httpReq.SetHeader("Content-Type", "application/json")
	
	Return httpReq.EntityBody.CopyFrom(stream)
}

Method BuildJSON() As %DynamicObject
{
	Set body = {}
	
	Do:..GrantType'="" body.%Set("grant_type", ..GrantType)
	Do:..Scope'="" body.%Set("scope", ..Scope)
	Do body.%Set(..ClientIdFieldName, ..Username)
	Do body.%Set(..ClientSecretFieldName, ..Password)
	
	Return body
}

Method BuildFormData(ByRef httpReq As %Net.HttpRequest) As %Status
{
	Do:..GrantType'="" httpReq.InsertFormData("grant_type", ..GrantType)
	Do:..Scope'="" httpReq.InsertFormData("scope", ..Scope)
	Do httpReq.InsertFormData(..ClientIdFieldName, ..Username)
	Do httpReq.InsertFormData(..ClientSecretFieldName, ..Password)

	Return $$$OK
}

}
