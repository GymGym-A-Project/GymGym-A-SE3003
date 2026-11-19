param(
  [string]$LogPath = (Join-Path $env:TEMP 'gymgym-m3-demo-test.log'),
  [string]$AdbPath = 'C:\Android\platform-tools\adb.exe'
)
$ErrorActionPreference = 'Stop'
$demoOutput = Join-Path $PSScriptRoot '../output/m3-demo'
New-Item -ItemType Directory -Force $demoOutput | Out-Null
$deadline = (Get-Date).AddMinutes(4)
do {
  $log = Get-Content -LiteralPath $LogPath -Raw -ErrorAction SilentlyContinue
  if ($log -match 'M3_DEMO_READY') { break }
  if ($log -match 'Some tests failed|Script exited unsuccessfully|Error: Script') {
    throw 'Demo failed before recording'
  }
  Start-Sleep -Milliseconds 400
} while ((Get-Date) -lt $deadline)
if ($log -notmatch 'M3_DEMO_READY') { throw 'Ready marker timed out' }
$record = Start-Process -FilePath $AdbPath -ArgumentList 'shell screenrecord --bit-rate 4000000 --time-limit 44 /sdcard/gymgym-m3-demo.mp4' -WindowStyle Hidden -PassThru
$timer = [Diagnostics.Stopwatch]::StartNew()
$captured = @{}
Write-Output 'Demo recording started'
while (-not $record.HasExited) {
  $log = Get-Content -LiteralPath $LogPath -Raw
  foreach ($stage in @('ROUTINE', 'GHOSTS', 'ACCEPTED', 'SUMMARY', 'HISTORY', 'FINISHED')) {
    if (($log -match "M3_DEMO_$stage") -and (-not $captured.ContainsKey($stage))) {
      $captured[$stage] = [Math]::Round($timer.Elapsed.TotalSeconds, 3)
      if ($stage -ne 'FINISHED') {
        & $AdbPath shell screencap -p "/sdcard/m3-$stage.png"
        & $AdbPath pull "/sdcard/m3-$stage.png" (Join-Path $demoOutput "$stage.png")
      }
    }
  }
  Start-Sleep -Milliseconds 300
  $record.Refresh()
}
if ($record.ExitCode -ne 0) { throw 'Android screenrecord failed' }
& $AdbPath pull /sdcard/gymgym-m3-demo.mp4 (Join-Path $demoOutput 'GymGym-A_M3_Android_Demo_raw.mp4')
if ($LASTEXITCODE -ne 0) { throw 'Video pull failed' }
$captured | ConvertTo-Json | Set-Content (Join-Path $demoOutput 'markers.json')
if ($captured.Count -ne 6) { throw 'Not all demo stages completed; inspect the test log' }
Write-Output "Demo captured to $demoOutput"
