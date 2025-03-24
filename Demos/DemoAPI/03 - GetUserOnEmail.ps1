$demoBlock = {
    $baseUrl = 'http://localhost:5240'
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
        Invoke-RestMethod -Uri "$baseUrl/api/user/search?email=ac.doe@example" -Method 'GET' -Headers $headers
    } catch {
        Write-Host ""
        Write-Host -Fore Cyan "Exception information"
        Write-Host -Fore Cyan "----------------------------------------------------"
        Write-Host -Fore Yellow "PowerShell version : $($PSVersionTable.PSVersion)"
        Write-Host -Fore Red "Exception of type  : $($_.Exception.GetType())"
        Write-Host -Fore Red "Exception message  : $($_.Exception.Message)"
        Write-Host -Fore Red "ErrorDetails       : $($_.ErrorDetails.Message)"
        if (!$IsCoreCLR) {
            Write-Host -Fore Red "ResponseStream     : $([System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream()).ReadToEnd())"
        }
        Write-Host -Fore Cyan "----------------------------------------------------"
        Write-Host ""
    }
}.ToString()

pwsh -command $demoBlock
powershell -command $demoBlock
