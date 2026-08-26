/// Base class for token-provider settings
Class FlexibleREST.Auth.ProviderSettings Extends Ens.Settings [ Abstract ]
{

Parameter SETTINGS = "TokenProviderClass:TokenProvider,TokenKey:TokenProvider,TokenCredentials:TokenProvider:credentialsSelector,TokenLockTimeout:TokenProvider";

/// Override in the implementation
Parameter KEYMAP = "";

/// Override in the implementation
Parameter PROVIDERCLASS = "";

/// Class implementing the AbstractProvider interface; no authorization if not specified
Property TokenProviderClass As %String(MAXLEN = 256);
 
/// Set if several operations must share the token, otherwise %ConfigName is used
Property TokenKey As %String(MAXLEN = 256);

/// Credential in the adapter - it is Basic authentication, 
/// TokenCredentials - it is credentials for getting a token
Property TokenCredentials As %String;

/// Lock timeout for the token cache, seconds (^FlexibleREST.Auth.TokenCache)
Property TokenLockTimeout As %Integer [ InitialExpression = 15 ];
 
Property %TokenProvider As FlexibleREST.Auth.AbstractProvider [ Internal ];

Method InitTokenProvider(pConfigName As %String, adapter As EnsLib.HTTP.OutboundAdapter) As %Status
{
	Set ..%TokenProvider = $$$NULLOREF
	Return:..TokenProviderClass="" $$$OK
 
	Set def = ##class(%Dictionary.CompiledClass).%OpenId(..TokenProviderClass)
    Return:'$ISOBJECT(def) $$$ERROR($$$GeneralError, $$$FormatText("Token provider class %1 not found or not compiled", ..TokenProviderClass))
	Set parent = ##class(FlexibleREST.Auth.AbstractProvider).%ClassName(1)
	Return:def.Super'[parent $$$ERROR($$$GeneralError, $$$FormatText("%1 is not a subclass of %2", ..TokenProviderClass, parent))

	Set provider = $CLASSMETHOD(..TokenProviderClass, "%New")
	Return:'$ISOBJECT(provider) $$$ERROR($$$GeneralError, $$$FormatText("Failed to create an instance of token provider %1", ..TokenProviderClass))

	Do ..BuildSettings(.settings, pConfigName, adapter)

	Set tSC = provider.Configure(.settings)
	Return:$$$ISERR(tSC) tSC
 
	Set ..%TokenProvider = provider
	Return $$$OK
}

Method ApplyAuth(ByRef pHttpRequest As %Net.HttpRequest) As %Status
{
	Return:(..TokenProviderClass="")||'$ISOBJECT(..%TokenProvider) $$$OK

	Set tSC = ..%TokenProvider.GetToken(.token)
	Return:$$$ISERR(tSC) tSC
	
	Do pHttpRequest.SetHeader("Authorization", token)
	Return $$$OK
}

Method RetryUnauthorized(ByRef pHttpRequest As %Net.HttpRequest, pRequest As FlexibleREST.Message.APIClientReq, pURL As %String) As %Status
{
	Return:(..TokenProviderClass="")||'$ISOBJECT(..%TokenProvider) $$$OK
	Return:'$iso(pHttpRequest.HttpResponse) $$$OK
	Return:pHttpRequest.HttpResponse.StatusCode'=401 $$$OK
	
	Do ..%TokenProvider.Invalidate()
	Do:$iso(pHttpRequest.EntityBody) pHttpRequest.EntityBody.Rewind()

	Set tSC = ..ApplyAuth(.pHttpRequest)
	Return:$$$ISERR(tSC) tSC

	Return ..SendHttp(.pHttpRequest, pRequest, pURL)
}

Method SendHttp(ByRef pHttpRequest As %Net.HttpRequest, pRequest As FlexibleREST.Message.APIClientReq, pURL As %String) As %Status [ Abstract ]
{
}

/// Find the settings class associated with the provider and populate the provider's fields with their values
Method BuildSettings(Output pSettings, pConfigName As %String, adapter As EnsLib.HTTP.OutboundAdapter) As %Status [ Private ]
{
	Kill pSettings
 
	// Common settings
	Set pSettings("TokenKey") = $SELECT(..TokenKey="":pConfigName, 1:..TokenKey)
	Set pSettings("HTTPServer") = adapter.HTTPServer
	Set pSettings("HTTPPort") = adapter.HTTPPort
	Set pSettings("ResponseTimeout") = adapter.ResponseTimeout
	Set pSettings("SSLConfig") = adapter.SSLConfig
	Set pSettings("WriteTimeout") = adapter.WriteTimeout
	Set pSettings("LockTimeout") = ..TokenLockTimeout
 
	If (..TokenCredentials '= "") && ($ZCONVERT(..TokenCredentials, "U") '= "NONE") {
		Set cred = ##class(Ens.Config.Credentials).%OpenId(..TokenCredentials)
		Return:'$ISOBJECT(cred) $$$ERROR($$$GeneralError, $$$FormatText("Credentials '%1' not found", ..TokenCredentials))

		Set pSettings("Username") = cred.Username
		Set pSettings("Password") = cred.Password
	}

	// Token-provider settings
	Return:..TokenProviderClass="" $$$OK

	Set def = ##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1))
	Return:'$iso(def) $$$ERROR($$$GeneralError, $$$FormatText("Class %1 not found or not compiled", ..%ClassName(1)))
 
	Try {
		Set prop = ""
		For i=1:1:$LENGTH(def.PrimarySuper, "~") {
			Set super = $PIECE(def.PrimarySuper, "~", i)
			
			Continue:super=""
			Continue:..GetParam(super,"PROVIDERCLASS")'=..TokenProviderClass
 
			Set map = ..GetParam(super, "KEYMAP")
			For j=1:1:$LENGTH(map, ",") {
				Set pair = $PIECE(map, ",", j)
				Continue:pair=""

				Set prop = $PIECE(pair, ":", 1)
				Set name = $PIECE(pair, ":", 2)
				Set:name="" name = prop // The same as property name

				Set pSettings(name) = $PROPERTY($THIS, prop)
			}
			Quit  // 1 provider = 1 settings class
		}
	} Catch ex {
		Return $$$ERROR($$$GeneralError, $$$FormatText("Error parsing KEYMAP (class '%1', property '%2'): %3", super, prop, ex.DisplayString()))
	}
 
	Return $$$OK
}

ClassMethod GetParam(pClass As %String, pParameter As %String) As %String [ Private ]
{
	Set def = ##class(%Dictionary.CompiledParameter).%OpenId(pClass_"||"_pParameter)
	Return $SELECT($iso(def):def.Default, 1:"")
}

}
