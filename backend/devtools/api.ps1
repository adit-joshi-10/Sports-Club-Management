# Dev helper: load with   . .\devtools\api.ps1
$script:Base = "http://127.0.0.1:8000"

function Login($email, $password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    (Invoke-RestMethod -Method Post -Uri "$script:Base/auth/login" -ContentType "application/json" -Body $body).access_token
}

function Api($method, $path, $token = $null, $body = $null) {
    $headers = @{}
    if ($token) { $headers["Authorization"] = "Bearer $token" }
    $p = @{ Method = $method; Uri = "$script:Base$path"; Headers = $headers; UseBasicParsing = $true }
    if ($body) { $p["Body"] = $body; $p["ContentType"] = "application/json" }
    try {
        $r = Invoke-WebRequest @p
        "HTTP $($r.StatusCode) $($r.Content)"
    } catch {
        "HTTP $($_.Exception.Response.StatusCode.value__) $($_.ErrorDetails.Message)"
    }
}
