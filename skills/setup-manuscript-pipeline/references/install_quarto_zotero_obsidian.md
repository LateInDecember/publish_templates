# 설치 가이드 — Quarto · Zotero · Obsidian · R

설치는 **사용자 컴퓨터에서 직접** 실행된다. 에이전트는 OS를 확인하고 명령을 제시하며, 사용자가 실행·확인하도록 안내한다. 각 단계 끝에 버전 확인으로 성공 여부를 검증한다.

> **자동화**: 아래 단계를 일일이 치지 않고 한 번에 하려면 `install/` 스크립트를 쓴다.
> - macOS/Linux: `bash install/install.sh` (Quarto·R·패키지·Obsidian·Zotero) → 또는 폴더 생성까지 한 번에 `bash install/bootstrap.sh "<프로젝트경로>" --install`
> - Windows: `./install/install.ps1` (winget)
> - 검증: `bash install/verify.sh "<01_manuscript경로>"`
> GUI 앱(Obsidian/Zotero)은 설치만 자동이고, 플러그인 승인·BBT export 지정은 직접 한다(이 문서·`install/zotero_bbt_setup.md`·`install/obsidian_starter/README.md` 참고).

---

## 1. Quarto

원고 렌더 엔진. Pandoc 내장.

- **macOS**: `brew install --cask quarto` 또는 <https://quarto.org/docs/get-started/> 에서 `.pkg` 설치.
- **Windows**: <https://quarto.org/docs/get-started/> 에서 `.msi` 설치, 또는 `winget install --id RStudio.Quarto`.
- **Linux**: `.deb`/`.rpm` 다운로드 후 설치, 또는 tarball을 `~/.local`에 전개.

확인: `quarto --version` (1.4 이상 권장; `embed-resources` 지원).

---

## 2. Zotero + Better BibTeX

참고문헌 관리 + `references.bib` 자동 export.

1. **Zotero 데스크톱** 설치: <https://www.zotero.org/download/>
2. **Better BibTeX** 플러그인 설치: <https://retorque.re/zotero-better-bibtex/installation/> 의 `.xpi`를 받아 Zotero → Tools → Plugins → 톱니바퀴 → Install Plugin From File.
3. 참고문헌 컬렉션 만들기: `My Library/<project>/references` 형태.
4. **자동 export 설정**: 컬렉션 우클릭 → *Export Collection* → Format **Better BibTeX**, **Keep updated** 체크 → 저장 위치를 `01_manuscript/01_source/references.bib`로 지정.
   - 이후 컬렉션에 논문을 추가하면 Zotero가 열려 있는 동안 `references.bib`가 자동 갱신된다.
5. 인용 키 확인: 항목 선택 → Better BibTeX citation key 필드, 또는 `references.bib`의 `@article{` 뒤 문자열.

> 첨부 PDF를 로컬 폴더로 미러하려면 `_scripts/sync_zotero_literature.R` 사용.

---

## 3. Obsidian

원고·문헌 노트 편집 환경.

1. 설치: <https://obsidian.md/download> (macOS/Windows/Linux).
2. **Open folder as vault** → `01_manuscript/` 선택. (원고 `manuscript.md`와 문헌 `02_literature/notes/`가 한 vault에 들어온다.)
3. 권장 커뮤니티 플러그인(선택):
   - **Citations** 또는 **Zotero Integration**: `references.bib`를 읽어 `[@key]` 인용 삽입.
   - **Dataview**: `02_literature/notes/`의 프론트매터(`status`, `priority` 등)로 문헌 대시보드 작성.
4. 편집·인용 워크플로우는 `obsidian_workflow.md` 참조.

> 참고: Obsidian은 기본적으로 `.md`만 다룬다. 이 파이프라인은 원고를 `manuscript.md`로 두므로 Obsidian에서 바로 편집되고, 동시에 Quarto 렌더 소스로 쓰인다(별도 `.qmd` 불필요).

---

## 4. R + 렌더 패키지 (선택 — `render_with_insertions.R`를 쓸 때만)

> **R은 선택**이다. 분석을 Python/MATLAB로 해도 되고, `02_anal` 폴더는 도구 중립(`01_R` 같은 강제 없음)이다. 다만 마커·표 자동삽입 렌더(`render_with_insertions.R`)는 R이 필요하다. R을 안 쓰면 `quarto render manuscript.md`로 렌더한다(표는 마커 위치에 수동 배치). 자동 설치는 `install.sh --with-r` / `install.ps1 -WithR`.

1. **R** 설치: <https://cloud.r-project.org/> (또는 macOS `brew install --cask r`, Windows `winget install RProject.R`).
2. 렌더 스크립트 의존 패키지:

   ```r
   install.packages(c("officer", "png", "stringr", "xml2", "zip"))
   ```

3. 분석 자체에 필요한 패키지(예: `tidyverse`, `lme4`, `igraph` 등)는 프로젝트에 맞게 추가.
4. 확인: `Rscript -e 'cat(R.version.string)'` 및 위 패키지 `library()` 로드.

---

## 5. Zotero API 키 (_secrets) — 선택

웹 API로 메타데이터·첨부를 가져오는 스크립트용. `bash _secrets/set_zotero_key.sh`로 키를 복붙해 `_secrets/zotero.env`(gitignore, 권한600)에 저장. 자세히는 `install/zotero_bbt_setup.md` §5.5, `install/secrets/README.md`.

## 검증 체크리스트

- [ ] `quarto --version` 출력됨
- [ ] Zotero에서 컬렉션 → `01_source/references.bib` 자동 export 동작(Keep updated)
- [ ] Obsidian에서 `01_manuscript/` vault 열림, `manuscript.md` 편집 가능
- [ ] (R) `officer/png/stringr/xml2/zip` 로드됨
