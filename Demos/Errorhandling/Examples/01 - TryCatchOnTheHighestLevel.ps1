#################################################

#################################################
$script:headers

#region functions
function Get-ExampleUser {
    [CmdletBinding()]
    param (
        $Id
    )
    Invoke-RestMethod -Uri "$($actionContext.Configuration.BaseUrl)api/user/$Id" -Method 'GET' -Headers $script:headers
}
#endregion

try {
    # Get token
    try {
        $splatGetTokenParams = @{
            Uri = "$($actionContext.Configuration.BaseUrl)/api/auth/token"
            Method = 'POST'
            Body = @{
                ClientId = $($actionContext.Configuration.ClientId)
                ClientSecret = $($actionContext.Configuration.ClientSecret)
            } | ConvertTo-Json
            ContentType = 'application/json'
        }
        $responseToken = Invoke-RestMethod @splatGetTokenParams
    } catch {
        throw
    }

    # Set headers
    $script:headers = @{
        Authorization = "Bearer $($responseToken.token)"
        'Accept-Language' = 'en'
    }

    # Determine if a user needs to be [created] or [correlated]
    $correlatedAccount = Get-ExampleUser -Id 100

    if ($null -ne $correlatedAccount){
        $action = 'CreateAccount'
    } else {
        $action = 'CorrelateAcccount'
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            break
        }

        'CorrelateAccount' {
            break
        }
    }
} catch {
    $ex = $PSItem
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
}