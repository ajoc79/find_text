# 특정 파일 찾기

# DOS 용
1. 현재 폴더 + 하위 폴더 검색
  - find_all.bat "ancient wonders"
2. 특정 하위 폴더(mods) 검색
  - find_all.bat "mods" "ancient wonders"
3. 절대 경로 검색
  - find_all.bat "C:\Users\Game\mods" "ancient wonders"

# 리눅스 용
1. 현재 폴더 + 하위 폴더 전체 검색
  - ./find_text.sh "ancient wonders"
2. 특정 하위 폴더(mods)만 검색 (상대 경로)
  - ./find_text.sh mods/ "ancient wonders"
  - ./find_text.sh ./mods/ "ancient wonders"
3. 절대 경로로 검색 (어디서든 실행 가능)
  - ./find_text.sh /volume2/docker/lol/data/mods/ "ancient wonders"
