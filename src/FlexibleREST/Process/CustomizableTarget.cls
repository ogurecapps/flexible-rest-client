/// Business Host with customizable target
Class FlexibleREST.Process.CustomizableTarget Extends %RegisteredObject [ Abstract ]
{

Property Target As Ens.DataType.ConfigName;

/// Must be defined in subclass
Parameter TargetType;

Method TargetSetup() As %Status [ CodeMode = objectgenerator, Internal ]
{
	Return:%class.Abstract $$$OK

	Set targetType = "", generated = 0
	For i=1:1:%class.Parameters.Count() {
        Set param = %class.Parameters.GetAt(i)
        Set:param.Name="TargetType" targetType = param.Default
		Set:param.Name="SETTINGS" generated = 1  
	}

	Return:targetType="" $$$ERROR($$$GeneralError, "Parameter TargetType must be defined")
	Return:generated=1 $$$OK

	Set settings = ##class(%Dictionary.ParameterDefinition).%New()
	Do %class.Parameters.Insert(settings)

    Set settings.Name = "SETTINGS"
    Set settings.Default = $$$FormatText("Target:Basic:selector?context={Ens.ContextSearch/ProductionItems?className=%1&productionName=@productionId}", targetType)
    Set settings.Description = "Auto-generated, remove on TargetType change for regeneration"
    
	Return %class.%Save()
}

Method OnInit() As %Status
{
	Return:..Target="" $$$ERROR($$$GeneralError, "You must specify the Target setting")
	Return $$$OK
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set:pItem.GetModifiedSetting("Target", .tValue) pArray(tValue) = ""
}

}
