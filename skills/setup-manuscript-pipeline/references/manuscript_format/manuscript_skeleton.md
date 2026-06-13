<!--
Journal template note:
- Target format: 인지 및 생물 심리학회지 원고 양식, 2020판 (기본값). 다른 저널이면 양식 교체.
- Full format note: 01_source/notes/journal_format_kjcbp_2020.md
- Checklist: 01_source/notes/journal_requirements.md
- Quarto YAML(author/date)은 표제부로 쓰지 않고, 본문 첫머리에 제목→저자→소속→저자주→영문요약 순서로 직접 작성.
- 심사용 원고는 저자/소속/저자주를 익명 처리.
- 표 제목은 표 위, 그림 제목은 그림 아래, 모두 영문. 본문 1단, 쪽번호, 신명조 10pt, 줄간격 160.
-->

# <논문 제목> {.unnumbered .unlisted}

익명

소속 익명(OO 대학교)

::: {.author-note}

:::

## 영문요약

<English abstract ~600자.>

**Keywords:** <keyword1, keyword2, keyword3, keyword4, keyword5>

## 서론

<도입: 현상·문제 정의 → 선행연구 → 공백 → 본 연구 목적/가설.>

### <소절 제목>

<...>

## 연구방법

### 연구대상

<표본, 모집·선별, 윤리.>

### 측정도구

<척도/도구와 신뢰도.>

### <자료 및 지표 산출>

<...>

### 과제 및 절차

{{figure:1}}

### 분석 자료 수집/처리

<...>

### 통계분석

<분석 전략·모형.>

## 연구결과

### 기술통계/인구통계학적 특성

{{table:1}}

### <가설 1 결과>

{{figure:2}}

{{table:3}}

### <가설 2 결과>

{{table:4}}

## 논의

<요약 → 해석 → 선행연구와 통합 → 한계 → 함의/결론.>

## 참고문헌

<!-- Quarto가 references.bib + apa.csl로 자동 생성. 본문 인용 [@key] 사용. -->

## 국문요약

<국문 요약 ~600자.>

**주제어:** <주제어1, 주제어2, 주제어3, 주제어4, 주제어5>

## 부록

{{figure:s1}}
{{figure:s2}}

{{table:s1}}
{{table:s2}}

<!--
마커 매핑은 _scripts/render_with_insertions.R 의 table/figure map에서 실제 파일로 연결한다.
표/그림을 추가·삭제하면 이 골격의 마커와 스크립트의 매핑을 함께 갱신할 것.
-->
