#!/usr/bin/env python3
import sys
import os
import zipfile

# 사용법: python3 find_text_py.py "찾을내용"
if len(sys.argv) < 2:
    print("사용법: find_text \"찾을 문자열\"")
    sys.exit(1)

# 검색어 (따옴표로 묶인 문장 전체를 받음)
SEARCH_TEXT = sys.argv[1]

print(f"========================================================")
print(f" 검색 시작: \"{SEARCH_TEXT}\"")
print(f" (현재 위치의 모든 파일 및 .jar/.zip 내부를 검색합니다)")
print(f"========================================================")

def print_refined(file_path, inner_name, content, line_mode=False):
    """
    검색 결과 출력 함수
    - JSON 파일은 콤마(,) 단위로 잘라서 보여줌 (가독성 UP)
    - 일반 텍스트는 줄 단위로 보여줌
    """
    if line_mode:
        # 일반 텍스트 파일 모드 (줄바꿈 기준)
        lines = content.splitlines()
        for i, line in enumerate(lines, 1):
            if SEARCH_TEXT in line:
                print(f"[일반] {file_path} ({i}행)\n    -> {line.strip()[:200]}")
    else:
        # JSON 데이터 모드 (콤마 기준)
        entries = content.split(',')
        for entry in entries:
            if SEARCH_TEXT in entry:
                clean_entry = entry.strip('{}[] \n\r"\'')
                # 너무 긴 내용은 잘라서 보여줌
                if len(clean_entry) > 300: 
                    clean_entry = clean_entry[:300] + "..."
                
                # 내부 경로가 있으면(압축파일) 표시, 없으면 파일명만 표시
                location = f"{file_path} -> {inner_name}" if inner_name != file_path else file_path
                print(f"[발견] {location}\n    -> {clean_entry}")

# 현재 디렉토리부터 하위 폴더까지 탐색
for root, dirs, files in os.walk('.'):
    for file in files:
        full_path = os.path.join(root, file)
        
        # 1. 압축 파일 (.jar, .zip) 검색
        if file.endswith(('.jar', '.zip')):
            try:
                with zipfile.ZipFile(full_path) as z:
                    for name in z.namelist():
                        # 텍스트로 된 설정 파일들만 검사
                        if name.endswith(('.json', '.lang', '.txt', '.mcfunction', '.toml')):
                            try:
                                content = z.read(name).decode('utf-8', 'ignore')
                                if SEARCH_TEXT in content:
                                    print_refined(full_path, name, content, line_mode=False)
                            except: pass
            except: pass
            
        # 2. 일반 텍스트 파일 (.json, .txt 등) 검색
        elif file.endswith(('.json', '.lang', '.txt', '.mcfunction', '.toml', '.md')):
            try:
                with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    if SEARCH_TEXT in content:
                        # JSON 확장자는 콤마 기준으로, 나머지는 줄 단위로
                        is_line_mode = not file.endswith(('.json', '.lang'))
                        print_refined(full_path, full_path, content, line_mode=is_line_mode)
            except: pass

print("\n검색 완료.")
