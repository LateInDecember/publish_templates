# 여기서 시작하세요 (START HERE)

논문 작업 환경(Quarto·R·Obsidian·Zotero)을 **아무것도 몰라도** 한 번에 깔고 폴더까지 만들어 주는 템플릿입니다.

---

## 1단계 — 더블클릭으로 설치

| 운영체제 | 할 일 |
|---|---|
| **🍎 macOS** | 이 폴더의 **`SETUP_MAC.command`** 더블클릭 |
| **🪟 Windows** | 이 폴더의 **`SETUP_WINDOWS.bat`** 더블클릭 |

그러면 창이 열리고 **프로젝트 이름/위치**를 물어봅니다. 입력하면 도구 설치 → 폴더·양식 생성 → 점검까지 자동으로 진행됩니다.

> **첫 실행 시 경고가 뜨면(정상입니다):**
> - macOS: `SETUP_MAC.command` **우클릭 → 열기 → (경고창) 열기** 를 한 번만. (이후엔 그냥 더블클릭)
> - Windows: "Windows의 PC 보호" 창이 뜨면 **추가 정보 → 실행**.
> - macOS에서 더블클릭이 아무 반응이 없으면(실행 권한 문제): Terminal에 `chmod +x ` 를 친 뒤 `SETUP_MAC.command` 파일을 끌어다 놓고 Enter, 다시 더블클릭.
> - macOS는 설치 중 **로그인 비밀번호**를 물어볼 수 있습니다(Homebrew 설치). 화면엔 안 보여도 입력됩니다.
> - Windows는 **App Installer(winget)** 가 필요합니다. 없다면 Microsoft Store에서 "App Installer"를 먼저 설치하세요.

---

## 2단계 — 손으로 한 번만 (GUI)

자동화로 다 안 되는 3가지(앱 안에서 클릭해야 하는 것)만 남습니다. 설치 끝에 안내가 다시 나옵니다.

1. **Zotero 참고문헌 연결** — Better BibTeX 설치 후, 참고문헌 컬렉션을 `01_manuscript/01_source/references.bib`로 자동 내보내기(Keep updated). → `skills/.../install/zotero_bbt_setup.md`
2. **Zotero API 키 저장**(선택) — 키를 명령에 붙여넣기:
   - macOS: `bash _secrets/set_zotero_key.sh "API_KEY" "userID"`
   - Windows: `powershell -File _secrets\set_zotero_key.ps1 -ApiKey "API_KEY" -UserId "userID"`
3. **Obsidian 열기** — `01_manuscript` 폴더를 vault로 열고, 커뮤니티 플러그인 Shell commands·Citations·Dataview 설치. → `skills/.../install/obsidian_starter/README.md`

---

## 3단계 — 글쓰기 & 렌더

- Obsidian에서 **`manuscript.md`** 를 씁니다. 표·그림 자리에는 `{{table:1}}`, `{{figure:1}}` 마커.
- 렌더(미리보기 docx/html 만들기):
  - macOS: `01_source/render.command` 더블클릭
  - Windows: `01_source\render.bat` 더블클릭
- 결과는 `05_output/`.

---

자세한 사용법은 **[`USER_GUIDE.md`](USER_GUIDE.md)** (설치·원고·표/그림·Zotero·API 키·문헌 노트·에이전트 프롬프트·터미널 명령·문제해결 전부). 에이전트(Codex/Claude)로 자동 진행하려면 **[`프롬프트.md`](%ED%94%84%EB%A1%AC%ED%94%84%ED%8A%B8.md)** 를 주세요.
