#############################################################
# Prevent error handling based on the messages being
# returned. The error messages might be localized based
# on the 'Accept-Language' header.
# The call to: /api/user/<id> -by default- returns error
# messages in German if the 'Accept-Language' is missing.
#############################################################

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
    $headers = @{
        Authorization = "Bearer $($responseToken.token)"
        #'Accept-Language' = 'en'
    }

    # Determine if a user needs to be [created] or [correlated]
    try {
        $splatParams = @{
            Uri    = "$($actionContext.Configuration.BaseUrl)/api/user/100"
            Method = 'GET'
            Headers = $headers
        }
        $correlatedAccount = Invoke-RestMethod @splatParams
    } catch {
        $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errorMessage.title -eq 'Not Found'){
            $correlatedAccount = $null
        } else {
            throw
        }
    }

    if ($null -ne $correlatedAccount){
        $action = 'CorrelateAcccount'
    } else {
        $action = 'CreateAccount'
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            Write-Information 'Creating HandlingErrorsGracefully account'
            break
        }

        'CorrelateAccount' {
            Write-Information 'Correlating HandlingErrorsGracefully account'
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