# Zotero ↔ 원고 연동 (Better BibTeX auto-export)

목표: Zotero의 참고문헌 컬렉션이 바뀌면 `01_manuscript/01_source/references.bib`가 **자동으로 갱신**되어, 원고의 `[@key]` 인용이 항상 최신 서지와 연결되게 한다.

## 1. Better BibTeX 설치

1. Zotero 데스크톱 설치: <https://www.zotero.org/download/>
2. BBT `.xpi` 다운로드: <https://retorque.re/zotero-better-bibtex/installation/>
3. Zotero → **Tools → Plugins(또는 Add-ons) → 톱니바퀴 → Install Plugin From File…** → 받은 `.xpi` 선택 → Zotero 재시작.

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

## 4. 인용 키(citation key) 규칙

- BBT가 항목마다 citation key를 만든다(예: `russellUCLALonelinessScale1996`).
- 키 확인: 항목 선택 → 우측 패널의 Better BibTeX citation key, 또는 `references.bib`의 `@article{` 뒤 문자열.
- 원고/문헌 노트에서 이 키를 그대로 쓴다: 본문 `[@russellUCLALonelinessScale1996]`, 노트 프론트매터 `citation_key: russellUCLALonelinessScale1996`.

## 5. (선택) PDF/노트 미러

로컬에 PDF를 `02_literature/pdfs/`로 모으고 노트를 자동 생성하려면:

```bash
cd 01_manuscript
Rscript _scripts/sync_zotero_literature.R
```

## 6. 검증

```bash
bash <publish_templates경로>/skills/setup-manuscript-pipeline/references/install/verify.sh "<...>/01_manuscript"
```

`references.bib 존재 — 항목 N개` 와 `최근 7일 내 갱신됨`이 나오면 연동 OK.

## 자주 막히는 점

- **Zotero가 꺼져 있으면 auto-export가 안 돈다.** 글 쓰는 동안 Zotero를 열어 둔다.
- 저장 경로를 잘못 지정하면 원고가 빈 참고문헌으로 렌더된다 → 위 4번 경로를 정확히.
- 키가 바뀌면 본문 인용이 깨진다 → BBT의 "pin citation key"로 키 고정 권장(항목 우클릭 → Better BibTeX → Pin BibTeX key).
