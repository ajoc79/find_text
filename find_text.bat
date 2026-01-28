@echo off
setlocal
:: [사용법] find_all.bat "검색어" 
:: [기능] rg가 설치되어 있으면 일반 파일 검색에 rg를 사용(고속), 없으면 PowerShell 내장 기능 사용

set "FIND_TEXT=%~1"
if "%FIND_TEXT%"=="" (
    set "FIND_TEXT=%~2"
    set "TARGET_DIR=%~1"
) else (
    set "TARGET_DIR=."
)

if "%FIND_TEXT%"=="" (
    echo [사용법] find_all.bat "경로" "검색어"
    goto :EOF
)

:: 네트워크 경로 대응
echo %~dp0 | findstr /B "\\" >nul
if %errorlevel% equ 0 (
    if exist Z:\ net use Z: /delete /y >nul
    net use Z: "%~dp0." >nul
    Z:
)

echo ========================================================
echo  대상 경로: %TARGET_DIR%
echo  검색 내용: "%FIND_TEXT%"
echo ========================================================

powershell -NoProfile -Command ^
    "$path = '%TARGET_DIR%';" ^
    "$txt = '%FIND_TEXT%';" ^
    "$cwd = (Get-Location).Path;" ^
    "if ($path -eq '.') { $path = $cwd };" ^
    "" ^
    "# 1. rg 설치 여부 확인;" ^
    "$hasRg = (Get-Command rg -ErrorAction SilentlyContinue) -ne $null;" ^
    "if ($hasRg) { Write-Host '>> [가속 모드] ripgrep(rg)을 사용하여 일반 파일을 검색합니다.' -ForegroundColor Cyan } " ^
    "else { Write-Host '>> [일반 모드] rg가 없어 PowerShell로 검색합니다. (속도 느림)' -ForegroundColor Yellow };" ^
    "" ^
    "# 2. 파일 순회 시작;" ^
    "try { $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction Stop } catch { Write-Warning '경로 접근 불가'; exit };" ^
    "" ^
    "foreach ($f in $files) {" ^
        "if ($f.Attributes -match 'Directory') { continue }" ^
        "try {" ^
            "# [A] 압축 파일 (.jar, .zip) -> PowerShell 방식 유지 (가장 안정적);" ^
            "if ($f.Extension -match '\.(jar|zip)$') {" ^
                "$zip = [IO.Compression.ZipFile]::OpenRead($f.FullName);" ^
                "foreach($e in $zip.Entries) {" ^
                    "if($e.Name -match '\.(json|lang|txt|toml|yml|mcfunction)$') {" ^
                        "$s = $e.Open(); $r = New-Object IO.StreamReader($s); $t = $r.ReadToEnd();" ^
                        "if($t -match $txt) { Write-Host ('[ZIP내부] ' + $f.Name + ' -> ' + $e.FullName) -ForegroundColor Green };" ^
                        "$r.Dispose(); $s.Dispose();" ^
                    "}" ^
                "}" ^
                "$zip.Dispose();" ^
            "}" ^
            "# [B] 일반 파일 -> rg 있으면 rg 사용, 없으면 PS 사용;" ^
            "elseif ($f.Extension -match '\.(json|lang|txt|toml|yml|mcfunction)$') {" ^
                "if ($hasRg) {" ^
                    "# rg 사용 (외부 프로세스 호출);" ^
                    "$args = @('-n', '-i', '--no-heading', $txt, $f.FullName);" ^
                    "$res = & rg $args;" ^
                    "if ($res) { Write-Host $res };" ^
                "} else {" ^
                    "# PS 사용;" ^
                    "$c = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue;" ^
                    "if($c -match $txt) { Write-Host ('[파일] ' + $f.FullName) -ForegroundColor White };" ^
                "}" ^
            "}" ^
        "} catch {}" ^
    "}"

if exist Z:\ ( c: & net use Z: /delete /y >nul )
