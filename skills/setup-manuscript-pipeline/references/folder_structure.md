# 폴더 구조 명세

프로젝트 루트(`<프로젝트>`) 아래에 아래 구조를 생성한다. 번호 폴더는 사람이 보는 콘텐츠, 언더스코어 폴더는 기계 부산물.

```
<프로젝트>/
├── AGENTS.md                          # 작업 규칙 정본 (AGENTS_TEMPLATE.md에서 생성)
│
├── 01_manuscript/                     # 원고 작업 폴더 (Obsidian vault)
│   ├── manuscript.md                  # ★ 원고 본체 — 유일하게 편집하는 파일
│   ├── _quarto.yml                    # 렌더 설정
│   ├── README.md / OBSIDIAN_GUIDE.md  # 사용법 (선택)
│   │
│   ├── 01_source/                     # 입력 자산 (사람이 관리)
│   │   ├── references.bib             # Zotero Better BibTeX 자동 export 대상
│   │   ├── apa.csl                    # 인용 스타일
│   │   ├── styles/                    # reference docx, css
│   │   ├── notes/                     # 저자 작업 노트(저널 양식, outline, 해석)
│   │   └── render.command            # 렌더 런처(더블클릭)
│   │
│   ├── 02_literature/                 # 문헌 콘텐츠만 (스크립트·csv 금지)
│   │   ├── pdfs/                      # PDF/HTML 첨부
│   │   ├── notes/                     # 논문별 노트(Obsidian, paper-review 양식)
│   │   └── index.md                   # 문헌 인덱스/대시보드
│   │
│   ├── 03_assets/figures/             # 손으로 만든 도식/그림 원본
│   │
│   ├── 04_synced/                     # 분석 결과 미러 (★ 읽기 전용, 직접 수정 금지)
│   │   ├── tables/  (main/, supplementary/)
│   │   └── figures/
│   │
│   ├── 05_output/                     # 렌더 산출물 (.docx, .html)
│   │
│   ├── _scripts/                      # 모든 .R/.py
│   │   ├── render_with_insertions.R   # 메인 렌더(마커 삽입 포함)
│   │   ├── sync_reporting_assets.R    # 분석→04_synced 동기화
│   │   ├── sync_zotero_literature.R   # Zotero→02_literature 미러
│   │   └── lit/                       # 문헌 python 도구(있으면)
│   │
│   ├── _logs/                         # 모든 csv·manifest·json·스냅샷 (literature/ 하위)
│   └── _archive/                      # 아카이브 (날짜 폴더 1단계까지만)
│
└── 02_anal/                           # 분석 폴더 (도구별)
    └── 01_R/
        ├── 00_code/                   # 00_setup.R … NN_*.R (번호 = 실행 순서)
        ├── 01_data/                   # 01_interim/ → 02_final/
        ├── 02_meta_data/              # codebook, variable_map, logs
        ├── 03_results/                # 분석별 raw 결과
        │   └── 06_reporting/          # ★ 원고로 넘어가는 단일 출처 (docs/figures/tables, main+supplementary)
        └── 04_docs/
```

## 생성 명령 (예시, bash/zsh)

```bash
P="<프로젝트 절대경로>"
mkdir -p "$P/01_manuscript"/{01_source/{styles,notes},02_literature/{pdfs,notes},03_assets/figures,04_synced/{tables/{main,supplementary},figures},05_output,_scripts/lit,_logs/literature,_archive}
mkdir -p "$P/02_anal/01_R"/{00_code,01_data/{01_interim,02_final},02_meta_data,03_results/06_reporting/{docs/{main,supplementary},figures/{main,supplementary},tables/{main,supplementary}},04_docs}
```

## 불변 규칙

- csv·로그·manifest·json·임시출력 → **반드시 `_logs/`** (문헌 관련은 `_logs/literature/`). 콘텐츠 폴더에 금지.
- `04_synced/`는 동기화로만 채운다. 직접 생성·수정 금지(덮어써짐).
- 임시/캐시(`.quarto/`, `*_files/`, `__pycache__/`, `quarto-session-temp*`)는 커밋·아카이브하지 않고 삭제.
- 새 폴더가 필요하면 이 명세에 먼저 추가하고 만든다.
