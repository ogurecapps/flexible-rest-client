Class FlexibleREST.Message.APIClientReq Extends Ens.Request
{

/// If no URL is specified, the adapter URL will be used
Property URL As %String(MAXLEN = "");

Property Method As %String(VALUELIST = ",GET,POST,PUT,DELETE,PATCH") [ Required ];

Property Body As %Stream.GlobalCharacter;

Property ContentType As %String [ InitialExpression = "application/json" ];

/// UTF8, JS, etc. See the $ZCONVERT documentation for details
Property ConvertFrom As %String;

/// UTF8, JS, etc. See the $ZCONVERT documentation for details
Property ConvertTo As %String;

/// If you send authentication data via headers, set XMLPROJECTION="NONE" for security purposes
Property Headers As array Of %String(MAXLEN = "");

Property Cookies As %String(MAXLEN = "");

Property FormData As array Of %String(MAXLEN = "");

Property ResponseStreamType As %String [InitialExpression = "%Stream.GlobalCharacter"];

Parameter RESPONSECLASSNAME = "FlexibleREST.Message.APIClientResp";

Storage Default
{
<Data name="APIClientReqDefaultData">
<Subscript>"APIClientReq"</Subscript>
<Value name="1">
<Value>URL</Value>
</Value>
<Value name="2">
<Value>Method</Value>
</Value>
<Value name="3">
<Value>Body</Value>
</Value>
<Value name="4">
<Value>ContentType</Value>
</Value>
<Value name="5">
<Value>ConvertFrom</Value>
</Value>
<Value name="6">
<Value>ConvertTo</Value>
</Value>
<Value name="7">
<Value>Cookies</Value>
</Value>
<Value name="8">
<Value>ResponseStreamType</Value>
</Value>
</Data>
<Data name="FormData">
<Attribute>FormData</Attribute>
<Structure>subnode</Structure>
<Subscript>"FlexibleREST.Message.APIClientReq.FormData"</Subscript>
</Data>
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"FlexibleREST.Message.APIClientReq.Headers"</Subscript>
</Data>
<DefaultData>APIClientReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
