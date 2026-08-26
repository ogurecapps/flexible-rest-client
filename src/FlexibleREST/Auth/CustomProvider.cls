/// Custom OAuth provider
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

	Set httpReq = ..BuildHttpRequest()
	Set tSC = $SELECT(useRefresh: ..FetchByRefreshToken(.httpReq), 1: ..FetchByToken(.httpReq))
	Return:$$$ISERR(tSC) tSC

	If useRefresh && $iso(httpReq.HttpResponse) && (httpReq.HttpResponse.StatusCode '= 200) {
		Do ..Warn($$$FormatText("Refresh token rejected (HTTP %1). Falling back to full token fetch", httpReq.HttpResponse.StatusCode), "Fetch")
		Do ..Invalidate()

		Set httpReq = ..BuildHttpRequest()
		Set tSC = ..FetchByToken(.httpReq)
		Return:$$$ISERR(tSC) tSC
	}

	Return:'$iso(httpReq.HttpResponse) $$$ERROR($$$GeneralError, "Http response is null on token fetching")
	Return:'$iso(httpReq.HttpResponse.Data) $$$ERROR($$$GeneralError, "Http response data is null on token fetching")
	Return:httpReq.HttpResponse.StatusCode'=200 $$$ERROR($$$GeneralError, $$$FormatText("Invalid HTTP code on token fetching: %1", httpReq.HttpResponse.StatusCode))

	Do ..Trace("Response: "_httpReq.HttpResponse.Data.Read(httpReq.HttpResponse.Data.Size), "Fetch")
	Do httpReq.HttpResponse.Data.Rewind()
	
	Set json = $SELECT($iso(httpReq.HttpResponse.Data):{}.%FromJSON(httpReq.HttpResponse.Data),1:{})
	Set list = ..TokensExtract(json)
	
	Return $$$OK
}

Method TokensExtract(json As %DynamicObject) As %List
{
	Set token = ..GetByPath(json, ..TokenField)
	Return:token="" $$$ERROR($$$GeneralError, $$$FormatText("Field '%1' not found in JSON: %2", ..TokenField, json.%ToJSON()))
	
	Set expiresIn = ..GetByPath(json, ..ExpiresField)
	If expiresIn = "" {
		Set tokenExpiresAt = ..NowUnix() + ..DefaultTTL
	} Else {
		Set tokenExpiresAt = $SELECT(..ExpiresAsDate: ..ISO8601ToUnix(expiresIn), 1: ..NowUnix() + expiresIn)
	}
	
	Set refreshToken = ..GetByPath(json, ..RefreshTokenField)
	Set refreshTokenExpiresAt = ""
	
	If (refreshToken '= "") {
		Set refreshTokenExpiresIn = ..GetByPath(json, ..RefreshTokenExpiresField)
		If (refreshTokenExpiresIn = "") {
			Set refreshTokenExpiresAt = ..NowUnix() + ..DefaultTTL
		} Else {
			Set refreshTokenExpiresAt = $SELECT(..ExpiresAsDate: ..ISO8601ToUnix(refreshTokenExpiresIn), 1: ..NowUnix() + refreshTokenExpiresIn)
		}
	}

	Return $LISTBUILD(token, +tokenExpiresAt, refreshToken, +refreshTokenExpiresAt)
}

Method FetchByRefreshToken(ByRef httpReq As %Net.HttpRequest) As %Status
{
	Do httpReq.SetHeader("Authorization", "Bearer "_..%RefreshToken)

	Do ..Trace("GET "_..GetCanonicalURL(..SSLConfig, ..HTTPServer, ..HTTPPort, ..RefreshURL), "FetchByRefreshToken")
	Return httpReq.Get(..RefreshURL)
}

Method FetchByToken(ByRef httpReq As %Net.HttpRequest) As %Status
{
	If ..AuthStyle = "basic" {
		Set httpReq.Username = ..Username
		Set httpReq.Password = ..Password
	} ElseIf ..AuthStyle = "body" {
		If ..RequestFormat = "json" {
			Set body = ..BuildJSON()

			Do body.%ToJSON(.stream)
			Do httpReq.SetHeader("Content-Length", stream.Size)
			Do httpReq.SetHeader("Host", httpReq.Server)
			Do httpReq.SetHeader("Content-Type", "application/json")
			Do httpReq.EntityBody.CopyFrom(stream)
		} Else {	// form
			Do ..BuildFormData(.httpReq)
		}	
	} ElseIf ..AuthStyle = "parameters" {
		Do httpReq.SetParam(..ClientIdFieldName, ..Username)
  		Do httpReq.SetParam(..ClientSecretFieldName, ..Password)
		Do:..GrantType'="" httpReq.SetParam("grant_type", ..GrantType)
		Do:..Scope'="" httpReq.SetParam("scope", ..Scope)
	}

	Do ..Trace("POST "_..GetCanonicalURL(..SSLConfig, ..HTTPServer, ..HTTPPort, ..TokenURL), "FetchByToken")
	Return httpReq.Post(..TokenURL)
}

Method Invalidate() As %Status
{
	Set tSC = ##super()
	Return:$$$ISERR(tSC) tSC

	Set ..%Token = "", ..%TokenExpiresAt = 0, ..%RefreshToken = "", ..%RefreshTokenExpiresAt = 0
	Return $$$OK
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
