# AGENTS_TEMPLATE.md

> 이 파일을 프로젝트 루트에 `AGENTS.md`로 복사한 뒤, 모든 `<...>` 플레이스홀더를 실제 값으로 치환한다.
> 이 파일이 이 프로젝트에서 작업하는 모든 에이전트(Codex, Claude 등)의 **규칙 정본**이다. 사람용 사용법은 `01_manuscript/README.md`에 둔다.

---

# AGENTS.md — `<프로젝트명>` 작업 규칙

대상: `<프로젝트 절대경로>`
분석 도구: `<R | Python | MATLAB>`
원고 양식: `<저널명 / 기본 양식>`
마지막 갱신: `<YYYY-MM-DD>`

## 0. 황금 규칙 (요약)

1. **새 폴더를 임의로 만들지 않는다.** 필요하면 §1 구조표에 먼저 추가하고 만든다.
2. **부산물(csv·log·manifest·json·임시파일)은 콘텐츠 폴더에 절대 쓰지 않는다.** 전부 `_logs/`로.
3. **타임스탬프는 파일명에만 쓴다. 타임스탬프 폴더를 만들지 않는다.**
4. **그림·표는 코드(분석)가 유일한 출처다.** 원고 폴더의 산출물(`04_synced/`)을 손으로 고치지 않는다.
5. **임시/캐시는 커밋·아카이브하지 않는다.** 발견 즉시 삭제 대상.
6. **원고 파일은 `manuscript.md` 하나뿐이다.** `.qmd`를 만들지 않는다(렌더가 md를 직접 읽음).

## 1. 폴더 구조 (정본)

`references/folder_structure.md`와 동일한 구조를 유지한다. 요약:

```
01_manuscript/  manuscript.md, _quarto.yml,
  01_source/(references.bib, apa.csl, styles/, notes/, render.command)
  02_literature/(pdfs/, notes/, index.md)
  03_assets/figures/
  04_synced/(tables/, figures/)   ← 분석 미러, 읽기 전용
  05_output/                      ← 렌더 산출물
  _scripts/  _logs/  _archive/
_secrets/  zotero.env(키, gitignore) + zotero.env.example + set_zotero_key.sh/.ps1
02_anal/  00_code/ 01_data/(00_raw,01_interim,02_final) 02_meta_data/ 03_results/06_reporting/ 04_docs/
```

번호 폴더 = 콘텐츠, 언더스코어 폴더 = 부산물. `06_reporting`이 분석→원고 단일 핸드오프 지점. **`02_anal`은 도구 중립**(폴더에 R/Python 이름을 쓰지 않음). 분석은 R/Python/MATLAB 무엇이든 가능하나 **렌더용 R은 필수**(`render_with_insertions.R`가 R 기반).

## 2. 출력 위치 규칙 (위반 금지)

| 만드는 것 | 가야 할 곳 |
|---|---|
| csv, manifest, dry_run, json, 로그 txt | `_logs/` (문헌은 `_logs/literature/`) |
| .R / .py 스크립트 | `_scripts/` (문헌 python은 `_scripts/lit/`) |
| 손제작 그림/도식 | `03_assets/figures/` |
| 분석에서 동기화된 표/그림 | `04_synced/` (직접 생성·수정 금지) |
| 렌더 .docx/.html | `05_output/` |
| 문헌 PDF/노트 | `02_literature/pdfs`, `02_literature/notes` |
| 더 이상 안 쓰는 것 | `_archive/` (§5) |

## 3. 작업 파이프라인 (순서 고정)

표·그림이 바뀌어야 하면 **항상 분석 → 동기화 → 렌더** 순서. 역방향(원고에서 직접 수정) 금지.

1. **분석 수정**: `02_anal/00_code/`의 스크립트 수정·실행 → `02_anal/03_results/06_reporting` 갱신.
2. **동기화**: `01_manuscript/_scripts/sync_reporting_assets.R` → `04_synced/`로 미러(렌더가 자동 호출).
3. **렌더**: `01_manuscript/`에서 `Rscript _scripts/render_with_insertions.R` (또는 `01_source/render.command`) → `05_output/manuscript.docx`, `.html`. 렌더는 `manuscript.md`를 직접 읽음(별도 `.qmd` 없음). 이 렌더는 R 기반이므로 R + 패키지가 설치돼 있어야 한다.

## 4. 그림·표 = 코드가 유일 출처

- 그림을 손으로 고치지 않는다. 제목/라벨/캡션 변경도 분석 코드/라벨 설정에서 한다.
- figure·table 번호는 `06_reporting`에서 단일 부여. 서로 다른 분석이 같은 번호대를 중복 사용하지 않게 매핑 테이블 1개로 관리.

## 5. 아카이브 규칙

- 아카이브는 `01_manuscript/_archive/` 한 곳, 그 아래 **날짜 폴더 1단계까지만**(`_archive/YYYYMMDD_무엇/`).
- 임시/캐시(`.quarto/`, `quarto-session-temp*`, `__pycache__/`, `*_files/`)는 아카이브 금지 → 삭제.

## 6. 문헌 노트 규칙

- 대상: `02_literature/pdfs/`의 `<모든 | core>` 참고문헌.
- 노트 1개 = 논문 1편. 위치 `02_literature/notes/`. **17섹션 paper-review 양식**(YAML 프론트매터 + 1.Citation … 17.Final Evaluation)으로 작성 — `write-literature-note` 스킬 사용.
- 프론트매터에 `status: core|candidate|dropped`를 둬 참고문헌 갱신에 대응(노트를 지우지 말고 status만 변경).
- 파일명 규칙(§8)을 PDF와 일치.

## 7. Obsidian / 렌더

- `01_manuscript/`를 Obsidian vault로 연다. `manuscript.md`를 편집한다.
- 인용은 `[@citation_key]` (Better BibTeX 키). 마커 `{{table:N}}`, `{{figure:N}}`는 렌더 시 치환.
- HTML은 `_quarto.yml`의 `embed-resources: true`로 단일 파일 출력(출력 폴더 오염 방지).

## 8. 파일·폴더 명명 규칙 (상세: `references/naming_conventions.md`)

공통: 토큰은 **snake_case**(소문자+`_`), 날짜 `YYYYMMDD`, 설명어는 **영문 의미어**(결과값 아님). 한글·공백·대문자 파일명 금지(참고문헌 예외).

- **그림**: `Figure_<N>_<desc>.png` / 보충 `Figure_S<N>_<desc>.png`. `<desc>`는 영문 의미어 ~3단어. 번호는 `06_reporting`에서 단일 부여(매핑표로 코드 추적). 예) `Figure_2_caudate_loneliness.png`.
- **표**: `Table_<N>_<desc>.docx` / 보충 `Table_S<N>_<desc>.docx`, 연관 `Table_S4a/S4b`. 예) `Table_1_demographic_characteristics.docx`.
- **산출물**: 작업본은 `05_output/manuscript.docx`·`.html` 덮어쓰기. **제출본만** `_archive/submissions/YYYYMMDD_<journal-slug>/`에 스냅샷.
- **참고문헌**: bib는 `01_source/references.bib`(BBT auto-export). 인용키는 **BBT 자동**(`russellUCLALonelinessScale1996`) 그대로. 문헌 PDF/노트는 `Author(Year) - Short title.{pdf,md}` (1/2/3/4+인 규칙은 상세 문서).
- **로그**: `_logs/`에 `<purpose>_YYYYMMDD.csv` 또는 덮어쓰기. dry-run은 `*.dry_run.csv` 덮어쓰기.

새 표·그림을 만들면: 번호는 `06_reporting` 매핑표에서 받고 → 위 형식으로 저장 → 매핑표·`render_with_insertions.R` 마커 매핑을 일치시킨다.

## 9. 도구·경로 (이 프로젝트 실제값)

- 분석 결과 단일 출처: `02_anal/03_results/06_reporting` (또는 `<실제 경로>`)
- Zotero 컬렉션: `<컬렉션 경로>` → `01_source/references.bib` 자동 export
- 로컬 PDF 소스(있으면): `<경로>`
- 분석 도구: `<R | Python | MATLAB>` (분석은 자유, 단 렌더용 R은 필수)

## 10. 시크릿 (API 키) — 안전 규칙

- Zotero 등 API 키는 **`_secrets/zotero.env`** 에만 둔다(gitignore, 권한 600). placeholder는 `_secrets/zotero.env.example`, 입력은 `_secrets/set_zotero_key.sh`(복붙).
- 에이전트는 키를 **읽기 전용으로만** 사용한다: `set -a; . _secrets/zotero.env; set +a` 또는 R `readRenviron("_secrets/zotero.env")`.
- 키 값을 **채팅·로그·코드·커밋에 절대 출력/포함하지 않는다**(필요시 길이/끝 4자리만). `_secrets/zotero.env`를 git에 추가하지 않는다.
