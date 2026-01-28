#!/bin/bash
# 사용법: ./find_all.sh [경로] "검색어"

# --- 1. 인자 파싱 ---
if [ "$#" -eq 2 ]; then
    TARGET_DIR="$1"
    SEARCH_TEXT="$2"
else
    TARGET_DIR="."
    SEARCH_TEXT="$1"
fi

# 필수 체크
if [ -z "$SEARCH_TEXT" ]; then
    echo "사용법: ./find_all.sh [경로] \"검색어\""
    exit 1
fi
if [ ! -d "$TARGET_DIR" ]; then
    echo "오류: 경로가 존재하지 않습니다 -> $TARGET_DIR"
    exit 1
fi

echo "========================================================"
echo " 대상 경로: $TARGET_DIR"
echo " 검색 내용: \"$SEARCH_TEXT\""
echo "========================================================"

# --- 2. 검색 실행 ---

if command -v rg &> /dev/null; then
    # [CASE A] rg (ripgrep) 사용 - 고속 모드
    echo ">> [도구] 'rg'로 검색합니다. (멀티라인 지원)"
    
    echo ""
    echo "--- [1] 일반 파일 검색 ---"
    # -U: 여러 줄(멀티라인) 매칭 허용
    # --multiline-dotall: .이 엔터도 포함하게 함
    # [수정] -a 옵션 추가: 바이너리 파일(NBT, DAT 등)도 텍스트로 취급하여 검색
    rg -n -i -a -U --multiline-dotall "$SEARCH_TEXT" "$TARGET_DIR" --glob "!*.{jar,zip}"
    
    echo ""
    echo "--- [2] 압축 파일(.jar, .zip) 검색 ---"
    python3 -c "
        import zipfile, os
        target_dir = '$TARGET_DIR'
        search_text = '$SEARCH_TEXT'
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if file.endswith(('.zip', '.jar')):
                    p = os.path.join(root, file)
                    try:
                        with zipfile.ZipFile(p) as z:
                            for name in z.namelist():
                                if name.endswith(('.json', '.lang', '.mcfunction', '.txt')):
                                    content = z.read(name).decode('utf-8', 'ignore')
                                    if search_text in content:
                                        print(f'[발견] {p} -> {name}')
                    except: pass
            "
else
    # [CASE B] rg가 없는 경우 -> grep + zipgrep 사용 (호환성)
    echo ">> [도구] 'rg'가 없습니다. 표준 도구(grep, zipgrep)로 전환합니다."
    
    echo ""
    echo "--- [1] 일반 파일 검색 (grep) ---"
    grep -rni "$SEARCH_TEXT" "$TARGET_DIR" --exclude=*.{jar,zip} 2>/dev/null
    
    echo ""
    echo "--- [2] 압축 파일 검색 (zipgrep) ---"
    if command -v zipgrep &> /dev/null; then
        find "$TARGET_DIR" -type f \( -name "*.jar" -o -name "*.zip" \) -print0 | xargs -0 -I {} sh -c "
            if zipgrep -iq \"$SEARCH_TEXT\" \"{}\"; then
                echo \"[발견] 압축파일: {}\"
                # zipgrep -ni \"$SEARCH_TEXT\" \"{}\"
            fi
        "
    else
        echo "오류: 'zipgrep'도 설치되어 있지 않습니다. 압축 파일 검색을 건너뜁니다."
        echo "(Synology의 경우 'Unzip' 또는 'SynoCli File Tools' 패키지가 필요합니다)"
    fi
fi

echo ""
echo "검색 완료."
