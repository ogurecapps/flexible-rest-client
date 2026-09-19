# Flexible REST API Client for IRIS Interoperability (Ensemble)

## What's new
- For more flexibility, the `RawJWT` option has been replaced with two options: `TokenAsPlainText` - when we get a non-JSON authentication response, and `TokenExpiresFromJWT` - for retrieving the token expiration date (works with both JSON and text response bodies)

## Features
- Based on `EnsLib.REST.Operation`
- Extensible architecture
- Support request/response conversion from/to UTF8, JS, etc. (useful when using an IRIS instance with a national locale)
- Support sending HTTP headers in Ensemble messages
- Support cookie modification
- Sending request as text body (JSON, XML, etc.) or as Form Data
- Getting a character or binary response body (files)
- Basic, Header, or Cookie authentication in simple cases
- An easy way to connect custom authentication providers for complex use cases (retrieving and renewing tokens, managing expiration dates, and so on). See the `TokenProviderClass` setting and `FlexibleREST.Auth.AbstractProvider` class
- Sharing a token between many business operations (see `TokenKey` setting)
- Correctly work with tokens in a multi-threaded mode of a single business operation (`Pool Size > 1`)
- Two-level token cache: in-process memory and on disk
- Masking sensitive data in logs
- Included an OAuth-like token provider with a bunch of settings (implementation of the `AbstractProvider` interface). You can use it as a sample for your own provider implementation
- Token refresh support
- `TokenSkew` - early refreshing
- Customizable auth style on token receiving: `body`, `basic`, `parameters` (see `TokenAuthStyle` setting)
- Customizable token request methods (`GET`, `POST`)
- Customizable token request body format: `form` (`x-www-form-urlencoded`) or `json` (if you use `TokenAuthStyle = body`)
- Read and write token-related data from/to any fields. You only need to specify the field names, nesting is allowed! For example, tokens can be extracted from: `data."access_token"` or `accessToken` fields - a sample of real settings
- The token expiration date can be specified in seconds or as an ISO 8601 datetime (please ensure the UTC0 time zone is used)
- The default time-to-live of the token is supported (`TokenDefaultTTL`)
- Customizable `grant_type` and token `scope`
- Option `TokenAsPlainText` - when on authentication request the server returns only a token as plain text 
- Option `TokenExpiresFromJWT` - when we have to extract the expiration date from the JWT token ourselves
- Customizable way to refresh the token. You can choose the HTTP method and sending type (via the `Authorization` header, in the JSON body, or as a query parameter)
- Customizable unauthorized error checker. You can set one of the HTTP status codes (e.g., 401, 403) as a signal that the server rejected the token. Or override the `IsAuthError()` method to check the response body content
- The package includes a demo version of the Interoperability Production with a configured example request to the dummyjson API (see the `Auth` settings section of the Business Operation for details)

## Installation with ZPM
```
zpm "install flexible-rest-client"
```
Run the command in the IRIS terminal with IPM installed. Add the `FlexibleREST.Operation.APIClient` Business Operation to your Production

## Installation with Git
```
git clone https://github.com/ogurecapps/flexible-rest-client.git
```
Clone the repo into a local directory and copy the `FlexibleREST` package into your project

## Launch of test Production
After installing the package, you can run `FlexibleREST.Production.Test` in the IRIS Management Portal. Production already has a data stream set up to dummyjson.com. You only need to create a credential named `dummy-json`. You can use `{"username": "emilys", "password": "emilyspass"}` or take any from here: [https://dummyjson.com/users](https://dummyjson.com/users).
