# 파일·폴더 명명 규칙 (정본)

이 프로젝트의 모든 에이전트·사람은 아래 규칙을 따른다. 새 파일을 만들 때 규칙을 어기지 않는다. (요약은 `AGENTS.md`에, 상세는 이 문서에.)

## 0. 공통 원칙

- **토큰 구분은 snake_case**(소문자+`_`). 공백·대문자·한글을 파일명에 쓰지 않는다(이식성·스크립트 안정성). 예외: 참고문헌 PDF/노트는 §4의 `Author(Year) - Short title` 형식.
- **날짜는 `YYYYMMDD`**. 타임스탬프가 필요하면 `YYYYMMDD_HHMMSS`. **날짜는 파일명에만**, 폴더로 만들지 않는다(아카이브 제출본 제외 §3).
- **설명어(descriptor)는 의미를 담되 값이 아니다**: 수치·p값·계수 같은 결과값을 파일명에 넣지 않는다(`..._p001` 금지). 의미가 바뀌지 않는 한 파일명도 안정적이어야 한다.
- **번호 폴더 = 콘텐츠, 언더스코어 폴더 = 부산물**. csv·로그·임시는 전부 `_logs/`.

## 1. 그림 (Figure)

```
본문:  Figure_<N>_<desc>.png         예) Figure_1_task_procedure.png
                                        Figure_2_caudate_loneliness.png
보충:  Figure_S<N>_<desc>.png        예) Figure_S1_network_overview.png
```

- `<N>`은 정수(본문), 보충은 `S1, S2, …`.
- `<desc>`는 **영문 의미어, 소문자 snake_case, 약 3단어 이내**. 사람이 읽고 무슨 그림인지 알 수 있게(분석 변수명을 그대로 베끼지 않는다).
- **번호는 `02_anal/03_results/06_reporting`에서 한 곳에서만 부여**한다. 서로 다른 분석이 같은 번호를 중복 쓰지 않게 `06_reporting`에 **매핑표 1개**(번호 ↔ 파일 ↔ 생성 코드/변수)를 둔다. 분석 변수와의 추적은 이 매핑표로 하고, 파일명은 깔끔하게 유지한다.
- 손제작 도식 원본은 `03_assets/figures/`, R/분석 동기화본은 `04_synced/figures/`.

## 2. 표 (Table)

```
본문:  Table_<N>_<desc>.docx         예) Table_1_demographic_characteristics.docx
보충:  Table_S<N>_<desc>.docx        예) Table_S1_full_correlations.docx
연관:  Table_S<N><a|b|c>_<desc>.docx 예) Table_S4a_caudate_models.docx
```

- 규칙은 그림과 동일(영문 의미어 snake_case, 번호는 `06_reporting` 단일 부여).
- 하나의 표가 여러 패널/모형으로 쪼개지면 `S4a/S4b/S4c`처럼 소문자 접미.

## 3. 최종 산출물 (rendered output)

- **작업 렌더는 덮어쓰기**: `05_output/manuscript.docx`, `05_output/manuscript.html` (항상 같은 이름, 매 렌더마다 덮어씀). 작업본은 버전 파일을 쌓지 않는다.
- **제출본만 스냅샷 보관**:
  ```
  _archive/submissions/YYYYMMDD_<journal-slug>/
      manuscript.docx
      manuscript.html
      cover_letter.docx        (있으면)
      README.md                (제출 메모: 저널, 버전, 변경점)
  ```
  `<journal-slug>`은 소문자 snake_case(예: `kjcbp`, `neuroimage`).
- 렌더 부산물(`*_files/`, `.quarto/`)은 산출물이 아니므로 보관하지 않는다(§0, gitignore).

## 4. 참고문헌·문헌 (references / literature)

- 서지 파일: **`01_source/references.bib`** (Zotero Better BibTeX auto-export 대상, 단일).
- **인용키(citation key)는 Zotero BBT 자동 생성**을 그대로 쓴다. 예: `russellUCLALonelinessScale1996`. 본문 인용 `[@russellUCLALonelinessScale1996]`, 노트 프론트매터 `citation_key:` 동일. 키가 흔들리면 BBT에서 **pin**.
- 문헌 PDF·노트 파일명(예외적으로 사람 읽기 형식 허용):
  ```
  1인:     Author(Year) - Short title.pdf
  2인:     Author1 & Author2(Year) - Short title.pdf
  3인:     Author1, Author2 & Author3(Year) - Short title.pdf
  4인 이상: Author et al(Year) - Short title.pdf
  ```
  노트(`02_literature/notes/`)는 같은 stem에 `.md`. PDF는 `02_literature/pdfs/`.

## 5. 로그·부산물 (_logs)

- 위치는 항상 `_logs/`(문헌 관련은 `_logs/literature/`).
- 이름: `<purpose>_<YYYYMMDD>.csv` (스냅샷) 또는 `<purpose>.csv`(최신본 덮어쓰기). **dry-run은 덮어쓴다**(`<purpose>.dry_run.csv`), 날짜로 쌓지 않는다.
- manifest/inventory 등도 동일.

## 6. 데이터 (02_anal/01_data)

- `00_raw/`(원자료, 불변), `01_interim/`(중간), `02_final/`(분석용 최종).
- 파일명 snake_case + 의미어. 버전이 필요하면 `..._v2` 또는 날짜 접미. 원자료는 받은 이름을 보존해도 되나 가능하면 정리.

## 7. 에이전트 준수

- 표·그림을 새로 만들면: 번호는 `06_reporting` 매핑표에서 받고, 위 형식으로 저장하고, 매핑표를 갱신한다. 그 뒤 `sync_reporting_assets.R`로 `04_synced/`에 미러.
- `render_with_insertions.R`의 마커 매핑(`[Table N 삽입]` → 파일)을 새 이름과 일치시킨다.
- 규칙을 못 지킬 상황이면 임의로 어기지 말고 사용자에게 확인한다.
