#################################################################################
# Account creation may fail on the first attempt due to network or server issues.
# To handle this, we've implemented a retry mechanism to attempt the
# creation process max. 2 times before finally throwing an error.
#################################################################################
$script:headers
$action = 'CreateAccount'

#region functions
#endregion functions

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
        'SimulateFailure' = $true # Special setting within the demo API to simulate retry logic
        'RetryCount' = 2 # Special setting within the demo API to simulate retry logic
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            try {
                $splatParams = @{
                    Uri = "$($actionContext.Configuration.BaseUrl)/api/user"
                    Method = 'POST'
                    Body = $actionContext.Data | ConvertTo-Json
                    Headers = $script:headers
                    ContentType = 'application/json'
                }
                $createdAccount = Invoke-RestMethod @splatParams
            } catch {
                if ($_.Exception.StatusCode -eq 408){
                    try {
                        Start-Sleep -Seconds 1
                        $createdAccount = Invoke-RestMethod @splatParams
                    } catch {
                        if ($_.Exception.StatusCode -eq 408){
                            try {
                                Start-Sleep -Seconds 1
                                $createdAccount = Invoke-RestMethod @splatParams
                            } catch {
                                throw
                            }
                        } else {
                            throw
                        }
                    }
                } else {
                    throw
                }
            }
            $outputContext.Data = $createdAccount
            $outputContext.AccountReference = $createdAccount.Id
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = $action
            Message = $auditLogMessage
            IsError = $false
        })
} catch {
    $ex = $PSItem
    Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
}