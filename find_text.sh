#!/bin/bash
# 사용법 1: ./find_all.sh "검색어"             (현재 위치에서 검색)
# 사용법 2: ./find_all.sh "경로" "검색어"       (지정 경로에서 검색)
# ./find_text.sh mods/ "ancient wonders"       (특정 하위 폴더(mods)만 검색 (상대 경로))
# ./find_text.sh /volume2/docker/mc_verse/data/mods/ "ancient wonders"  (절대 경로로 검색 (어디서든 실행 가능))

# 인자 개수 확인
if [ "$#" -eq 2 ]; then
    # 인자가 2개면: 첫 번째는 경로, 두 번째는 검색어
    TARGET_DIR="$1"
    SEARCH_TEXT="$2"
else
    # 인자가 1개(혹은 그 외)면: 현재 위치(.)에서 검색어($1) 검색
    TARGET_DIR="."
    SEARCH_TEXT="$1"
fi

# 필수 확인: 검색어가 비어있으면 종료
if [ -z "$SEARCH_TEXT" ]; then
    echo "사용법 오류:"
    echo "  1. ./find_all.sh \"검색어\""
    echo "  2. ./find_all.sh /특정/경로/ \"검색어\""
    exit 1
fi

# 필수 확인: 경로가 실제로 존재하는지 확인
if [ ! -d "$TARGET_DIR" ]; then
    echo "오류: 경로를 찾을 수 없습니다 -> $TARGET_DIR"
    echo "팁: 현재 폴더 안의 하위 폴더는 앞의 슬래시(/)를 빼고 입력하세요. (예: mods/)"
    exit 1
fi

echo "========================================================"
echo " 대상 경로: $TARGET_DIR"
echo " 검색 내용: \"$SEARCH_TEXT\" (대소문자 무시)"
echo "========================================================"

echo ""
echo ">>> [1/2] 일반 파일 검색 중..."
# -r:재귀, -n:줄번호, -i:대소문자무시
# --include 지정보다는 --exclude로 압축파일만 빼는 게 안전
grep -rni "$SEARCH_TEXT" "$TARGET_DIR" --exclude=*.{jar,zip} 2>/dev/null

echo ""
echo ">>> [2/2] 압축 파일(.jar, .zip) 내부 검색 중..."
# find로 경로 내의 jar/zip 찾기 -> xargs로 넘겨서 -> zipgrep 실행
find "$TARGET_DIR" -type f \( -name "*.jar" -o -name "*.zip" \) -print0 | xargs -0 -I {} sh -c "
    if zipgrep -iq \"$SEARCH_TEXT\" \"{}\"; then
        echo \"[발견] 압축파일: {}\"
        # 상세 내용을 보려면 아래 주석 해제 (# 제거)
        # zipgrep -ni \"$SEARCH_TEXT\" \"{}\"
    fi
"

echo ""
echo "검색 완료."
