# 사용 설명서 (USER GUIDE) — Manuscript Publishing Pipeline

이 문서는 이 저장소(파이프라인)로 **무엇을 할 수 있고, 그걸 하려면 에이전트에게 어떤 프롬프트를 주거나 터미널에서 어떤 명령을 실행해야 하는지**를 처음 쓰는 사람도 따라 할 수 있게 끝까지 설명합니다.

> 한 줄 요약: **Obsidian에서 `manuscript.md` 한 파일을 쓰고, 분석(R 등)에서 나온 표·그림을 `{{table:1}}`/`{{figure:1}}` 마커로 끼워 넣은 뒤, 한 번의 렌더로 `manuscript.docx`/`.html`을 만든다. 참고문헌은 Zotero가 자동으로 대주고, 문헌은 17섹션 노트로 정리한다.**

---

## 목차

1. [전체 그림 (5분 이해)](#1-전체-그림)
2. [빠른 시작](#2-빠른-시작)
3. [어떤 에이전트로 어떻게 쓰나 (+프롬프트 예시)](#3-어떤-에이전트로)
4. [설치 상세 (Quarto·R·Obsidian·Zotero)](#4-설치-상세)
5. [폴더 구조 — 무엇을 어디에 두나](#5-폴더-구조)
6. [원고 작성 (Obsidian·마커·인용·수식)](#6-원고-작성)
7. [표·그림 파이프라인 (분석→동기화→렌더, 자동 마커)](#7-표그림-파이프라인)
8. [렌더링 (방법·산출물·문제해결)](#8-렌더링)
9. [참고문헌 = Zotero 연동](#9-zotero-연동)
10. [Zotero API 키 설정 (_secrets)](#10-api-키)
11. [문헌 PDF·노트 정리 (어떻게 요청하나)](#11-문헌-노트)
12. [파일·폴더 명명 규칙](#12-명명-규칙)
13. [에이전트로 할 수 있는 일 — 작업별 프롬프트 모음](#13-프롬프트-모음)
14. [터미널로 직접 할 수 있는 일 — 명령 모음](#14-명령-모음)
15. [검증 & 자주 막히는 점](#15-문제해결)
16. [제출본 관리 & git/GitHub](#16-제출-git)

---

## 1. 전체 그림

이 파이프라인은 4개 도구를 엮습니다.

| 도구 | 역할 |
|---|---|
| **Obsidian** | 원고(`manuscript.md`)와 문헌 노트를 쓰는 편집기(vault) |
| **Quarto** | `manuscript.md` → `.docx`/`.html` 렌더 엔진 |
| **Zotero (+Better BibTeX)** | 참고문헌 관리 → `references.bib` 자동 생성 → 인용 `[@key]` 연결 |
| **R** | 통계 분석 + 렌더 스크립트(`render_with_insertions.R`)가 표·그림을 원고에 삽입 |

작업 흐름:

```
분석(R 등) ──► 06_reporting(표·그림 단일 출처) ──► 04_synced(원고용 미러)
                                                      │
Obsidian에서 manuscript.md 작성 ([@인용], {{table:1}}, {{figure:1}}) ─┘
                                                      ▼
                          렌더 ──► 05_output/manuscript.docx · .html
```

핵심 원칙: **원고 파일은 `manuscript.md` 하나**, **표·그림은 분석이 유일 출처**(원고에서 직접 수정 금지), **부산물(csv·로그)은 전부 `_logs/`**.

---

## 2. 빠른 시작

새 컴퓨터/새 논문에서 처음부터 세팅하는 가장 빠른 길(맥/리눅스):

```bash
# 1) 이 저장소로 이동
cd <publish_templates 경로>/skills/setup-manuscript-pipeline/references

# 2) 도구 설치 + 폴더·양식·스크립트·_secrets·AGENTS 생성 + 검증 (한 번에)
bash install/bootstrap.sh "<새 프로젝트 절대경로>"

# 3) 검증
bash install/verify.sh "<새 프로젝트 절대경로>/01_manuscript"
```

그다음 **GUI로 한 번만** 마무리(§4, §9, §10): Zotero Better BibTeX 자동 export 지정, Obsidian 커뮤니티 플러그인 설치, Zotero API 키 저장. 끝나면 §8대로 렌더하면 됩니다.

Windows는 `powershell -ExecutionPolicy Bypass -File install/install.ps1` 로 설치한 뒤 폴더 생성은 에이전트/수동으로.

> **에이전트에게 통째로 맡기려면** §3·§13의 프롬프트를 쓰세요. 에이전트가 위 과정을 대신 실행합니다.

---

## 3. 어떤 에이전트로

이 저장소는 도구 중립입니다. **진입점은 `AGENTS.md`**, **마스터 지시문은 `프롬프트.md`**.

- **Codex CLI / Claude Code (맥 터미널)** — 실제 설치까지 됩니다. 가장 권장. 저장소 폴더에서 `프롬프트.md` 내용을 주거나 "AGENTS.md 읽고 새 논문 프로젝트 세팅해줘"라고 시키면 됩니다.
- **Claude Cowork** — 폴더·문서 작업은 되지만, 샌드박스라 사용자 맥에 설치는 못 합니다(설치 명령은 사용자가 맥 터미널에서 실행). 플러그인(`.plugin`)으로 설치하면 두 스킬이 자연어로 호출됩니다.
- **Cursor 등** — `AGENTS.md`를 읽는 에이전트면 동일하게 동작.

가장 짧은 시작 프롬프트:

```
publish_templates 의 AGENTS.md와 프롬프트.md를 읽고, 그 절차대로 새 논문 프로젝트를 세팅해줘.
설치(Quarto·R·Obsidian·Zotero)는 안내만 하지 말고 install.sh/bootstrap을 실제로 실행해.
시작 전에 작업 폴더 위치·이름, 데이터 위치, 문헌 위치, 원고 양식, 분석 도구부터 물어봐.
```

작업별 더 구체적인 프롬프트는 §13에 모아 두었습니다.

---

## 4. 설치 상세

R은 **필수**입니다(렌더 스크립트가 R 기반). 분석 자체는 Python/MATLAB도 가능하지만 렌더용 R은 깝니다.

### 자동 (권장)
- macOS/Linux: `bash install/install.sh` (Homebrew/apt 사용)
- Windows: `powershell -ExecutionPolicy Bypass -File install/install.ps1` (winget 사용)
- 폴더 생성까지 한 번에: `bash install/bootstrap.sh "<프로젝트경로>"`

### 수동 링크
- Quarto <https://quarto.org/docs/get-started/> → 확인 `quarto --version`
- R <https://cloud.r-project.org/> → 패키지 `install.packages(c("officer","png","stringr","xml2","zip"))`
- Obsidian <https://obsidian.md/download>
- Zotero <https://www.zotero.org/download/> + Better BibTeX <https://retorque.re/zotero-better-bibtex/>

### 설치가 "그냥 clone만 되고 안 깔리는" 이유
템플릿을 `git clone`하면 파일만 복사됩니다. 설치는 **별도 동작**이라, `install.sh`/`bootstrap.sh`를 *실행*해야 깔립니다. 또 **Cowork 샌드박스 셸은 사용자 맥과 다른 환경**이라 거기서 돌리면 맥엔 안 깔립니다 — 맥 터미널이나 로컬 셸 에이전트(Codex CLI/Claude Code)에서 실행해야 합니다. 자세한 검증은 §15.

---

## 5. 폴더 구조

```
<프로젝트>/
├── AGENTS.md                 # 에이전트 작업 규칙(정본)
├── _secrets/                 # API 키 (gitignore, 권한600) — §10
├── 01_manuscript/            # ← Obsidian vault. 여기서 원고를 쓴다
│   ├── manuscript.md         #   ★ 유일하게 편집하는 원고 파일
│   ├── _quarto.yml           #   렌더 설정
│   ├── 01_source/            #   references.bib, apa.csl, styles/, notes/, render.command
│   ├── 02_literature/        #   pdfs/, notes/(문헌 리뷰 노트), index.md
│   ├── 03_assets/figures/    #   손으로 만든 도식(Figure 1 등)
│   ├── 04_synced/            #   분석에서 온 표·그림 미러 (★ 읽기 전용)
│   ├── 05_output/            #   렌더 결과 manuscript.docx/.html
│   ├── _scripts/             #   렌더·동기화 스크립트(.R)
│   ├── _logs/                #   모든 csv·로그·manifest
│   └── _archive/             #   아카이브(제출본 등)
└── 02_anal/                  # 분석 (도구 중립)
    ├── 00_code/              #   분석 코드(R/Python/MATLAB)
    ├── 01_data/{00_raw,01_interim,02_final}
    ├── 02_meta_data/
    ├── 03_results/06_reporting/  # ★ 원고로 넘어가는 표·그림 단일 출처
    └── 04_docs/
```

**번호 폴더 = 콘텐츠(사람이 봄), 언더스코어 폴더 = 부산물(기계가 씀).** csv·로그는 항상 `_logs/`. `04_synced/`는 직접 고치지 않습니다(동기화 때 덮어써짐).

---

## 6. 원고 작성

Obsidian에서 `01_manuscript/`를 vault로 열고 **`manuscript.md`** 를 편집합니다(이 파일이 곧 Quarto 렌더 소스 — 별도 `.qmd` 없음).

원고에 쓰는 마크업:

- **인용**: `[@citation_key]` (Zotero BBT 키). 다중 `[@a; @b]`, 서술형 `@a (2020) ...`.
- **표·그림 삽입 마커**: `{{table:1}}`, `{{figure:1}}` (한 줄에 하나). §7에서 자동으로 실제 파일로 치환.
- **수식**: `$...$`, `$$...$$`.
- **제목 위계**: 논문 제목 `#`, 본문 큰 제목 `##`, 중제목 `###`, 하위 `####`.

Obsidian 안에서 바로 렌더하려면 **Shell commands** 플러그인에 `cd "{{vault_path}}" && Rscript _scripts/render_with_insertions.R` 를 명령으로 등록하면 ⌘P로 실행됩니다(`install/obsidian_starter/`에 미리 설정됨).

---

## 7. 표·그림 파이프라인

**규칙: 표·그림은 분석에서만 만든다.** 분석 결과가 `02_anal/03_results/06_reporting`에 모이고, `sync_reporting_assets.R`가 `01_manuscript/04_synced/`로 복사하며, 렌더가 마커를 실제 파일로 바꿉니다.

### 마커는 번호로 자동 매핑됩니다
- `{{table:1}}` → `04_synced/tables/{main,supplementary}/Table_1_*.docx` 를 자동으로 찾음
- `{{figure:2}}` → `04_synced/figures/Figure_2_*.png` (손제작은 `03_assets/figures/`)
- **번호만 맞으면 설명어는 자유.** 즉 `Table_1_무엇이든.docx`를 04_synced에 넣고 `{{table:1}}`만 쓰면 렌더됩니다. 경로 매핑을 손볼 필요 없음.
- 같은 번호 파일이 둘 이상이면 렌더가 "모호함" 에러로 멈춥니다 → 그때만 `render_with_insertions.R`의 `asset_override`에 정확한 파일을 지정.
- **그림 캡션**(제목/노트)은 `render_with_insertions.R`의 `figure_captions`에 id별로, **표 레이아웃**(가로형/페이지나눔)은 `wide_table_markers`/`appendix_pagebreak_markers`에 둡니다(파일명에서 못 얻으므로).

### 표·그림 내용을 바꾸려면
원고나 `04_synced/`에서 직접 고치지 말고 **분석 코드에서** 고친 뒤 다시 동기화·렌더합니다(§8). 그림 제목/라벨도 분석 코드에서.

---

## 8. 렌더링

### 방법 (셋 중 하나)
1. **Finder에서 `01_source/render.command` 더블클릭** (가장 쉬움)
2. 터미널: `cd 01_manuscript && Rscript _scripts/render_with_insertions.R`
3. **Obsidian** 명령 팔레트에서 "Render manuscript" (Shell commands 등록 시)

렌더는 먼저 `sync_reporting_assets.R`로 최신 표·그림을 `04_synced/`에 동기화한 뒤, DOCX/HTML을 만들고 마커를 실제 파일로 치환합니다.

### 산출물
- `05_output/manuscript.docx`, `05_output/manuscript.html` (작업본 — 매번 덮어씀)
- HTML은 단일 파일로 임베드됨(`_quarto.yml`의 `embed-resources: true`) → 출력 폴더에 그림 복사본이 안 생김.

### 자주 나는 문제
- **Word에서 docx를 열어둔 채 렌더** → 덮어쓰기 실패. 렌더 전 Word를 닫으세요(`~$manuscript.docx` 잠금 흔적).
- **"Ambiguous figure/table" 에러** → 04_synced에 같은 번호 파일이 둘. `asset_override`로 지정(§7).
- **"No table/figure file" 에러** → 04_synced에 해당 번호 파일이 없음. 분석을 돌려 06_reporting을 만들고 동기화하세요.

---

## 9. Zotero 연동

목표: Zotero 컬렉션이 바뀌면 `01_source/references.bib`가 자동 갱신되어 본문 `[@key]`가 항상 최신 서지와 연결.

1. Zotero + **Better BibTeX** 설치(§4).
2. 참고문헌 컬렉션 만들기 (예: `My Library/<project>/references`).
3. 컬렉션 우클릭 → **Export Collection** → Format **Better BibTeX** → **Keep updated 체크** → 저장 위치 `01_manuscript/01_source/references.bib`.
4. 이후 컬렉션에 논문 추가하면, **Zotero가 열려 있는 동안** `references.bib`가 자동 갱신.
5. 인용키 확인: 항목 선택 → Better BibTeX citation key. 본문에 `[@그키]`로 인용. 키가 흔들리면 우클릭 → Pin BibTeX key.

상세: `skills/setup-manuscript-pipeline/references/install/zotero_bbt_setup.md`.

---

## 10. API 키

Zotero **웹 API**로 메타데이터·첨부를 가져오는 스크립트에는 API 키가 필요합니다(로컬 export는 키 불필요). 키는 안전하게 `_secrets/`에 둡니다.

1. 키 발급: <https://www.zotero.org/settings/keys> → *Create new private key* → **read** 권한 권장. key와 userID(숫자) 확인.
2. 저장(복붙 한 번):
   ```bash
   bash _secrets/set_zotero_key.sh          # 키를 붙여넣으면 _secrets/zotero.env 생성(권한600, gitignore)
   ```
   Windows: `powershell -ExecutionPolicy Bypass -File _secrets\set_zotero_key.ps1`
3. 스크립트/에이전트는 `_secrets/zotero.env`를 **읽기 전용**으로 로드하고 키를 출력·커밋하지 않습니다.

**안전 규칙**: 실제 키 파일 `zotero.env`는 git에 올리지 않습니다(이미 gitignore). 저장소에는 빈 `zotero.env.example`만 들어갑니다. 상세: `_secrets/README.md`.

---

## 11. 문헌 노트

문헌 PDF를 **17섹션 구조의 리뷰 노트**(YAML 프론트매터 + Citation … Final Evaluation)로 정리합니다. 양식: `skills/write-literature-note/references/literature_note_template.md`.

### 어떻게 요청하나 (에이전트에게)
```
02_literature/pdfs/ 에 있는 "<논문 파일명>" 을 write-literature-note 양식(17섹션 paper-review)으로
정리해서 02_literature/notes/ 에 저장해줘. 파일명은 'Author(Year) - Short title.md' 규칙으로.
원문에서 확인 안 되는 값은 'Needs verification'으로 두고, citation_key는 references.bib와 일치시켜줘.
```
여러 편을 한꺼번에:
```
02_literature/pdfs/ 의 모든 PDF를 각각 17섹션 노트로 정리해줘. 이미 notes/ 에 있는 건 건너뛰고,
프론트매터 status는 core로, 다 끝나면 어떤 게 references.bib에 없는지 _logs/literature/ 에 리포트로 남겨줘.
```

### 직접 정리할 때
PDF·노트 파일명은 APA 저자-연도(§12). 노트끼리는 `[[wikilink]]`로 연결, `02_literature/index.md`가 시작점. Obsidian **Dataview** 플러그인으로 status별 대시보드를 만들 수 있습니다.

---

## 12. 명명 규칙

상세: `skills/setup-manuscript-pipeline/references/naming_conventions.md`. 요약:

- 공통: snake_case, 날짜 `YYYYMMDD`, 설명어는 영문 의미어(결과값 금지), 한글·공백 파일명 금지(참고문헌 예외).
- 그림 `Figure_<N>_<desc>.png` / 보충 `Figure_S<N>_…`. 표 `Table_<N>_<desc>.docx` / 보충 `Table_S<N>_…`, 연관 `S4a/S4b`.
- 산출물: 작업본 `manuscript.docx`/`.html` 덮어쓰기 / 제출본만 `_archive/submissions/YYYYMMDD_<journal>/` 스냅샷.
- 참고문헌: `references.bib` + BBT 자동 인용키. 문헌 PDF/노트 `Author(Year) - Short title`.
- 삽입 마커: `{{table:N}}` / `{{figure:N}}` (보충 `s1`, 연관 `s4a`).
- 로그: 전부 `_logs/`.

---

## 13. 프롬프트 모음

에이전트(Codex/Claude/Cursor)에게 그대로 주면 되는 작업별 프롬프트.

| 하고 싶은 것 | 프롬프트 |
|---|---|
| **새 프로젝트 세팅** | "publish_templates의 AGENTS.md·프롬프트.md대로 새 논문 프로젝트를 세팅해줘. 설치는 실제로 실행하고, 폴더 위치·데이터·문헌·양식·분석도구부터 물어봐." |
| **도구 설치만** | "install/install.sh 를 실행해서 Quarto·R·Obsidian·Zotero를 설치하고 verify.sh로 확인해줘." |
| **표/그림 추가** | "분석에서 새 표 Table_5_<설명>.docx 를 06_reporting에 만들고 동기화한 뒤, 원고의 결과 절에 {{table:5}} 마커를 넣어줘." |
| **그림 제목/라벨 수정** | "Figure 2의 제목을 '…'으로 바꾸고 싶어. 원고가 아니라 분석 코드/figure_captions에서 고친 뒤 다시 렌더해줘." |
| **렌더** | "manuscript를 렌더해서 05_output에 docx/html을 만들어줘. (Word는 닫혀 있어)" |
| **문헌 노트 1편** | (§11 위 프롬프트) |
| **문헌 노트 전체** | (§11 아래 프롬프트) |
| **Zotero 연동 점검** | "references.bib가 최신인지, 본문 [@key]들이 다 references.bib에 있는지 확인하고 빠진 키를 _logs/에 리포트해줘." |
| **참고문헌 정리** | "manuscript.md에서 실제 인용된 키만 남기도록 references 컬렉션과 대조해서 미사용/누락을 알려줘." |
| **제출본 만들기** | "현재 원고를 렌더해서 _archive/submissions/<날짜>_<저널>/ 에 docx/html과 제출 메모 README를 만들어줘." |
| **구조 점검** | "AGENTS.md 규칙대로 폴더·파일명이 맞는지 점검하고, 어긋난 것(콘텐츠 폴더의 csv 등)을 _logs로 옮기는 안을 제시해줘." |

> 팁: 프롬프트에 "AGENTS.md 규칙을 지켜서"를 붙이면 폴더·명명·출력 위치 규칙을 따릅니다.

---

## 14. 명령 모음

터미널에서 직접 할 수 있는 것(맥/리눅스 기준, `01_manuscript/`에서):

```bash
# 렌더 (표·그림 동기화 포함)
Rscript _scripts/render_with_insertions.R

# 표·그림만 04_synced로 동기화(렌더 없이) — 먼저 dry-run으로 확인
Rscript _scripts/sync_reporting_assets.R --dry-run
Rscript _scripts/sync_reporting_assets.R

# Zotero → 문헌 PDF/노트 미러
Rscript _scripts/sync_zotero_literature.R

# 로컬 PDF 폴더를 02_literature로 매칭 복사
Rscript _scripts/sync_key_articles_to_literature.R --dry-run
Rscript _scripts/sync_key_articles_to_literature.R

# 문헌 파일명 규칙으로 정규화(미리보기 후 적용)
Rscript _scripts/normalize_literature_filenames.R

# Zotero API 키 저장
bash _secrets/set_zotero_key.sh

# 설치/연동 검증
bash <publish_templates>/skills/setup-manuscript-pipeline/references/install/verify.sh "$(pwd)"
```

산출물·로그 위치: 렌더 결과 `05_output/`, 동기화 manifest·csv는 `_logs/`.

---

## 15. 문제해결

검증: `bash install/verify.sh "<01_manuscript 경로>"` — Quarto·R·패키지·references.bib·_secrets·폴더를 점검합니다.

자주 막히는 점:
- **설치가 안 됨 / clone만 됨** → `install.sh`/`bootstrap.sh`를 *실행*해야 함. Cowork 샌드박스면 사용자 맥 터미널에서 실행(§4).
- **references.bib가 비거나 옛날** → Zotero가 꺼져 있거나 auto-export 경로가 틀림(§9). Zotero를 열고 컬렉션 export 설정 확인.
- **렌더 "Ambiguous"/"No file"** → §8 참고(번호 중복은 asset_override, 누락은 분석·동기화).
- **Word 잠금으로 docx 덮어쓰기 실패** → Word 닫기.
- **05_output에 그림 폴더가 생김** → `_quarto.yml` html에 `embed-resources: true` 확인.
- **한글 깨짐(Windows PowerShell)** → 제공 `.ps1`은 ASCII 전용이라 안전. 직접 만든 스크립트는 UTF-8(BOM) 또는 영문으로.

---

## 16. 제출 & git

- **제출본**: 작업본(`05_output/manuscript.docx`)을 덮어쓰며 쓰다가, 제출 시점에 `_archive/submissions/YYYYMMDD_<journal>/`로 스냅샷(+ 제출 메모 README). 작업본에 버전 파일을 쌓지 않습니다.
- **git/GitHub**(템플릿 저장소 기준): iCloud 동기화 폴더의 `.git`은 잠금 경고가 날 수 있으니, 커밋·푸시는 맥 터미널에서:
  ```bash
  cd "<publish_templates 경로>"
  git add -A && git commit -m "..." && git push origin main
  ```
- 실제 논문 프로젝트도 git으로 관리하려면 `_secrets/zotero.env`와 렌더 부산물(`*_files/`, `.quarto/`)이 무시되는지(.gitignore) 확인하세요(템플릿 gitignore에 포함됨).

---

질문이 생기면 해당 섹션의 상세 문서(`skills/setup-manuscript-pipeline/references/...`)를 보거나, 에이전트에게 "USER_GUIDE.md의 <섹션>대로 해줘"라고 요청하세요.
