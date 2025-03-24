$baseUrl = $actionContext.Configuration.BaseUrl

function Resolve-HandlingErrorsGracefullyError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            if (![string]::IsNullOrEmpty($errorDetailsObject.detail)){
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.detail
            }elseif ($null -ne $errorDetailsObject.errors){
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.errors.Email
            } else {
                $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
            }
        } catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}

$splatGetTokenParams = @{
    Uri = "$baseUrl/api/auth/token"
    Method = 'POST'
    Body = @{
        ClientId = 'demo'
        ClientSecret = 'demo'
    } | ConvertTo-Json
    ContentType = 'application/json'
}
$responseToken = Invoke-RestMethod @splatGetTokenParams
    $headers = @{
    Authorization = "Bearer $($responseToken.token)"
    'Accept-Language' = 'en'
}

try {
    Invoke-RestMethod -Uri "$baseUrl/api/user/100" -Method 'GET' -Headers $headers
} catch {
    $errorObj1 = Resolve-HandlingErrorsGracefullyError -ErrorObject $_

    Write-Host "Get user on <id>" -fore Magenta
    Write-Host -Fore Cyan "Exception information"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host -Fore Yellow "PowerShell version    : $($PSVersionTable.PSVersion)"
    Write-Host -Fore Red "Exception of type        : $($_.Exception.GetType())"
    Write-Host -Fore Red "FriendlyMessage message  : $($errorObj1.FriendlyMessage)"
    Write-Host -Fore Red "ErrorDetails             : Error at Line '$($errorObj1.ScriptLineNumber)': $($errorObj1.Line). Error: $($errorObj1.ErrorDetails)"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host ""
}

try {
    Invoke-RestMethod -Uri "$baseUrl/api/user/search?email=ac.doe@example" -Method 'GET' -Headers $headers
} catch {
    $errorObj2 = Resolve-HandlingErrorsGracefullyError -ErrorObject $_

    Write-Host "Get user on <email>" -fore Magenta
    Write-Host -Fore Cyan "Exception information"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host -Fore Yellow "PowerShell version    : $($PSVersionTable.PSVersion)"
    Write-Host -Fore Red "Exception of type        : $($_.Exception.GetType())"
    Write-Host -Fore Red "FriendlyMessage message  : $($errorObj2.FriendlyMessage)"
    Write-Host -Fore Red "ErrorDetails             : Error at Line '$($errorObj2.ScriptLineNumber)': $($errorObj2.Line). Error: $($errorObj2.ErrorDetails)"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host ""
}

try {
    $body = @{
        firstName = 'Simon'
        lastName = 'Joe'
        description = 'created by PowerShell'
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/api/user" -Method 'POST' -Body $body -Headers $headers -ContentType 'application/json'
} catch {
    $errorObj3 = Resolve-HandlingErrorsGracefullyError -ErrorObject $_

    Write-Host "Create user" -fore Magenta
    Write-Host -Fore Cyan "Exception information"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host -Fore Yellow "PowerShell version    : $($PSVersionTable.PSVersion)"
    Write-Host -Fore Red "Exception of type        : $($_.Exception.GetType())"
    Write-Host -Fore Red "FriendlyMessage message  : $($errorObj3.FriendlyMessage)"
    Write-Host -Fore Red "ErrorDetails             : Error at Line '$($errorObj3.ScriptLineNumber)': $($errorObj3.Line). Error: $($errorObj3.ErrorDetails)"
    Write-Host -Fore Cyan "----------------------------------------------------"
    Write-Host ""
}
