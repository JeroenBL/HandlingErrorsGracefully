#####################################################################################
# Watcher
#if($allusers.email -contains 'a.doe@example'){Write-Host -fore cyan 'Got Alica Doe'}
#####################################################################################

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

$pageSize = 50
$pageNumber = 1
$totalUsersFetched = 0
$allUsers = [System.Collections.Generic.List[object]]::new()
$totalUsers = 0

do {
    $splatParams = @{
        Uri     = "$($actionContext.Configuration.BaseUrl)/api/user?pageNumber=$pageNumber&pageSize=$pageSize"
        Method  = 'GET'
        Headers = $headers
    }

    $response = Invoke-RestMethod @splatParams
    $users = $response.Users

    $totalUsers = $response.totalUsers
    $totalUsersFetched += $users.Count
    $allUsers.AddRange($users)
    $pageNumber++
} while ($totalUsersFetched -lt $totalUsers)
$allUsers