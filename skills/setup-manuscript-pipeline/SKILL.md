---
name: setup-manuscript-pipeline
description: Sets up a complete Quarto + Obsidian + Zotero + R manuscript-writing pipeline from scratch in a new project folder. Use when the user says "논문 작업 환경 세팅", "원고 파이프라인 만들어줘", "이 템플릿으로 새 프로젝트 시작", "set up the manuscript pipeline", "replicate the publishing setup", or wants to reproduce this reproducible-research folder structure on a new computer. Creates the folder structure, the root AGENTS.md rules file, installs/guides Quarto+Zotero+Obsidian, asks where data/literature/format live, and wires up render + sync scripts.
---

# Setup Manuscript Publishing Pipeline

이 스킬은 학술 논문 원고 작성·렌더링 환경을 **처음부터** 구축한다. 아무 사전 지식이 없는 사용자의 새 컴퓨터에서도 이 스킬만으로 동일한 파이프라인이 재현되어야 한다. 아래 **Phase 0 → 7**을 순서대로 수행한다. 각 Phase가 끝나면 사용자에게 한 줄로 결과를 보고하고 다음으로 넘어간다. **임의로 폴더를 만들거나 순서를 건너뛰지 말 것.**

상세 내용은 `references/`에 있다. 시작 전에 다음을 읽는다: `references/setup_questions.md`, `references/folder_structure.md`, `references/AGENTS_TEMPLATE.md`.

### 자동화 스크립트 (가능하면 활용)

`references/install/`에 설치·세팅 자동화가 있다. Phase 0(질문)으로 프로젝트 경로를 받은 뒤, 결정적인 부분(폴더 구조·양식·스크립트·.obsidian·AGENTS·검증)은 **bootstrap.sh 한 번으로** 처리할 수 있다:

```bash
bash references/install/bootstrap.sh "<프로젝트_절대경로>" [--install]
#   --install: 먼저 install.sh로 Quarto/R/Obsidian/Zotero 설치 시도
```

- `install/install.sh`(mac/linux), `install/install.ps1`(windows): Quarto·R(+패키지)·Obsidian·Zotero 설치.
- `install/bootstrap.sh`: 설치(선택) → Phase 1 폴더 + Phase 4 양식·스크립트 + .obsidian 스타터 + AGENTS.md → verify.
- `install/verify.sh`: 도구·폴더·references.bib 검증.
- `install/zotero_bbt_setup.md`, `install/obsidian_starter/`: GUI로 마무리해야 하는 연동(Zotero auto-export, Obsidian 커뮤니티 플러그인) 안내·기본설정.

bootstrap이 끝나도 **GUI 단계(Zotero BBT auto-export 지정, Obsidian 커뮤니티 플러그인 설치 승인)와 프로젝트별 값(AGENTS 플레이스홀더, reporting_root, 마커 매핑)** 은 사람이/에이전트가 마무리해야 한다. 아래 Phase는 이 마무리까지 포함한 전체 절차다.

## Phase 0 — 사용자에게 질문 (먼저)

`references/setup_questions.md`의 질문을 **한 번에** 던지고 답을 받는다. 핵심 5가지:

1. 작업(프로젝트) 폴더 위치 + 프로젝트 이름.
2. 분석 데이터/결과 위치(표·그림이 생성되는 폴더 절대경로). 없으면 "아직 없음".
3. 문헌(PDF)·참고문헌 위치(Zotero 컬렉션명, 로컬 PDF 폴더, `references.bib` 위치).
4. 원고 양식: 있으면 그 파일/요건을, 없으면 `references/manuscript_format/`의 기본 양식(인지 및 생물 심리학회지 2020판)을 사용.
5. 분석 도구(R / Python / MATLAB; 기본 R).

답을 받기 전에는 파일을 만들지 않는다. 모호하면 그 항목만 다시 확인한다.

## Phase 1 — 작업 폴더 + 폴더 구조 생성

`references/folder_structure.md`의 명세를 그대로 적용한다. 사용자가 정한 위치에 프로젝트 폴더를 만들고 그 안에 `01_manuscript/`(4구역 + 언더스코어 폴더)와 `02_anal/`을 생성한다.

핵심 규칙: 번호 폴더 = 사람이 보는 콘텐츠, 언더스코어 폴더(`_scripts`/`_logs`/`_archive`) = 기계 부산물. csv·로그는 **항상 `_logs/`**. 빈 폴더·타임스탬프 폴더 남발 금지.

## Phase 2 — 최상위 AGENTS.md 생성

`references/AGENTS_TEMPLATE.md`를 읽고 Phase 0~1에서 정해진 실제 경로·이름·도구로 플레이스홀더(`<...>`)를 모두 치환해 **프로젝트 루트에 `AGENTS.md`로 저장**한다. 이후 모든 작업의 규칙 정본이 된다.

## Phase 3 — Quarto + Zotero + Obsidian 설치

`references/install_quarto_zotero_obsidian.md`를 따른다. 사용자 OS 확인 후:

- **Quarto** 최신 안정판 → `quarto --version` 확인.
- **Zotero** + **Better BibTeX** → 참고문헌 컬렉션을 `01_manuscript/01_source/references.bib`로 **자동 export** 설정.
- **Obsidian** → `01_manuscript/`를 vault로 열기. 편집·인용 워크플로우는 `references/obsidian_workflow.md` 참조.
- **R은 선택**(`install.sh --with-r` / `install.ps1 -WithR`). `render_with_insertions.R`(마커·표 삽입)만 R + 패키지 `officer, png, stringr, xml2, zip`가 필요하다. R을 안 쓰면 분석을 Python/MATLAB로 하고 원고는 `quarto render manuscript.md`로 렌더한다. 분석 폴더 `02_anal`은 도구 이름을 쓰지 않는 중립 구조다.

설치는 사용자 컴퓨터에서 실행되므로 명령을 제시하고 사용자가 실행·확인하게 안내한다.

## Phase 4 — 원고 양식 세팅

`references/manuscript_format/`의 자료로 원고 골격을 만든다.

- `_quarto.yml` → `01_manuscript/_quarto.yml` (html에 `embed-resources: true` 유지 — 출력 폴더에 그림/스타일 복사본 방지).
- `styles/` → `01_manuscript/01_source/styles/`.
- `journal_format_kjcbp_2020.md`, `journal_requirements.md` → `01_manuscript/01_source/notes/` (참고용).
- `manuscript_skeleton.md` → `01_manuscript/manuscript.md` (사용자 양식이 없을 때 기본 골격; 제목→저자→소속→저자주→영문요약 순서, 마커 포함).
- `scripts/render_with_insertions.R`, `sync_reporting_assets.R`, `sync_zotero_literature.R` 등 → `01_manuscript/_scripts/`. **표·그림 마커 매핑(스크립트 내부)을 새 프로젝트의 실제 표/그림에 맞게 수정**해야 함을 사용자에게 명시.
- `scripts/render.command` → `01_manuscript/01_source/render.command` (`chmod +x`).

사용자가 자기 양식을 제공하면 그 양식으로 대체하되, 마커 기반 삽입·폴더 규칙·`embed-resources`는 유지한다.

**중요(단일 원고 파일):** `.qmd` 파일을 만들지 않는다. 렌더 스크립트는 `manuscript.md`를 직접 읽는다. (Obsidian이 .md를 네이티브로 편집하므로 별도 qmd 불필요. iCloud는 심볼릭 링크를 보존하지 못하므로 qmd 바로가기도 만들지 않는다.)

## Phase 5 — 데이터·문헌 연결

`references/pipeline.md` 참조.

- **분석 결과 연결**: `sync_reporting_assets.R`의 `reporting_root`를 사용자의 실제 분석 결과 폴더로 맞춘다. 분석이 아직 없으면 폴더만 만들고 "분석 후 동기화" 안내.
- **문헌 연결**: Zotero 컬렉션 → `references.bib` 자동 export 확인 후 `sync_zotero_literature.R`로 PDF/노트를 `02_literature/`에 미러. 로컬 PDF 폴더가 따로면 `sync_key_articles_to_literature.R`의 `source_root`를 그 경로로.
- **Zotero API 키**: `_secrets/`에 보관. 사용자에게 `bash _secrets/set_zotero_key.sh`로 키를 복붙해 저장하게 안내(gitignore·권한600). 에이전트는 `_secrets/zotero.env`를 **읽기 전용**으로만 쓰고 키를 출력/커밋하지 않는다(`references/install/secrets/README.md`).
- 분석 결과 단일 출처 기본값은 `02_anal/03_results/06_reporting`(중립 구조). 분석이 R이면 `sync_reporting_assets.R`의 `reporting_root`가 이 경로인지 확인.
- 문헌 노트는 `write-literature-note` 스킬로 작성(17섹션 paper-review 양식).

## Phase 6 — 렌더 검증

1. (분석 있으면) 분석 실행 → `06_reporting` 갱신.
2. `Rscript _scripts/sync_reporting_assets.R --dry-run` 으로 동기화 경로 확인.
3. `01_source/render.command` 더블클릭(또는 `Rscript _scripts/render_with_insertions.R`).
4. `05_output/manuscript.docx`, `manuscript.html` 생성되면 성공. (`05_output`에 그림/스타일 폴더가 또 생기면 `_quarto.yml` html의 `embed-resources: true`를 확인.)

## Phase 7 — 마무리 보고

생성된 구조, 설치된 도구 버전, 연결된 데이터·문헌 경로, 렌더 성공 여부를 요약 보고하고 미완 항목(마커 매핑 수정, 분석 미실행 등)을 체크리스트로 남긴다.
