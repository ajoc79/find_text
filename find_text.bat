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
    "$hasRg = (Get-Command rg -ErrorAction SilentlyContinue) -ne $null;" ^
    "" ^
    "if ($hasRg) {" ^
        "Write-Host '>> [도구] rg (ripgrep)가 감지되었습니다. (멀티라인 지원)' -ForegroundColor Cyan;" ^
        "Write-Host '--- [1] 일반 파일 검색 (rg) ---';" ^
        "# -U: 멀티라인, --multiline-dotall: 엔터 포함 검색;" ^
        "rg -n -i -U --multiline-dotall $txt $path --glob '!*.{jar,zip}';" ^
    "} else {" ^
        "Write-Host '>> [도구] rg가 없어 PowerShell로 검색합니다.' -ForegroundColor Yellow;" ^
        "$files = Get-ChildItem -Path $path -Recurse -File -Exclude *.jar,*.zip;" ^
        "foreach ($f in $files) {" ^
             "$c = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue;" ^
             "if($c -match $txt) { Write-Host ('[파일] ' + $f.FullName) };" ^
        "}" ^
    "}" ^
    "" ^
    "Write-Host '';" ^
    "Write-Host '--- [2] 압축 파일 검색 (.jar, .zip) ---';" ^
    "" ^
    "try { $zips = Get-ChildItem -Path $path -Recurse -Include *.jar,*.zip -ErrorAction SilentlyContinue } catch { exit };" ^
    "Add-Type -A System.IO.Compression.FileSystem;" ^
    "" ^
    "foreach ($z in $zips) {" ^
        "try {" ^
            "$zip = [IO.Compression.ZipFile]::OpenRead($z.FullName);" ^
            "foreach($e in $zip.Entries) {" ^
                "if($e.Length -eq 0) { continue };" ^
                "try {" ^
                    "$s = $e.Open(); $r = New-Object IO.StreamReader($s); $content = $r.ReadToEnd();" ^
                    "# (?s) 옵션: .이 엔터를 포함하도록 설정;" ^
                    "if($content -match '(?s)' + $txt) {" ^
                         "Write-Host ('[ZIP내부] ' + $z.Name + ' -> ' + $e.FullName) -ForegroundColor Green;" ^
                    "}" ^
                "} catch {} finally { if ($r) { $r.Dispose() }; if ($s) { $s.Dispose() }; }" ^
            "}" ^
            "$zip.Dispose();" ^
        "} catch {}" ^
    "}"

if exist Z:\ ( c: & net use Z: /delete /y >nul )
