# Shared test helpers. Dot-sourced by the test scripts.
$Base = "http://127.0.0.1:8000"

function Token($email, $pw) {
    $b = @{ email = $email; password = $pw } | ConvertTo-Json
    (Invoke-RestMethod -Method Post -Uri "$Base/auth/login" -ContentType "application/json" -Body $b).access_token
}

function Call($method, $path, $token, $body) {
    $h = @{}
    if ($token) { $h["Authorization"] = "Bearer $token" }
    $p = @{ Method = $method; Uri = "$Base$path"; Headers = $h; UseBasicParsing = $true }
    if ($body) { $p["Body"] = $body; $p["ContentType"] = "application/json" }
    try {
        $r = Invoke-WebRequest @p
        return @{ Code = [int]$r.StatusCode; Body = $r.Content }
    } catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        return @{ Code = $code; Body = "$($_.ErrorDetails.Message)" }
    }
}

$global:fail = 0
function Check($id, $desc, $res, $expected) {
    $ok = ($res.Code -eq $expected)
    if (-not $ok) { $global:fail++ }
    $tag = if ($ok) { "PASS" } else { "FAIL" }
    "{0} T{1,-2} {2} (got {3}, want {4})" -f $tag, $id, $desc, $res.Code, $expected
}

function Summary($total) {
    ""
    if ($global:fail -eq 0) { "ALL $total CHECKS PASSED" } else { "$($global:fail) CHECK(S) FAILED" }
}