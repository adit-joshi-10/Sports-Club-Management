# Member endpoint checks. Run: .\devtools\test_members.ps1
. "$PSScriptRoot\common.ps1"

$admin  = Token "admin@scms.demo" "Admin@123"
$coach  = Token "vikram.rathore@scms.demo" "Coach@123"
$member = Token "aarav.sharma@scms.demo" "Member@123"   # member_id 1

# Remove a leftover test member from an earlier run
$all = Call GET "/members" $admin $null
foreach ($m in ($all.Body | ConvertFrom-Json)) {
    if ($m.email -eq "test.player@scms.demo") { Call DELETE "/members/$($m.member_id)" $admin $null | Out-Null }
}

$r = Call GET "/members" $admin $null
Check 1 "admin lists members" $r 200
"      members returned: $(($r.Body | ConvertFrom-Json) | Measure-Object).Count) (expect 8)"
Check 2 "coach cannot list members" (Call GET "/members" $coach $null) 403
Check 3 "member cannot list members" (Call GET "/members" $member $null) 403
Check 4 "no token is rejected" (Call GET "/members" $null $null) 401

$newBody = '{"email":"test.player@scms.demo","password":"Player@123","full_name":"Test Player","phone":"9199999999","date_of_birth":"2004-06-01"}'
$r = Call POST "/members" $admin $newBody
Check 5 "admin creates a member" $r 201
$newId = ($r.Body | ConvertFrom-Json).member_id
$leak = @{ Code = $(if ($r.Body -match "password") { 1 } else { 0 }); Body = "" }
Check 6 "response contains no password field" $leak 0

Check 7 "duplicate email rejected (case-insensitive)" (Call POST "/members" $admin '{"email":"TEST.PLAYER@scms.demo","password":"Player@123","full_name":"Dup Player"}') 409
Check 8 "short password rejected" (Call POST "/members" $admin '{"email":"x.y@scms.demo","password":"abc","full_name":"Xy Zed"}') 422
Check 9 "invalid email rejected" (Call POST "/members" $admin '{"email":"not-an-email","password":"Player@123","full_name":"Xy Zed"}') 422
Check 10 "new member can log in" (Call POST "/auth/login" $null '{"email":"test.player@scms.demo","password":"Player@123"}') 200

$r = Call PATCH "/members/$newId" $admin '{"phone":"9188888888"}'
Check 11 "admin edits a member" $r 200
"      new phone: $(($r.Body | ConvertFrom-Json).phone)"

Check 12 "member reads own profile (/me)" (Call GET "/members/me" $member $null) 200
Check 13 "member reads own record by id" (Call GET "/members/1" $member $null) 200
Check 14 "member cannot read another member" (Call GET "/members/2" $member $null) 403
Check 15 "coach cannot read a member record" (Call GET "/members/1" $coach $null) 403
Check 16 "missing member returns 404" (Call GET "/members/999" $admin $null) 404

$r = Call GET "/members?search=diya" $admin $null
Check 17 "search finds a member" $r 200
"      search 'diya' returned: $(@($r.Body | ConvertFrom-Json).Count) (expect 1)"

Check 18 "admin deletes the test member" (Call DELETE "/members/$newId" $admin $null) 204
Check 19 "deleted member is gone" (Call GET "/members/$newId" $admin $null) 404
Check 20 "deleted member cannot log in" (Call POST "/auth/login" $null '{"email":"test.player@scms.demo","password":"Player@123"}') 401

Summary 20