---
name: write-literature-note
description: Writes a structured Obsidian literature-review note for an academic paper (PDF or reference), using a 17-section paper-review template with YAML frontmatter. Use when the user says "이 논문 노트로 정리해줘", "문헌 리뷰 노트 작성", "PDF를 노트로", "make a literature note", "review this paper", or wants to add a paper to 02_literature/notes/. Reads the paper, extracts metadata + citation key, fills the template, and saves with the author-year filename rule.
---

# Write Literature Review Note

학술 논문(PDF 또는 서지정보)을 받아 **17섹션 구조의 Obsidian 문헌 리뷰 노트**로 작성한다. 양식은 `references/literature_note_template.md`다.

## 절차

1. **입력 확보**: 대상 논문의 PDF(`02_literature/pdfs/` 또는 사용자가 준 경로)를 읽는다. PDF가 없으면 `references.bib` 항목·초록·사용자 제공 정보로 가능한 범위까지 작성하고, 확인 불가한 항목은 `Needs verification`로 표기한다.

2. **메타데이터 추출**: 저자, 연도, 제목, 저널, DOI, Zotero 링크/키, **citation key**(Better BibTeX, `references.bib`의 `@...{` 뒤 문자열)를 채운다.

3. **템플릿 채우기**: `references/literature_note_template.md`의 17개 섹션을 논문 내용으로 채운다.
   - 본문에서 **실제로 확인된 내용만** 단정한다. 불확실하면 `Needs verification`.
   - 요약(3), 핵심 발견(9), 비판적 평가(11)는 **이 논문 자체**에 대한 평가로 쓴다. (예시 템플릿의 특정 주제 문구를 그대로 남기지 말 것 — 대상 논문에 맞게 다시 쓴다.)
   - 14장 관계(Supports/Contradicts/Extends)는 같은 vault의 다른 노트를 `[[wikilink]]`로 연결한다.
   - 13장 "내 연구에 적용"은 사용자의 현재 연구 맥락이 있으면 그것에 맞춰, 없으면 일반적 시사점으로 쓴다.

4. **프론트매터**: `type: paper-review`, `status: reviewed|to-read|core|candidate|dropped`, `priority`, `field`, `theme`, `keywords`, `authors`, `year`, `journal`, `doi`, `zotero`/`zotero_item_key`, `attachment_*`, `citation_key`, `created`, `updated`(오늘 날짜)를 채운다.

5. **파일명·저장**: `02_literature/notes/`에 저장. 파일명은 PDF 파일명 규칙과 일치:
   - 1인 `Author(Year) - Short title.md`
   - 2인 `Author1 & Author2(Year) - Short title.md`
   - 3인 `Author1, Author2 & Author3(Year) - Short title.md`
   - 4인 이상 `Author et al(Year) - Short title.md`

6. **인덱스 갱신(선택)**: `02_literature/index.md`에 새 노트 링크를 추가하거나, Dataview가 자동 집계하면 생략.

## 원칙

- **단정 금지**: 원문에서 확인 못한 수치·결과를 지어내지 않는다. `Needs verification`를 쓴다.
- **인용 키 정확성**: `citation_key`는 `references.bib`와 정확히 일치해야 원고 인용이 연결된다.
- **paraphrase 우선**: 15장 인용구 외에는 원문 직접복사 대신 요약·해석으로 쓴다.
- 한 번에 여러 PDF를 요청받으면 각각 별도 노트로 작성한다.
