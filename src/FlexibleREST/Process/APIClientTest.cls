Class FlexibleREST.Process.APIClientTest Extends (Ens.BusinessProcess, FlexibleREST.Process.CustomizableTarget)
{

Parameter TargetType = "FlexibleREST.Operation.APIClient";

Property URL As %String;

Property HTTPMethod As %String(VALUELIST = ",GET,POST,PUT,DELETE,PATCH");

/// Auto-generated, remove on TargetType change for regeneration
Parameter SETTINGS = "Target:Basic:selector?context={Ens.ContextSearch/ProductionItems?className=FlexibleREST.Operation.APIClient&productionName=@productionId},URL:Basic,HTTPMethod:Basic";

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	Return:..URL="" $$$ERROR($$$GeneralError, "URL is not defined")
	Return:..HTTPMethod="" $$$ERROR($$$GeneralError, "HTTPMethod is not defined")

	Set req = ##class(FlexibleREST.Message.APIClientReq).%New()
	Set req.URL = ..URL
	Set req.Method = ..HTTPMethod
	
	Return ..SendRequestSync(..Target, req, .resp)
}

Storage Default
{
<Data name="APIClientTestDefaultData">
<Subscript>"APIClientTest"</Subscript>
<Value name="1">
<Value>Target</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
<Value name="3">
<Value>HTTPMethod</Value>
</Value>
</Data>
<DefaultData>APIClientTestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
