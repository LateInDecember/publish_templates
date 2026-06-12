# Manuscript Publishing Pipeline (Cowork 플러그인)

Quarto + Obsidian + Zotero + R 기반으로 **학술 논문 원고를 작성·렌더링하는 작업 환경을 처음부터 세팅**하고, **문헌 PDF를 구조화된 리뷰 노트로 작성**하는 Cowork 플러그인입니다. 다른 컴퓨터·다른 사람도 이 플러그인 하나로 동일한 파이프라인을 복제할 수 있습니다.

## 들어 있는 스킬

| 스킬 | 하는 일 | 부를 때 |
|---|---|---|
| **setup-manuscript-pipeline** | 작업 폴더·폴더 구조 생성 → 루트 `AGENTS.md` 생성 → Quarto/Zotero/Obsidian 설치 안내 → 데이터·문헌·양식 위치 질문 → 원고 양식·렌더 스크립트 세팅 | "논문 작업 환경 세팅", "원고 파이프라인 만들어줘", "이 템플릿으로 새 프로젝트 시작" |
| **write-literature-note** | PDF/논문을 17개 섹션 구조의 Obsidian 문헌 리뷰 노트로 작성(YAML 프론트매터 + paper-review 템플릿) | "이 논문 노트로 정리해줘", "문헌 리뷰 노트 작성", "PDF를 노트로" |

## 설치/사용

1. 이 폴더를 `.plugin`으로 패키징한 파일을 Cowork에 설치하거나, 마켓플레이스에 등록.
2. 새 논문 프로젝트를 시작할 때 setup 스킬을 호출 → 안내에 따라 폴더·도구·양식이 구성됩니다.
3. 문헌을 정리할 때 write-literature-note 스킬을 호출 → PDF가 구조화된 노트가 됩니다.

플러그인을 설치하지 않고 **프롬프트만 쓰고 싶으면** 루트의 `프롬프트.md`를 에이전트(Claude/Codex)에게 그대로 붙여넣으면 됩니다.

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
│   │       ├── scripts/                # 렌더·동기화 스크립트(참조 구현)
│   │       └── manuscript_format/      # _quarto.yml, 양식, 골격, 스타일
│   └── write-literature-note/
│       ├── SKILL.md
│       └── references/literature_note_template.md
└── .gitignore
```
