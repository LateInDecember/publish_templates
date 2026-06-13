# Obsidian 작업 워크플로우 (Quarto 원고 + 문헌 노트)

## 1. Vault 열기

Obsidian → **Open folder as vault** → `01_manuscript/` 선택. 원고(`manuscript.md`)와 문헌 노트(`02_literature/notes/`)가 한 vault에 들어온다.

## 2. 원고 편집 — `manuscript.md`

원고는 `manuscript.md` **하나**를 편집한다. 이 파일이 그대로 Quarto 렌더 소스이므로, Obsidian에서 쓴 내용이 곧 최종 원고가 된다(별도 `.qmd` 없음).

유지할 마크업:

- 인용: `[@citation_key]` — Better BibTeX 키. 다중: `[@a; @b]`. 서술형: `@a (2020) ...`.
- 삽입 마커: `{{table:1}}`, `{{figure:1}}` — 렌더 시 실제 표/그림 파일로 치환.
- 수식: `$...$`, `$$...$$`.
- 제목 위계: 논문 제목 `#`(H1), 본문 큰 제목 `##`(H2), 중제목 `###`(H3), 하위 `####`(H4).

## 3. ".qmd 를 Obsidian에서 다루고 싶다면" (선택)

이 파이프라인은 원고를 `.md`로 두므로 Obsidian이 바로 편집한다. 그래도 **`.qmd` 확장자 파일을 Obsidian에서 직접 열고 싶으면**:

1. Obsidian → **설정 → 파일 및 링크(Files & Links) → "Detect all file extensions"(모든 파일 확장자 감지)** 를 켠다.
2. 그러면 `.qmd`, `.R`, `.yml` 등도 파일 탐색기에 보이고 편집할 수 있다.

> 다만 권장 워크플로우는 `manuscript.md` 단일 편집이다. `.qmd`를 따로 두면 "원고가 2개"가 되어 동기화 혼란이 생기므로, 특별한 이유가 없으면 만들지 않는다. iCloud/클라우드 동기화 폴더에서는 심볼릭 링크가 보존되지 않으므로 `.qmd` 바로가기도 쓰지 않는다.

## 4. Obsidian 안에서 렌더 실행 (명령 바인딩)

Obsidian 안에서 바로 렌더하려면 **Shell commands** 커뮤니티 플러그인을 쓴다:

1. 설정 → 커뮤니티 플러그인 → **Shell commands** 설치·활성화.
2. New shell command 추가:

   ```bash
   cd "{{vault_path}}" && Rscript _scripts/render_with_insertions.R
   ```

   (vault가 `01_manuscript/`이므로 `{{vault_path}}`가 곧 원고 루트.)
3. 명령에 이름(예: "Render manuscript")과 단축키/리본 아이콘을 지정.
4. 이제 Obsidian 명령 팔레트(⌘P)에서 "Render manuscript"를 실행하면 `05_output/`에 docx·html이 생성된다.

> Shell commands 플러그인을 쓰지 않으면, Finder에서 `01_source/render.command`를 더블클릭하거나 터미널에서 `Rscript _scripts/render_with_insertions.R`를 실행한다.

## 5. 문헌 노트 보기/작성

- `02_literature/notes/`의 논문별 노트는 `[[wikilink]]`로 서로 연결된다. `index.md`에서 시작.
- 새 문헌 노트는 **`write-literature-note` 스킬**로 작성(17섹션 paper-review 양식). 프론트매터 `status`로 core/candidate/dropped 분류 → Dataview로 대시보드화 가능.
- 인용 삽입은 **Citations** 또는 **Zotero Integration** 플러그인으로 `references.bib`를 읽어 `[@key]`를 넣는다.

## 6. 권장 Obsidian 설정 요약

- Files & Links → Detect all file extensions: (필요 시) ON
- Editor → Readable line length: OFF (긴 표·마커 가독성)
- Community plugins: Shell commands(렌더), Citations/Zotero Integration(인용), Dataview(문헌 대시보드)
- `.obsidian/workspace*.json`은 기기별 상태이므로 git에서 무시(`.gitignore`).
