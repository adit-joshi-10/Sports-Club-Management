# Registration, schedule and attendance checks. Run: .\devtools\test_club.ps1
. "$PSScriptRoot\common.ps1"

$admin  = Token "admin@scms.demo" "Admin@123"
$coach1 = Token "vikram.rathore@scms.demo" "Coach@123"   # coach 1 (Football)
$coach2 = Token "neha.kapoor@scms.demo" "Coach@123"      # coach 2
$aarav  = Token "aarav.sharma@scms.demo" "Member@123"    # member 1 (Football, Cricket)
$date = (Get-Date).AddDays(10).ToString("yyyy-MM-dd")

function Num($res) { (($res.Body | ConvertFrom-Json) | Measure-Object).Count }
function Has($res, $field, $value) {
    ((($res.Body | ConvertFrom-Json) | Where-Object { $_.$field -eq $value }) | Measure-Object).Count -gt 0
}
function Flag($b) { @{ Code = [int][bool]$b } }

# Clean up leftovers from an earlier partial run
foreach ($s in ((Call GET "/schedules" $admin $null).Body | ConvertFrom-Json)) {
    if ($s.venue -eq "Test Ground") { Call DELETE "/schedules/$($s.schedule_id)" $admin $null | Out-Null }
}
foreach ($g in ((Call GET "/registrations/me" $aarav $null).Body | ConvertFrom-Json)) {
    if ($g.sport_name -eq "Swimming") { Call DELETE "/registrations/$($g.registration_id)" $aarav $null | Out-Null }
}

# ---------------- registrations
$r = Call GET "/registrations/me" $aarav $null
Check 1 "member lists own registrations" $r 200
"      Aarav registrations: $(Num $r) (expect 2)"
Check 2 "admin has no member profile (/me)" (Call GET "/registrations/me" $admin $null) 403
Check 3 "member cannot list all registrations" (Call GET "/registrations" $aarav $null) 403
$r = Call GET "/registrations" $admin $null
Check 4 "admin lists all registrations" $r 200
"      all registrations: $(Num $r) (expect 14)"
$other = (($r.Body | ConvertFrom-Json) | Where-Object { $_.member_id -ne 1 } | Select-Object -First 1)

$r = Call POST "/registrations" $aarav '{"sport_id":5}'
Check 5 "member registers for Swimming" $r 201
$regId = ($r.Body | ConvertFrom-Json).registration_id
Check 6 "duplicate registration rejected" (Call POST "/registrations" $aarav '{"sport_id":5}') 409
Check 7 "unknown sport returns 404" (Call POST "/registrations" $aarav '{"sport_id":999}') 404
Check 8 "coach cannot register for a sport" (Call POST "/registrations" $coach1 '{"sport_id":5}') 403
Check 9 "member cannot cancel another member's registration" (Call DELETE "/registrations/$($other.registration_id)" $aarav $null) 403
Check 10 "member cancels own registration" (Call DELETE "/registrations/$regId" $aarav $null) 204

# ---------------- schedules
$body = @{ sport_id = 1; coach_id = 1; session_date = $date; start_time = "17:00"; end_time = "18:30"; venue = "Test Ground"; notes = "Test" } | ConvertTo-Json -Compress
$bad  = @{ sport_id = 1; coach_id = 1; session_date = $date; start_time = "18:30"; end_time = "17:00"; venue = "Test Ground" } | ConvertTo-Json -Compress
$noCoach = @{ sport_id = 1; coach_id = 999; session_date = $date; start_time = "17:00"; end_time = "18:30"; venue = "Test Ground" } | ConvertTo-Json -Compress

Check 11 "member cannot create a session" (Call POST "/schedules" $aarav $body) 403
$r = Call POST "/schedules" $admin $body
Check 12 "admin creates a session" $r 201
$sid = ($r.Body | ConvertFrom-Json).schedule_id
Check 13 "end before start rejected" (Call POST "/schedules" $admin $bad) 422
Check 14 "unknown coach returns 404" (Call POST "/schedules" $admin $noCoach) 404
Check 15 "member sees session of a joined sport" (Flag (Has (Call GET "/schedules" $aarav $null) "venue" "Test Ground")) 1
Check 16 "other coach does not see it" (Flag (Has (Call GET "/schedules" $coach2 $null) "venue" "Test Ground")) 0
Check 17 "owning coach sees it" (Flag (Has (Call GET "/schedules" $coach1 $null) "venue" "Test Ground")) 1
Check 18 "admin edits a session" (Call PATCH "/schedules/$sid" $admin '{"notes":"Bring bibs"}') 200

# ---------------- roster and attendance
$r = Call GET "/schedules/$sid/roster" $coach1 $null
Check 19 "owning coach reads the roster" $r 200
"      roster size: $(Num $r) (expect 4 Football players)"
Check 20 "other coach cannot read the roster" (Call GET "/schedules/$sid/roster" $coach2 $null) 403
Check 21 "member cannot read the roster" (Call GET "/schedules/$sid/roster" $aarav $null) 403

$mark = @{ schedule_id = $sid; member_id = 1; status = "present" } | ConvertTo-Json -Compress
$r = Call POST "/attendance" $coach1 $mark
Check 22 "coach marks attendance" $r 201
$aid = ($r.Body | ConvertFrom-Json).attendance_id
Check 23 "duplicate attendance rejected" (Call POST "/attendance" $coach1 $mark) 409
$unreg = @{ schedule_id = $sid; member_id = 2; status = "present" } | ConvertTo-Json -Compress
Check 24 "player not registered for the sport rejected" (Call POST "/attendance" $coach1 $unreg) 400
Check 25 "other coach cannot mark this session" (Call POST "/attendance" $coach2 $mark) 403
$r = Call PATCH "/attendance/$aid" $coach1 '{"status":"late"}'
Check 26 "coach edits attendance" $r 200
"      status now: $(($r.Body | ConvertFrom-Json).status)"
Check 27 "member sees own attendance record" (Flag (Has (Call GET "/attendance/me" $aarav $null) "schedule_id" $sid)) 1
Check 28 "member cannot list all attendance" (Call GET "/attendance" $aarav $null) 403
Check 29 "invalid status rejected" (Call PATCH "/attendance/$aid" $coach1 '{"status":"maybe"}') 422
Check 30 "no token is rejected" (Call GET "/attendance" $null $null) 401

# ---------------- cleanup
Check 31 "admin deletes the session" (Call DELETE "/schedules/$sid" $admin $null) 204
Check 32 "its attendance is deleted with it" (Flag (Has (Call GET "/attendance/me" $aarav $null) "schedule_id" $sid)) 0

Summary 32