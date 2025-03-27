###########################################################################
# In this example, if Invoke-ExampleRestMethod is called, it has no
# knowledge of who called it. Therefore, if an exception occurs,
# it cannot determine whether the application should stop or
# continue — that decision should be made at a higher level.
# Therefore, its a common best practice to always handle
# errors at the highest possible level.
###########################################################################
$script:headers

#region functions
function Get-ExampleUser {
    [CmdletBinding()]
    param (
        $Id
    )
    Invoke-ExampleRestMethod -Path "user/$Id" -Method 'GET'
}

function Invoke-ExampleRestMethod {
    [CmdletBinding()]
    param (
        $Path,
        $Method
    )

    $splatParams = @{
        Uri = "$($actionContext.Configuration.BaseUrl)/api/$Path"
        Method = $Method
        Headers = $script:headers
    }
    Invoke-RestMethod @splatParams
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
    $correlatedAccount = Get-ExampleUser -Id 3

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