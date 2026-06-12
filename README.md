# Manuscript Publishing Pipeline

Quarto + Obsidian + Zotero + R 기반으로 **학술 논문 원고를 작성·렌더링하는 작업 환경을 처음부터 세팅**하고, **문헌 PDF를 구조화된 리뷰 노트로 작성**하는 **에이전트 중립적 템플릿 저장소**입니다. 다른 컴퓨터·다른 사람도 동일한 파이프라인을 복제할 수 있습니다.

## 어떤 에이전트로 쓰나 (도구 중립)

이 저장소는 특정 AI에 종속되지 않습니다. **Codex, Claude, Cursor 등 `AGENTS.md`를 읽는 어떤 agentic AI로도** 사용할 수 있습니다.

- **진입점은 [`AGENTS.md`](AGENTS.md)** — 에이전트가 이 저장소를 열면 먼저 읽는 사용 안내(도구 중립 표준).
- **마스터 프롬프트는 [`프롬프트.md`](%ED%94%84%EB%A1%AC%ED%94%84%ED%8A%B8.md)** — 어떤 에이전트에게든 그대로 붙여넣으면 파이프라인을 세팅합니다.
- **Claude/Cowork 사용자**는 추가로 이 저장소를 `.plugin`으로 설치하면 아래 두 스킬이 슬래시 명령처럼 노출됩니다. (`.claude-plugin/plugin.json` + `skills/*/SKILL.md`는 이 편의 패키징을 위한 것이며, 핵심 자산은 일반 마크다운·스크립트입니다.)

## 들어 있는 스킬

| 스킬 | 하는 일 | 부를 때 |
|---|---|---|
| **setup-manuscript-pipeline** | 작업 폴더·폴더 구조 생성 → 루트 `AGENTS.md` 생성 → Quarto/Zotero/Obsidian 설치 안내 → 데이터·문헌·양식 위치 질문 → 원고 양식·렌더 스크립트 세팅 | "논문 작업 환경 세팅", "원고 파이프라인 만들어줘", "이 템플릿으로 새 프로젝트 시작" |
| **write-literature-note** | PDF/논문을 17개 섹션 구조의 Obsidian 문헌 리뷰 노트로 작성(YAML 프론트매터 + paper-review 템플릿) | "이 논문 노트로 정리해줘", "문헌 리뷰 노트 작성", "PDF를 노트로" |

위 두 작업은 스킬 형식으로 묶여 있지만 **내용은 에이전트 중립적**입니다. 아래 어느 방식으로든 사용할 수 있습니다.

## 사용 방법

**방법 A — 어떤 에이전트로든 (Codex, Claude, Cursor, …)**
1. 에이전트로 이 저장소를 열면 [`AGENTS.md`](AGENTS.md)가 진입점입니다.
2. 새 프로젝트 세팅: [`프롬프트.md`](%ED%94%84%EB%A1%AC%ED%94%84%ED%8A%B8.md)를 에이전트에게 주면 됩니다(또는 아래 빠른 시작).
3. 문헌 노트: `skills/write-literature-note/`의 절차·템플릿을 따르게 합니다.

**방법 B — Claude / Cowork 플러그인으로**
1. 이 저장소를 `.plugin`으로 패키징해 Cowork에 설치(또는 마켓플레이스 등록).
2. `setup-manuscript-pipeline` / `write-literature-note` 스킬이 노출되어 자연어로 호출됩니다.

## 빠른 시작 (자동 부트스트랩)

도구 설치 + 폴더·양식·스크립트·.obsidian·AGENTS 생성 + 검증을 한 번에:

```bash
cd skills/setup-manuscript-pipeline/references
bash install/bootstrap.sh "<새 프로젝트 절대경로>" --install            # macOS/Linux (R 제외)
bash install/bootstrap.sh "<새 프로젝트 절대경로>" --install --with-r   # R까지 설치(선택)
# Windows: powershell -File install/install.ps1 [-WithR] 실행 후, 폴더 생성은 에이전트/수동
```

생성되는 구조는 **도구 중립**입니다(`02_anal`에 R/Python 이름 없음, `01_data/{00_raw,01_interim,02_final}`). **R은 선택** — `render_with_insertions.R`에만 필요하고, 없으면 `quarto render manuscript.md`를 씁니다.

이후 **GUI 마무리**(직접): Zotero Better BibTeX auto-export 지정(`install/zotero_bbt_setup.md`), Zotero API 키 저장(`bash _secrets/set_zotero_key.sh`), Obsidian 커뮤니티 플러그인 설치(`install/obsidian_starter/README.md`), `AGENTS.md` 플레이스홀더·`reporting_root`·마커 매핑 채우기.

## 설계 원칙

- **단일 원고 파일**: `manuscript.md` 하나만 편집(Obsidian). `.qmd`는 만들지 않음 — 렌더 스크립트가 md를 직접 읽음.
- **분석이 단일 출처**: 표·그림은 분석(R)에서만 생성 → `04_synced/`로 단방향 미러 → 원고에서 직접 수정 금지.
- **마커 기반 삽입**: `[Table 1 삽입]`, `[Figure 1 삽입]` 마커를 렌더 시 실제 파일로 치환.
- **부산물 격리**: csv·로그·임시파일은 전부 `_logs/`. 콘텐츠 폴더 오염 금지.
- **재현성**: 폴더·규칙을 `AGENTS.md`로 고정.

## 폴더 구성

```
manuscript-publishing-pipeline/        (= 이 플러그인 / git repo)
├── .claude-plugin/plugin.json
├── README.md
├── 프롬프트.md                         # 플러그인 없이 쓰는 마스터 프롬프트
├── skills/
│   ├── setup-manuscript-pipeline/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── folder_structure.md
│   │       ├── install_quarto_zotero_obsidian.md
│   │       ├── obsidian_workflow.md
│   │       ├── pipeline.md
│   │       ├── setup_questions.md
│   │       ├── AGENTS_TEMPLATE.md
│   │       ├── install/                # ★ 자동화: bootstrap.sh, install.sh/.ps1, verify.sh,
│   │       │                           #   zotero_bbt_setup.md, obsidian_starter/.obsidian
│   │       ├── scripts/                # 렌더·동기화 스크립트(참조 구현)
│   │       └── manuscript_format/      # _quarto.yml, 양식, 골격, 스타일
│   └── write-literature-note/
│       ├── SKILL.md
│       └── references/literature_note_template.md
└── .gitignore
```
