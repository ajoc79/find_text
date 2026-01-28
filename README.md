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

# 환경 변수 및 별명(Alias) 등록
  - 설정 파일 편집: 터미널에서 아래 명령어를 입력하여 사용자 프로필 파일을 엽니다.
1. Bash
  - vi ~/.profile
    - 내용 추가: 파일의 맨 아래에 다음 내용을 추가해 주세요. (스크립트 파일명이 find_text.sh이므로, find_text라고만 입력해도 실행되도록 별칭을 설정합니다.)
      - alias find_text='/volume2/docker/scripts/find_text/find_text.sh'
  - 저장 및 종료:
      - Esc 키를 누릅니다.
      - :wq 를 입력하고 Enter를 눌러 저장하고 나옵니다.
  - 설정 적용: 수정된 내용을 현재 터미널에 바로 적용합니다.
      - source ~/.profile
  - 심볼릭 링크(Symbolic Link) 생성
      - sudo ln -s /volume2/docker/scripts/find_text/find_text.sh /usr/local/bin/find_text

# alias 및 심볼릭 링크 변경
1. .profile 수정 (Alias 변경)
  - vi ~/.profile
  - (파일 맨 아래에 있던 alias find_text=... 줄을 찾아 아래 내용으로 수정(덮어쓰기) 하세요.)
  - alias find_text='python3 /volume2/docker/scripts/find_text/find_text_py.py'
  - 저장 후 적용합니다:
  - source ~/.profile
2. 심볼릭 링크 변경
  - sudo 권한으로 전역 명령어(find_text)를 만드셨다면, 기존 링크를 지우고 새로 연결해야 합니다.
  - 기존 링크 삭제
    - sudo rm /usr/local/bin/find_text
  - 새 파이썬 파일로 링크 생성
    - sudo ln -s /volume2/docker/scripts/find_text/find_text_py.py /usr/local/bin/find_text
