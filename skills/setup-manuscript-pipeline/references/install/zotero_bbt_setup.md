# Zotero ↔ 원고 연동 (Better BibTeX auto-export)

목표: Zotero의 참고문헌 컬렉션이 바뀌면 `01_manuscript/01_source/references.bib`가 **자동으로 갱신**되어, 원고의 `[@key]` 인용이 항상 최신 서지와 연결되게 한다.

## 1. Better BibTeX 설치 (citation key가 비어 있다면 99% 이 단계 문제)

Zotero 기본 상태에는 **citation key 개념이 아예 없습니다.** citation key는 **Better BibTeX(BBT) 플러그인**이 만들어 주는 것이라, BBT가 설치·활성화돼 있지 않으면 키가 전부 공란입니다.

설치(Zotero 7 기준):

1. Zotero 데스크톱 설치: <https://www.zotero.org/download/>
2. BBT `.xpi` **파일을 다운로드**: <https://retorque.re/zotero-better-bibtex/installation/> 의 *Download* 링크를 **우클릭 → 다른 이름으로 저장**(그냥 클릭하면 브라우저가 열어버려 설치가 안 됨). 확장자가 `.xpi`인지 확인(`.zip`으로 바뀌면 `.xpi`로 변경).
3. Zotero → 상단 메뉴 **Tools → Plugins** (Zotero 6은 **Tools → Add-ons**).
4. 플러그인 창 **우측 상단 톱니바퀴(⚙)** → **Install Plugin From File…** → 받은 `.xpi` 선택.
5. **Zotero 완전 종료 후 재시작.**

설치 확인(이게 되면 OK):
- Tools → Plugins 목록에 **Better BibTeX**가 *Enabled*로 보인다.
- 상단 메뉴에 **Tools → Better BibTeX** 항목이 생긴다.
- 항목을 하나 클릭하면 우측 패널 아래에 **Better BibTeX** 섹션과 **Citation key** 값이 보인다.

> 위가 안 보이면 BBT가 설치 안 된 것 → 2~5단계 다시. (`.xpi`를 클릭만 하고 저장 안 했거나, 재시작을 안 한 경우가 대부분.)

## 2. 참고문헌 컬렉션 만들기

- 좌측 라이브러리에서 컬렉션 생성: 예) `My Library / <project> / references`.
- 이 논문에 인용할 항목을 이 컬렉션에 모은다.

## 3. references.bib 자동 export 설정 (핵심)

1. 컬렉션 우클릭 → **Export Collection…**
2. Format: **Better BibTeX**
3. **Keep updated** 체크 ✅ (이게 자동 갱신의 핵심)
4. 저장 위치를 정확히:
   `01_manuscript/01_source/references.bib`
5. 저장. 이후 컬렉션에 항목을 추가/수정하면, **Zotero가 실행 중인 동안** `references.bib`가 자동 갱신된다.

## 4. 인용 키(citation key) — 공란일 때 해결

BBT가 설치되면 항목마다 자동으로 키를 만든다(예: `russellUCLALonelinessScale1996`).

키 보는 법:
- 항목 선택 → 우측 패널 아래 **Better BibTeX → Citation key**.
- 또는 항목 목록의 **컬럼 헤더 우클릭 → "Citation Key" 컬럼 추가** → 목록에서 한눈에.
- 또는 `references.bib`를 열어 `@article{` 바로 뒤 문자열.

**키가 여전히 공란이면:**
1. §1대로 BBT가 *진짜* 설치·활성화됐는지 확인(Tools → Better BibTeX 메뉴가 있나).
2. 키 형식이 비어 있을 수 있음 → **Tools → Better BibTeX → Preferences → Citation keys** 의 *Citation key format*이 비어 있으면 기본값 `auth.lower + year`(또는 `[auth:lower][year]`)로 채운다.
3. 기존 항목 키 새로고침: 항목 전체 선택 → 우클릭 → **Better BibTeX → Refresh BibTeX key**.
4. 키를 고정하려면(원고가 키에 의존하므로 권장): 우클릭 → **Better BibTeX → Pin BibTeX key**.

원고/문헌 노트에서 이 키를 그대로 쓴다: 본문 `[@russellUCLALonelinessScale1996]`, 노트 프론트매터 `citation_key: russellUCLALonelinessScale1996`.

## 5. (선택) PDF/노트 미러

로컬에 PDF를 `02_literature/pdfs/`로 모으고 노트를 자동 생성하려면:

```bash
cd 01_manuscript
Rscript _scripts/sync_zotero_literature.R
```

## 5.5 Zotero 웹 API 키 (_secrets)

위 BBT auto-export는 로컬 export라 키가 필요 없지만, **Zotero 웹 API**로 메타데이터·첨부를 가져오는 스크립트는 API 키가 필요하다. 키는 `_secrets/`에 안전하게 둔다.

1. 키 발급: <https://www.zotero.org/settings/keys> → *Create new private key* → **read** 권한 권장. key와 userID(숫자) 확인.
2. 저장 — **키를 명령에 바로 붙여넣는 방식이 가장 확실**합니다(대화형 입력이 안 되는 터미널 대응):
   ```bash
   # macOS / Linux
   bash _secrets/set_zotero_key.sh "여기에_API_KEY_붙여넣기" "여기에_userID숫자"
   ```
   ```powershell
   # Windows PowerShell
   powershell -ExecutionPolicy Bypass -File _secrets\set_zotero_key.ps1 -ApiKey "API_KEY" -UserId "userID"
   ```
   인자 없이 실행하면 대화형으로 물어보며, **입력이 화면에 보입니다**(가리면 일부 터미널에서 입력 자체가 안 되는 문제가 있어 일부러 보이게 했습니다).
   > "커맨드는 실행되는데 입력이 안 된다"면 → 위처럼 **키를 인자로 전달**하세요.
3. 스크립트/에이전트는 `_secrets/zotero.env`를 **읽기 전용**으로 로드(`set -a; . _secrets/zotero.env; set +a`)하고 키를 출력·커밋하지 않는다. (`install/secrets/README.md`)

## 6. 검증

```bash
bash <publish_templates경로>/skills/setup-manuscript-pipeline/references/install/verify.sh "<...>/01_manuscript"
```

`references.bib 존재 — 항목 N개` 와 `최근 7일 내 갱신됨`이 나오면 연동 OK.

## 자주 막히는 점

- **Zotero가 꺼져 있으면 auto-export가 안 돈다.** 글 쓰는 동안 Zotero를 열어 둔다.
- 저장 경로를 잘못 지정하면 원고가 빈 참고문헌으로 렌더된다 → 위 4번 경로를 정확히.
- 키가 바뀌면 본문 인용이 깨진다 → BBT의 "pin citation key"로 키 고정 권장(항목 우클릭 → Better BibTeX → Pin BibTeX key).
