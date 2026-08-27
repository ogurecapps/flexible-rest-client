# Flexible REST API Client for IRIS Interoperability (Ensemble)
## Features
- Based on `EnsLib.REST.Operation`
- Extensible architecture
- Support request/response converting from/to UTF8, JS, etc. (useful when using an IRIS instance with a national locale)
- Support HTTP headers
- Support cookie modification
- Sending request as text body (JSON, XML, etc.) or as Form Data
- Getting a character or binary response body (files)
- Basic, Header, or Cookie authentication in simple cases
- An easy way to connect custom authentication providers for complex use cases (retrieving and renewing tokens, managing expiration dates, and so on). See the `TokenProviderClass` setting and `FlexibleREST.Auth.AbstractProvider` class
- Sharing a token between many business operations (see `TokenKey` setting)
- Correct work with tokens in a multi-threaded mode of a single business operation (`Pool Size > 1`)
- Two-level token cache: in process memory and on hard disk
- Masking sensitive data in logs
- Included a flexible OAuth-like token provider (implementation of the `AbstractProvider` interface). You can use it as a sample for your own provider implementation
- Support for `refresh_token`
- `TokenSkew` - early refreshing
- Customizable auth style on token receiving: `body`, `basic`, `parameters` (see `TokenAuthStyle` setting)
- Customizable token request body format: `form` (x-www-form-urlencoded) or `json` (if you use `TokenAuthStyle = body`)
- Read and write token-related data from/to any fields. You only need to specify the field names, nesting is allowed! For example: `data.access_token` or `accessToken`
- The token expiration date can be specified in seconds or as a Unix timestamp (in UTC0)
- The default time-to-live of the token is supported (`TokenDefaultTTL`)
- Customizable `grant_type` and token `scope`
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
