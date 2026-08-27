/// Setting of CustomProvider (see the PROVIDERCLASS parameter)
Class FlexibleREST.Auth.CustomSettings Extends FlexibleREST.Auth.ProviderSettings
{

Parameter SETTINGS = "TokenURL:Auth,RefreshTokenURL:Auth,TokenSkew:Auth,TokenGrantType:Auth,TokenScope:Auth,TokenAuthStyle:Auth,TokenRequestFormat:Auth,TokenClientIdFieldName:Auth,TokenClientSecretFieldName:Auth,TokenFieldName:Auth,TokenExpiresFieldName:Auth,TokenExpiresAsDate:Auth,RefreshTokenFieldName:Auth,RefreshTokenExpiresFieldName:Auth,TokenDefaultTTL:Auth,RefreshAuthStyle:Auth,RefreshMethod:Auth";

/// Which token-provider fields the settings values should be written to
Parameter KEYMAP = "TokenURL,RefreshTokenURL:RefreshURL,TokenSkew:Skew,TokenGrantType:GrantType,TokenScope:Scope,TokenAuthStyle:AuthStyle,TokenRequestFormat:RequestFormat,TokenClientIdFieldName:ClientIdFieldName,TokenClientSecretFieldName:ClientSecretFieldName,TokenFieldName:TokenField,TokenExpiresFieldName:ExpiresField,TokenExpiresAsDate:ExpiresAsDate,RefreshTokenFieldName:RefreshTokenField,RefreshTokenExpiresFieldName:RefreshTokenExpiresField,TokenDefaultTTL:DefaultTTL,RefreshAuthStyle,RefreshMethod";

/// Which token provider these settings belong to
Parameter PROVIDERCLASS = "FlexibleREST.Auth.CustomProvider";

/// Endpoint for obtaining the token (/token)
Property TokenURL As %String(MAXLEN = 128);

/// Endpoint for obtaining the token by refresh token (/refresh-token)
Property RefreshTokenURL As %String(MAXLEN = 128);
 
/// Refresh the token TokenSkew seconds before it expires
Property TokenSkew As %Integer [ InitialExpression = 60 ];

Property TokenGrantType As %String(MAXLEN = 64) [ InitialExpression = "client_credentials" ];

Property TokenScope As %String(MAXLEN = 512);
 
/// Where to place credentials: body — client_id/client_secret in the body, basic — Authorization: Basic header, parameters — in query parameters
Property TokenAuthStyle As %String(VALUELIST = ",body,basic,parameters") [ InitialExpression = "body" ];
 
/// Request format: form (x-www-form-urlencoded) or json when TokenAuthStyle = "body"
Property TokenRequestFormat As %String(VALUELIST = ",form,json") [ InitialExpression = "form" ];

/// Field with the client identifier (username)
Property TokenClientIdFieldName As %String(MAXLEN = 128) [ InitialExpression = "client_id" ];

/// Field with the secret (password)
Property TokenClientSecretFieldName As %String(MAXLEN = 128) [ InitialExpression = "client_secret" ];
 
/// Field with the token; nesting is allowed: "data.access_token"
Property TokenFieldName As %String(MAXLEN = 128) [ InitialExpression = "data.access_token" ];
 
/// Field with the time-to-live
Property TokenExpiresFieldName As %String(MAXLEN = 128) [ InitialExpression = "data.expires_in" ];

/// Switches the implementation variant: expires_in (number of seconds) or expires_at (unix timestamp)
Property TokenExpiresAsDate As %Boolean [ InitialExpression = 0 ];

Property RefreshTokenFieldName As %String(MAXLEN = 128) [ InitialExpression = "data.refresh_token" ];

Property RefreshTokenExpiresFieldName As %String(MAXLEN = 128) [ InitialExpression = "data.refresh_token_expires_in" ];
 
/// Default time-to-live in seconds
Property TokenDefaultTTL As %Integer [ InitialExpression = 300 ];

/// How to send a refresh token? 
/// header: via the Authorization header 
/// body: in the JSON body 
/// parameters: as a query parameter
Property RefreshAuthStyle As %String(VALUELIST = ",header,body,parameters") [ InitialExpression = "header" ];

Property RefreshMethod As %String(VALUELIST = ",GET,POST") [ InitialExpression = "GET" ];

}
