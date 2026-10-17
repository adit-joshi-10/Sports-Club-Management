# SCMS sports endpoint check. Run: .\devtools\test_sports.ps1
$Base = "http://127.0.0.1:8000"

function Login($email, $pw) {
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

$script:fail = 0
function Check($id, $desc, $res, $expected) {
    $ok = ($res.Code -eq $expected)
    if (-not $ok) { $script:fail++ }
    $tag = if ($ok) { "PASS" } else { "FAIL" }
    "{0} T{1,-2} {2} (got {3}, want {4})" -f $tag, $id, $desc, $res.Code, $expected
}

$admin  = Login "admin@scms.demo" "Admin@123"
$member = Login "aarav.sharma@scms.demo" "Member@123"

# Clean up a leftover Tennis row from an earlier partial run
$list = Call GET "/sports" $admin $null
foreach ($s in ($list.Body | ConvertFrom-Json)) {
    if ($s.name -eq "Tennis") { Call DELETE "/sports/$($s.sport_id)" $admin $null | Out-Null }
}

$r = Call GET "/sports" $member $null
Check 1 "member can list sports" $r 200
"      sports returned: $((($r.Body | ConvertFrom-Json) | Measure-Object).Count) (expect 5)"

Check 2 "no token is rejected" (Call GET "/sports" $null $null) 401
Check 3 "member cannot create a sport" (Call POST "/sports" $member '{"name":"Hockey"}') 403

$r = Call POST "/sports" $admin '{"name":"Tennis","description":"Court drills","icon_key":"tennis"}'
Check 4 "admin creates a sport" $r 201
$newId = ($r.Body | ConvertFrom-Json).sport_id

Check 5 "duplicate name is rejected" (Call POST "/sports" $admin '{"name":"tennis"}') 409
Check 6 "too-short name is rejected" (Call POST "/sports" $admin '{"name":"X"}') 422

$r = Call PATCH "/sports/$newId" $admin '{"description":"Singles and doubles"}'
Check 7 "admin edits a sport" $r 200
"      new description: $(($r.Body | ConvertFrom-Json).description)"

Check 8 "missing sport returns 404" (Call GET "/sports/999" $member $null) 404
Check 9 "sport in use cannot be deleted" (Call DELETE "/sports/1" $admin $null) 409
Check 10 "admin deletes the new sport" (Call DELETE "/sports/$newId" $admin $null) 204
Check 11 "deleted sport is gone" (Call GET "/sports/$newId" $admin $null) 404

""
if ($script:fail -eq 0) { "ALL 11 CHECKS PASSED" } else { "$($script:fail) CHECK(S) FAILED" }