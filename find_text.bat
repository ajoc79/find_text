@echo off
setlocal
:: [사용법] find_all.bat [경로] "검색어"

:: --- 1. 인자 파싱 ---
if "%~2"=="" (
    set "TARGET_DIR=."
    set "FIND_TEXT=%~1"
) else (
    set "TARGET_DIR=%~1"
    set "FIND_TEXT=%~2"
)

if "%FIND_TEXT%"=="" (
    echo [사용법] find_all.bat "경로" "검색어"
    goto :EOF
)

:: --- 네트워크 경로 대응 (Z: 드라이브 매핑) ---
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

:: --- PowerShell 실행 ---
powershell -NoProfile -Command ^
    "$path = '%TARGET_DIR%';" ^
    "$txt = '%FIND_TEXT%';" ^
    "$cwd = (Get-Location).Path;" ^
    "if ($path -eq '.') { $path = $cwd };" ^
    "" ^
    "# 1. rg 설치 여부 확인;" ^
    "$hasRg = (Get-Command rg -ErrorAction SilentlyContinue) -ne $null;" ^
    "" ^
    "if ($hasRg) {" ^
        "Write-Host '>> [도구] rg (ripgrep)가 감지되었습니다.' -ForegroundColor Cyan;" ^
        "Write-Host '--- [1] 일반 파일 검색 (rg) ---';" ^
        "# -n:줄번호, -i:대소문자무시, --glob:압축파일제외;" ^
        "rg -n -i $txt $path --glob '!*.{jar,zip}';" ^
    "} else {" ^
        "Write-Host '>> [도구] rg가 없어 PowerShell로 검색합니다. (느림)' -ForegroundColor Yellow;" ^
        "Write-Host '--- [1] 일반 파일 검색 (PS) ---';" ^
        "$files = Get-ChildItem -Path $path -Recurse -File -Exclude *.jar,*.zip;" ^
        "foreach ($f in $files) {" ^
             "$c = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue;" ^
             "if($c -match $txt) { Write-Host ('[파일] ' + $f.FullName) };" ^
        "}" ^
    "}" ^
    "" ^
    "Write-Host '';" ^
    "Write-Host '--- [2] 압축 파일 검색 (.jar, .zip) ---';" ^
    "# Windows에서 rg -z는 불안정하므로 PowerShell ZipFile 기능을 사용합니다.;" ^
    "# [변경점] -a 옵션 대응: 확장자 필터를 제거하고 모든 파일을 읽습니다.;" ^
    "# [변경점] -l 옵션 대응: 내용은 출력하지 않고 위치만 출력합니다.;" ^
    "" ^
    "try { $zips = Get-ChildItem -Path $path -Recurse -Include *.jar,*.zip -ErrorAction SilentlyContinue } catch { exit };" ^
    "Add-Type -A System.IO.Compression.FileSystem;" ^
    "" ^
    "foreach ($z in $zips) {" ^
        "try {" ^
            "$zip = [IO.Compression.ZipFile]::OpenRead($z.FullName);" ^
            "foreach($e in $zip.Entries) {" ^
                "# 폴더(디렉토리) 엔트리는 건너뜀;" ^
                "if($e.Length -eq 0) { continue };" ^
                "" ^
                "try {" ^
                    "$s = $e.Open();" ^
                    "$r = New-Object IO.StreamReader($s);" ^
                    "# 바이너리 파일도 강제로 텍스트로 읽음 (-a 대응);" ^
                    "$content = $r.ReadToEnd();" ^
                    "" ^
                    "if($content -match $txt) {" ^
                         "# 발견 시 경로만 출력 (-l 대응);" ^
                         "Write-Host ('[ZIP내부] ' + $z.Name + ' -> ' + $e.FullName) -ForegroundColor Green;" ^
                    "}" ^
                "} catch {" ^
                    "# 바이너리 읽기 실패 시 조용히 넘어감;" ^
                "} finally {" ^
                    "if ($r) { $r.Dispose() }; if ($s) { $s.Dispose() };" ^
                "}" ^
            "}" ^
            "$zip.Dispose();" ^
        "} catch {}" ^
    "}"

:: --- 네트워크 해제 ---
if exist Z:\ ( c: & net use Z: /delete /y >nul )
