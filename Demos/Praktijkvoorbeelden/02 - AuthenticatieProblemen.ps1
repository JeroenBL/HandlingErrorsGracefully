# Invalid credentials - 401
$splatGetTokenParams = @{
    Uri = "$($actionContext.Configuration.BaseUrl)/api/auth/token"
    Method = 'POST'
    Body = @{
        ClientId = 'demo'
        ClientSecret = 'deme'
    } | ConvertTo-Json
    ContentType = 'application/json'
}
$responseToken = Invoke-RestMethod @splatGetTokenParams

# Resource not accessible - 403
$splatGetTokenParams = @{
    Uri = "$($actionContext.Configuration.BaseUrl)/api/auth/token"
    Method = 'POST'
    Body = @{
        ClientId = 'demo'
        ClientSecret = 'demo'
    } | ConvertTo-Json
    ContentType = 'application/json'
}
$responseToken = Invoke-RestMethod @splatGetTokenParams

$splatParams = @{
    Uri = "$($actionContext.Configuration.BaseUrl)/api/user/testconnection"
    Method = 'GET'
    Headers = @{Authorization = "Bearer $($responseToken.token)"}
}
Invoke-RestMethod @splatParams

