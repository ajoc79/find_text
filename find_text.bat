@echo off
setlocal
:: [사용법 1] find_all.bat "검색어"             (현재 폴더 검색)
:: [사용법 2] find_all.bat "경로" "검색어"       (지정 경로 검색)

:: --- 인자 확인 로직 ---
if "%~2"=="" (
    :: 인자가 1개면 -> 현재 위치(.)에서 검색
    set "TARGET_DIR=."
    set "FIND_TEXT=%~1"
) else (
    :: 인자가 2개면 -> 첫번째는 경로, 두번째는 검색어
    set "TARGET_DIR=%~1"
    set "FIND_TEXT=%~2"
)

:: 검색어 누락 확인
if "%FIND_TEXT%"=="" goto Usage

:: --- 네트워크 경로(UNC) 대응 (Z: 드라이브 매핑) ---
echo %~dp0 | findstr /B "\\" >nul
if %errorlevel% equ 0 (
    if exist Z:\ net use Z: /delete /y >nul
    :: 스크립트가 있는 위치를 Z:로 잡습니다.
    net use Z: "%~dp0." >nul
    Z:
)

echo ========================================================
echo  대상 경로: %TARGET_DIR%
echo  검색 내용: "%FIND_TEXT%" (대소문자 무시)
echo ========================================================

:: --- PowerShell 실행 ---
powershell -NoProfile -Command ^
    "Add-Type -A System.IO.Compression.FileSystem;" ^
    "$searchTxt = '%FIND_TEXT%';" ^
    "$targetPath = '%TARGET_DIR%';" ^
    "$cwd = (Get-Location).Path;" ^
    "if ($targetPath -eq '.') { $targetPath = $cwd };" ^
    "try { $files = Get-ChildItem -Path $targetPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning '경로를 찾을 수 없거나 접근할 수 없습니다: ' + $targetPath; exit };" ^
    "foreach ($f in $files) {" ^
        "if ($f.Attributes -match 'Directory') { continue }" ^
        "try {" ^
            ":: [1] 압축 파일(.jar, .zip) 내부 검색 ;" ^
            "if ($f.Extension -match '\.(jar|zip)$') {" ^
                "$zip = [IO.Compression.ZipFile]::OpenRead($f.FullName);" ^
                "foreach($e in $zip.Entries) {" ^
                    "if($e.Name -match '\.(json|lang|txt|toml|yml|mcfunction)$') {" ^
                        "$s = $e.Open(); $r = New-Object IO.StreamReader($s); $t = $r.ReadToEnd();" ^
                        "if($t -match $searchTxt) { Write-Host ('[ZIP내부] ' + $f.Name + ' -> ' + $e.FullName) -ForegroundColor Cyan };" ^
                        "$r.Dispose(); $s.Dispose();" ^
                    "}" ^
                "}" ^
                "$zip.Dispose();" ^
            "}" ^
            ":: [2] 일반 텍스트 파일 검색 ;" ^
            "elseif ($f.Extension -match '\.(json|lang|txt|toml|yml|mcfunction)$') {" ^
                "$content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue;" ^
                "if($content -match $searchTxt) { Write-Host ('[파일] ' + $f.FullName) -ForegroundColor Green };" ^
            "}" ^
        "} catch {}" ^
    "}"

:: --- 네트워크 드라이브 해제 ---
if exist Z:\ ( c: & net use Z: /delete /y >nul )

goto :EOF

:Usage
echo [사용법 오류]
echo 1. 현재 폴더 검색: find_all.bat "검색어"
echo 2. 특정 경로 검색: find_all.bat "폴더명" "검색어"
pause
