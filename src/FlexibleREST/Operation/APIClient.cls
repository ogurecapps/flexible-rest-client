Class FlexibleREST.Operation.APIClient Extends (EnsLib.REST.Operation, FlexibleREST.Auth.CustomSettings, FlexibleREST.Auth.Util)
{

Parameter INVOCATION = "Queue";

Property Adapter As EnsLib.HTTP.OutboundAdapter;

Method OnInit() As %Status
{
	Set tSC = ##super()
	Return:$$$ISERR(tSC) tSC
 
	Return ..InitTokenProvider(..%ConfigName, ..Adapter)
}

Method OnMessage(pRequest As FlexibleREST.Message.APIClientReq, Output pResponse As FlexibleREST.Message.APIClientResp) As %Status
{
	Set tSC = ..BuildHttpRequest(pRequest, .tHReq)
	Return:$$$ISERR(tSC) tSC
	
	Set tSC = ..ApplyAuth(.tHReq)
	Return:$$$ISERR(tSC) tSC

	$$$TRACE("Set Authorization = "_..Mask(tHReq.GetHeader("Authorization")))
	
	Set tURL = $SELECT(pRequest.URL="":..Adapter.URL,1:pRequest.URL)
 	Set tSC = ..SendHttp(.tHReq, pRequest, tURL)
	Return:$$$ISERR(tSC) tSC

	Set tSC = ..RetryUnauthorized(.tHReq, pRequest, tURL)
	Return:$$$ISERR(tSC) tSC

	Return ..BuildResponse(pRequest, tHReq, .pResponse)
}

Method addFormData(ByRef root As %Net.MIMEPart, name As %String, value As %String)
{
	Set textPart = ##class(%Net.MIMEPart).%New()
    Do root.Parts.Insert(textPart)
    
    Do textPart.SetHeader("Content-Disposition", "form-data; name="_$CHAR(34)_name_$CHAR(34))
    
    Set textPart.Body = ##class(%Stream.GlobalCharacter).%New()
    Do textPart.Body.Write(value)
}

Method SetTextBody(pRequest As FlexibleREST.Message.APIClientReq, ByRef tHReq As %Net.HttpRequest) As %Status
{
	Set tHReq.EntityBody = ##class(%Stream.GlobalCharacter).%New()
	
	If $iso(pRequest.Body) {
		If pRequest.ConvertTo '= "" {
			While 'pRequest.Body.AtEnd {
				Do tHReq.EntityBody.Write($ZCONVERT(pRequest.Body.Read(), "O", pRequest.ConvertTo))
			}
		} Else {
			Do tHReq.EntityBody.CopyFrom(pRequest.Body)
		}	
	}
	
	Do:pRequest.ContentType'="" tHReq.SetHeader("Content-Type", pRequest.ContentType)
    Do tHReq.SetHeader("Content-Length", tHReq.EntityBody.Size)

	Return $$$OK
}

Method SetFormDataBody(pRequest As FlexibleREST.Message.APIClientReq, ByRef tHReq As %Net.HttpRequest) As %Status
{
	Set rootPart = ##class(%Net.MIMEPart).%New()

	Set key = ""
	For {
		Set value = pRequest.FormDataGetNext(.key) Quit:key=""
		Do ..addFormData(.rootPart, key, $SELECT(pRequest.ConvertTo="":value, 1:$ZCONVERT(value, "O", pRequest.ConvertTo)))
	}

	Set writer = ##class(%Net.MIMEWriter).%New()
    Set tSC = writer.OutputToStream(tHReq.EntityBody)
    Return:$$$ISERR(tSC) tSC
    
    Set tSC = writer.WriteMIMEBody(rootPart)
    Return:$$$ISERR(tSC) tSC
    
    Do tHReq.SetHeader("Content-Type", "multipart/form-data; boundary="_rootPart.Boundary)

	Return $$$OK
}

Method BuildHttpRequest(pRequest As FlexibleREST.Message.APIClientReq, Output tHReq As %Net.HttpRequest) As %Status
{
	Set tHReq = ##class(%Net.HttpRequest).%New()
	Set tHReq.Server = ..Adapter.HTTPServer
	Set tHReq.Port = ..Adapter.HTTPPort
	Set tHReq.Timeout = ..Adapter.ResponseTimeout
	Set tHReq.SSLConfiguration = ..Adapter.SSLConfig
	Set tHReq.Https = (tHReq.SSLConfiguration '= "")
	Set tHReq.WriteTimeout = ..Adapter.WriteTimeout

	Set tHReq.ProxyHTTPS = ..Adapter.ProxyHTTPS
	Set tHReq.ProxyServer = ..Adapter.ProxyServer
	Set tHReq.ProxyPort = ..Adapter.ProxyPort
	Set tHReq.ProxyTunnel = ..Adapter.ProxyHttpTunnel

	Do tHReq.SetHeader("Host", ..Adapter.HTTPServer)
	
	If (..Adapter.Credentials '= "") && ($ZCONVERT(..Adapter.Credentials, "U") '= "NONE") {
		Set cred = ##class(Ens.Config.Credentials).%OpenId(..Adapter.Credentials)
		Return:'$ISOBJECT(cred) $$$ERROR($$$GeneralError, $$$FormatText("Credentials '%1' not found", ..Adapter.Credentials))
		
		Set tHReq.Username = cred.Username
    	Set tHReq.Password = cred.Password
	}
	
	If $iso(pRequest.Headers) {
		Set key = ""
		While 1 {
			Set key = pRequest.Headers.Next(key)
			Quit:key=""
		
			Do tHReq.SetHeader(key, pRequest.Headers.GetAt(key))
		}
	}

	Set cookieList = $LISTFROMSTRING(pRequest.Cookies,";")
	For i=1:1:$LISTLENGTH(cookieList) {
        Set cookie = $LIST(cookieList, i)
        // name, domain, path, value, expires, secure
		Set tSC = tHReq.InsertCookie($PIECE(cookie,",",1),$PIECE(cookie,",",4),$PIECE(cookie,",",3),$PIECE(cookie,",",2),$PIECE(cookie,",",5),$PIECE(cookie,",",6))
        Return:$$$ISERR(tSC) tSC
    }
	
	If pRequest.FormData.Count() = 0 {
		Set tSC = ..SetTextBody(pRequest, .tHReq)
	} Else {
		Set tSC = ..SetFormDataBody(pRequest, .tHReq)
	}
	Return:$$$ISERR(tSC) tSC
	
 	Return tHReq
}

Method SendHttp(ByRef pHttpRequest As %Net.HttpRequest, pRequest As FlexibleREST.Message.APIClientReq, pURL As %String) As %Status
{
	$$$TRACE(pRequest.Method_" "_..GetCanonicalURL(..Adapter.SSLConfig, ..Adapter.HTTPServer, ..Adapter.HTTPPort, pURL))

	If pRequest.Method = "GET" {
		Set tSC = pHttpRequest.Get(pURL) 	
 	} ElseIf pRequest.Method = "POST" {
		Set tSC = pHttpRequest.Post(pURL) 	
 	} ElseIf pRequest.Method = "PUT" {
		Set tSC = pHttpRequest.Put(pURL)
	} ElseIf pRequest.Method = "PATCH" {
		Set tSC = pHttpRequest.Patch(pURL)
 	} ElseIf pRequest.Method = "DELETE" {
	 	Set tSC = pHttpRequest.Delete(pURL)	
 	} Else {
	 	Set tSC = $$$ERROR($$$GeneralError, $$$FormatText("Method %1 not implemented", pRequest.Method))	
 	}

	Return tSC
}

Method BuildResponse(pRequest As FlexibleREST.Message.APIClientReq, pHttpRequest As %Net.HttpRequest, Output pResponse As FlexibleREST.Message.APIClientResp) As %Status
{
	Set resp = pHttpRequest.HttpResponse
	Return:'$iso(resp) $$$ERROR($$$GeneralError, "HttpResponse is null")

	Set tSC = pRequest.NewResponse(.pResponse)
    Return:$$$ISERR(tSC) tSC
	
	Set pResponse.HTTPCode = resp.StatusCode
	Set pResponse.StatusText = resp.ReasonPhrase

	$$$TRACE("Response received: "_pResponse.HTTPCode_" "_pResponse.StatusText)

	Set size = pHttpRequest.GetFullCookieList(.cookies)
	For i=1:1:size {
		Set pResponse.Cookies = pResponse.Cookies_$SELECT(pResponse.Cookies="":"",1:";")_$LISTTOSTRING(cookies(i))
	}

	If $iso(resp.Data) {
		Set pResponse.Stream = $CLASSMETHOD(pRequest.ResponseStreamType, "%New")

		If (pRequest.ConvertFrom '= "") && (pRequest.ResponseStreamType["GlobalCharacter") {
			While 'resp.Data.AtEnd {
				Do pResponse.Stream.Write($ZCONVERT(resp.Data.Read(), "I", pRequest.ConvertFrom))
			}
		} Else {
			Do pResponse.Stream.CopyFrom(resp.Data)	
		}
	}

	Return tSC
}

}
