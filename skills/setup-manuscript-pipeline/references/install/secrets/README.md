# _secrets/ — API 키 안전 보관소

Zotero 같은 외부 서비스의 **API 키를 안전하게** 두는 폴더입니다. agentic AI(Codex/Claude 등)는 이 폴더의 키를 **읽어서** Zotero API를 호출할 수 있지만, 키를 **출력·로그·커밋하지 않습니다**.

## 들어 있는 것

| 파일 | 커밋 여부 | 설명 |
|---|---|---|
| `zotero.env.example` | ✅ 커밋 (빈 placeholder) | 형식 예시 |
| `zotero.env` | ❌ **절대 커밋 안 함** (.gitignore + 권한 600) | 실제 키 |
| `set_zotero_key.sh` / `.ps1` | ✅ 커밋 | 키를 복붙해 `zotero.env`를 안전하게 만드는 헬퍼 |

## 키 넣는 법 (복붙 한 번)

1. Zotero 키 발급: <https://www.zotero.org/settings/keys> → *Create new private key* → **read** 권한 권장. 발급된 key와 같은 페이지의 **userID(숫자)** 확인.
2. 헬퍼 실행:
   ```bash
   # macOS / Linux
   bash _secrets/set_zotero_key.sh
   ```
   ```powershell
   # Windows
   powershell -ExecutionPolicy Bypass -File _secrets\set_zotero_key.ps1
   ```
   키를 붙여넣으면(화면에 안 보임) `_secrets/zotero.env`가 권한 600으로 생성됩니다.

## 에이전트(Codex/Claude) 사용 규칙 — 안전

- **읽기 전용으로만** `_secrets/zotero.env`를 읽어 `ZOTERO_API_KEY` / `ZOTERO_USER_ID`를 얻는다.
- 키 값을 **채팅·로그·코드·커밋 메시지에 절대 출력하지 않는다**. (확인이 필요하면 길이/마지막 4자리 정도만.)
- `zotero.env`를 **git에 추가하지 않는다**(이미 .gitignore 처리). 새 키가 필요하면 헬퍼로 다시 생성.
- 스크립트에서 사용 예:
  ```bash
  set -a; . _secrets/zotero.env; set +a   # ZOTERO_API_KEY 등 환경변수로 로드
  ```
  ```r
  readRenviron("_secrets/zotero.env"); key <- Sys.getenv("ZOTERO_API_KEY")
  ```

## 왜 이렇게

API 키는 자격증명이라 코드·문서에 박으면 유출 위험이 큽니다. 그래서 (1) 키는 gitignore된 별도 파일에만 두고, (2) placeholder/헬퍼만 저장소에 커밋하며, (3) 에이전트는 읽기만 하고 출력하지 않습니다.
