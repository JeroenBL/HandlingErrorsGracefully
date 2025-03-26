#################################################################################
# Account creation may fail on the first attempt due to network or server issues.
# To handle this, we've implemented a retry mechanism to attempt the
# creation process max. 2 times before finally throwing an error.
#################################################################################
$script:headers
$action = 'CreateAccount'

#region functions
function Invoke-RestMethodWithRetry {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Params,
        [int]$MaxRetries,
        [int]$RetryDelay
    )

    $retryCount = 0

    while ($retryCount -lt $MaxRetries) {
        try {
            return Invoke-RestMethod @Params
        } catch {
            if ($_.Exception.StatusCode -eq 408) {
                $retryCount++
                if ($retryCount -lt $MaxRetries) {
                    Write-Information "Request timed out. Retrying... ($retryCount/$MaxRetries)"
                    Start-Sleep -Seconds $RetryDelay
                } else {
                    Write-Information 'Max retries reached. Failing...'
                    throw
                }
            } else {
                throw
            }
        }
    }
}
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
        'RetriesBeforeSuccess' = 2 # Special setting within the demo API to simulate retry logic
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            $splatParams = @{
                Uri = "$($actionContext.Configuration.BaseUrl)/api/user"
                Method = 'POST'
                Body = $actionContext.Data | ConvertTo-Json
                Headers = $script:headers
                ContentType = 'application/json'
            }
            $createdAccount = Invoke-RestMethodWithRetry -Params $splatParams -MaxRetries 2 -RetryDelay 1
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