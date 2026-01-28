#!/bin/bash
# 사용법: ./find_all.sh [경로] "검색어"

# --- 1. 인자 파싱 (경로/검색어 구분) ---
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

# --- 2. 도구 확인 및 분기 (rg vs grep/zipgrep) ---

if command -v rg &> /dev/null; then
    # [CASE A] rg(ripgrep)이 설치된 경우 (빠름)
    echo ">> [도구] 'rg' (ripgrep)가 감지되었습니다. 고속 검색을 시작합니다."
    
    echo ""
    echo "--- [1] 일반 파일 검색 (rg) ---"
    # -n:줄번호, -i:대소문자무시, --glob:압축파일제외
    rg -n -i "$SEARCH_TEXT" "$TARGET_DIR" --glob "!*.{jar,zip}"
    
    echo ""
    echo "--- [2] 압축 파일 검색 (rg -z) ---"
    # --- [2] 압축 파일 검색 (rg -z) --- [수정]
    # -a: 바이너리 파일도 텍스트처럼 검색 (JAR 내부 JSON 검색에 필수)
    # --with-filename: 어느 JAR 파일에서 찾았는지 표시
    rg -z -i -a --with-filename "$SEARCH_TEXT" "$TARGET_DIR" --glob "*.{jar,zip}"

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
