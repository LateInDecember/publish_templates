# AGENTS.md — publish_templates

> 이 파일은 **이 저장소를 여는 모든 agentic AI(Codex, Claude, Cursor 등)** 를 위한 사용 안내다.
> `AGENTS.md`는 도구 중립적인 사실상 표준 진입점이다. (Claude Code/Cowork도 이 파일을 참조하며, 별도 `CLAUDE.md`는 두지 않는다 — 이 파일이 정본이다.)

## 이 저장소는 무엇인가

학술 논문(원고) **출판 파이프라인 템플릿**이다. 어떤 에이전트로든 이 저장소를 사용해:

1. 새 논문 프로젝트의 **작업 폴더·폴더 구조**를 만들고,
2. **Quarto · Obsidian · Zotero · R**을 설치·연동하고,
3. **원고 양식**을 세팅하고,
4. **문헌 PDF**를 구조화된 리뷰 노트로 작성한다.

특정 AI에 종속되지 않는다. 패키징(`.claude-plugin/plugin.json`, `skills/*/SKILL.md`)은 Claude/Cowork 설치 편의를 위한 **선택적** 래퍼일 뿐이고, 핵심 자산은 일반 마크다운·스크립트다.

## 에이전트가 할 일 (작업 유형별 진입점)

- **새 프로젝트 파이프라인 세팅** → `프롬프트.md`(마스터 지시문)를 따른다. 핵심 절차·참조는 `skills/setup-manuscript-pipeline/SKILL.md`와 그 `references/`에 있다.
  - 결정적 부분은 자동화: `bash skills/setup-manuscript-pipeline/references/install/bootstrap.sh "<프로젝트경로>" [--install]`
- **문헌 리뷰 노트 작성** → `skills/write-literature-note/SKILL.md` 절차와 `references/literature_note_template.md`(17섹션 paper-review 양식)를 따른다.

> `SKILL.md`는 Claude/Cowork 스킬 형식이지만, **내용은 에이전트 중립적**이다. Codex 등 다른 에이전트는 이 `AGENTS.md` → `프롬프트.md` → 해당 `SKILL.md`/`references/` 순으로 읽고 그대로 수행하면 된다.

## 저장소 지도

```
publish_templates/
├── AGENTS.md                 # ← 지금 이 파일 (모든 에이전트의 진입점)
├── 프롬프트.md                # 새 프로젝트 세팅 마스터 프롬프트 (붙여넣어 실행)
├── README.md                 # 사람용 개요
├── .claude-plugin/plugin.json # (선택) Claude/Cowork 플러그인 매니페스트
└── skills/
    ├── setup-manuscript-pipeline/
    │   ├── SKILL.md
    │   └── references/        # folder_structure, install_*, obsidian_workflow,
    │       │                  #   pipeline, setup_questions, AGENTS_TEMPLATE,
    │       │                  #   install/(bootstrap·install·verify·obsidian_starter·zotero),
    │       │                  #   scripts/, manuscript_format/
    └── write-literature-note/
        ├── SKILL.md
        └── references/literature_note_template.md
```

## 핵심 규칙 (생성되는 프로젝트에 적용)

새 프로젝트를 만들 때 `references/AGENTS_TEMPLATE.md`를 그 프로젝트 루트의 `AGENTS.md`로 복사해 채운다. 그 규칙의 요지:

- **단일 원고 파일** `manuscript.md`만 편집(별도 `.qmd` 없음). 렌더가 md를 직접 읽음.
- **분석이 단일 출처**: 표·그림은 분석에서만 생성 → `04_synced/` 단방향 미러 → 원고에서 직접 수정 금지.
- **마커 기반 삽입** `[Table N 삽입]`, `[Figure N 삽입]`.
- **부산물 격리**: csv·로그는 전부 `_logs/`.
- 번호 폴더 = 콘텐츠, 언더스코어 폴더 = 부산물.
- **도구 중립 구조 / R 필수**: `02_anal`은 도구 이름을 쓰지 않는 중립 구조(`00_code`, `01_data/{00_raw,01_interim,02_final}`, …). 분석은 R/Python/MATLAB 자유지만, 원고 렌더 `render_with_insertions.R`가 R 기반이라 **R은 필수**로 설치한다.
- **시크릿**: API 키는 `_secrets/zotero.env`(gitignore·권한600)에만. 에이전트는 **읽기 전용**으로 쓰고 키를 출력·로그·커밋하지 않는다.

## 주의

- `AGENTS_TEMPLATE.md`(references 안)는 *새 프로젝트에 복사되는 규칙 템플릿*이고, 지금 이 루트 `AGENTS.md`는 *이 저장소 자체를 다루는 안내*다. 혼동하지 말 것.
- GUI 앱(Obsidian/Zotero)의 일부 단계(플러그인 설치 승인, Better BibTeX auto-export 경로 지정)는 스크립트로 완전 자동화되지 않으므로 사용자에게 안내한다.
