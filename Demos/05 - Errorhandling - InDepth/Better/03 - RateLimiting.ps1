#################################################################################
# When retrieving all users using pagination, you might run in a situation where
# the API has rate limiting. Meaning; you can only make a certain amount of API
# calls per minute resulting in a 429 TooManyRequests error.
# To handle this, we need to implement a retry/wait strategy.
#################################################################################
$script:headers
$action = 'CreateAccount'

#region functions
#endregion functions

try {
    $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

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
        'SimulateRateLimiting' = $true # Special setting within the demo API to simulate rate limiting
    }

    $pageSize = 10
    $pageNumber = 1
    $totalUsersFetched = 0
    $allUsers = [System.Collections.Generic.List[object]]::new()
    $totalUsers = 0

    do {
        try {
            $splatParams = @{
                Uri     = "$($actionContext.Configuration.BaseUrl)/api/user?pageNumber=$pageNumber&pageSize=$pageSize"
                Method  = 'GET'
                Headers = $script:headers
            }

            $response = Invoke-RestMethod @splatParams
            $users = $response.Users

            $totalUsers = $response.totalUsers
            $totalUsersFetched += $users.Count
            $allUsers.AddRange($users)
            $pageNumber++
        } catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                $retryAfter = $_.Exception.Response.Headers.RetryAfter.Delta.Seconds
                if ($retryAfter) {
                    Start-Sleep -Seconds $retryAfter
                }
            } else {
                throw
            }
        }
    } while ($totalUsersFetched -lt $totalUsers)

    # Determine if a user needs to be [created] or [correlated]
    $correlatedAccount = $allUsers | Where-Object { $_.email -eq $correlationValue }
    if ($null -ne $correlatedAccount){
        $action = 'CorrelateAccount'
    }


    # Process
    switch ($action) {
        'CorrelateAccount' {
            Write-Information 'Correlating HandlingErrorsGracefully account'

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