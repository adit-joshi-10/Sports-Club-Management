# Coach endpoint checks. Run: .\devtools\test_coaches.ps1
. "$PSScriptRoot\common.ps1"

$admin  = Token "admin@scms.demo" "Admin@123"
$coach  = Token "vikram.rathore@scms.demo" "Coach@123"
$member = Token "aarav.sharma@scms.demo" "Member@123"

# Remove a leftover test coach from an earlier run
$all = Call GET "/coaches" $admin $null
foreach ($c in ($all.Body | ConvertFrom-Json)) {
    if ($c.email -eq "test.coach@scms.demo") { Call DELETE "/coaches/$($c.coach_id)" $admin $null | Out-Null }
}

$r = Call GET "/coaches" $admin $null
Check 1 "admin lists coaches" $r 200
"      coaches returned: $((($r.Body | ConvertFrom-Json) | Measure-Object).Count) (expect 3)"
Check 2 "coach cannot list coaches" (Call GET "/coaches" $coach $null) 403
Check 3 "member cannot list coaches" (Call GET "/coaches" $member $null) 403
Check 4 "no token is rejected" (Call GET "/coaches" $null $null) 401

$newBody = '{"email":"test.coach@scms.demo","password":"Coach@12345","full_name":"Test Coach","phone":"9177777777","specialization":"Hockey"}'
$r = Call POST "/coaches" $admin $newBody
Check 5 "admin creates a coach" $r 201
$newId = ($r.Body | ConvertFrom-Json).coach_id
$leak = @{ Code = $(if ($r.Body -match "password") { 1 } else { 0 }); Body = "" }
Check 6 "response contains no password field" $leak 0

Check 7 "duplicate email rejected (case-insensitive)" (Call POST "/coaches" $admin '{"email":"TEST.COACH@scms.demo","password":"Coach@12345","full_name":"Dup Coach"}') 409
Check 8 "short password rejected" (Call POST "/coaches" $admin '{"email":"x.y@scms.demo","password":"abc","full_name":"Xy Zed"}') 422
Check 9 "invalid email rejected" (Call POST "/coaches" $admin '{"email":"not-an-email","password":"Coach@12345","full_name":"Xy Zed"}') 422
Check 10 "new coach can log in" (Call POST "/auth/login" $null '{"email":"test.coach@scms.demo","password":"Coach@12345"}') 200

$r = Call PATCH "/coaches/$newId" $admin '{"specialization":"Field Hockey"}'
Check 11 "admin edits a coach" $r 200
"      new specialization: $(($r.Body | ConvertFrom-Json).specialization)"

Check 12 "coach cannot read a coach record" (Call GET "/coaches/1" $coach $null) 403
Check 13 "missing coach returns 404" (Call GET "/coaches/999" $admin $null) 404

$r = Call GET "/coaches?search=cricket" $admin $null
Check 14 "search finds a coach" $r 200
"      search 'cricket' returned: $((($r.Body | ConvertFrom-Json) | Measure-Object).Count) (expect 1)"

Check 15 "coach with sessions cannot be deleted" (Call DELETE "/coaches/1" $admin $null) 409
Check 16 "that coach still exists" (Call GET "/coaches/1" $admin $null) 200

Check 17 "admin deletes the test coach" (Call DELETE "/coaches/$newId" $admin $null) 204
Check 18 "deleted coach is gone" (Call GET "/coaches/$newId" $admin $null) 404
Check 19 "deleted coach cannot log in" (Call POST "/auth/login" $null '{"email":"test.coach@scms.demo","password":"Coach@12345"}') 401

Summary 19