Class FlexibleREST.Message.APIClientResp Extends Ens.StreamContainer
{

Property HTTPCode As %Integer;

Property StatusText As %String;

/// For modification outside the operation
Property Cookies As %String(MAXLEN = "");

Storage Default
{
<Data name="APIClientRespDefaultData">
<Subscript>"APIClientResp"</Subscript>
<Value name="1">
<Value>HTTPCode</Value>
</Value>
<Value name="2">
<Value>StatusText</Value>
</Value>
<Value name="3">
<Value>Cookies</Value>
</Value>
</Data>
<DefaultData>APIClientRespDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
