Class FlexibleREST.Production.Test Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="FlexibleREST.Production.Test" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Setting Target="Adapter" Name="ShutdownTimeout">15</Setting>
  <Item Name="FlexibleREST.Operation.DummyJSON.API" Category="" ClassName="FlexibleREST.Operation.APIClient" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="HTTPServer">dummyjson.com</Setting>
    <Setting Target="Adapter" Name="SSLCheckServerIdentity">0</Setting>
    <Setting Target="Adapter" Name="SSLConfig">ISC.FeatureTracker.SSL.Config</Setting>
    <Setting Target="Host" Name="RefreshTokenExpiresFieldName"></Setting>
    <Setting Target="Host" Name="RefreshTokenFieldName">refreshToken</Setting>
    <Setting Target="Host" Name="RefreshTokenURL">/auth/refresh</Setting>
    <Setting Target="Host" Name="TokenClientIdFieldName">username</Setting>
    <Setting Target="Host" Name="TokenClientSecretFieldName">password</Setting>
    <Setting Target="Host" Name="TokenExpiresFieldName"></Setting>
    <Setting Target="Host" Name="TokenFieldName">accessToken</Setting>
    <Setting Target="Host" Name="TokenGrantType"></Setting>
    <Setting Target="Host" Name="TokenRequestFormat">json</Setting>
    <Setting Target="Host" Name="TokenURL">/auth/login</Setting>
    <Setting Target="Host" Name="TokenProviderClass">FlexibleREST.Auth.CustomProvider</Setting>
    <Setting Target="Host" Name="TokenCredentials">dummy-json</Setting>
    <Setting Target="Host" Name="RefreshAuthStyle">body</Setting>
    <Setting Target="Host" Name="RefreshMethod">POST</Setting>
  </Item>
  <Item Name="FlexibleREST.Process.DummyJSON.Test" Category="" ClassName="FlexibleREST.Process.APIClientTest" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="Target">FlexibleREST.Operation.DummyJSON.API</Setting>
    <Setting Target="Host" Name="HTTPMethod">GET</Setting>
    <Setting Target="Host" Name="URL">/auth/ip</Setting>
  </Item>
  <Item Name="FlexibleREST.Service.DummyJSON.Run" Category="" ClassName="FlexibleREST.Service.Job" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">FlexibleREST.Process.DummyJSON.Test</Setting>
    <Setting Target="Adapter" Name="CallInterval">3600</Setting>
  </Item>
</Production>
}

}
