# 작업 파이프라인 (분석 → 동기화 → 렌더)

표·그림이 바뀌어야 할 때는 **항상 이 순서**다. 원고 폴더의 산출물을 직접 고치지 않는다(분석이 단일 출처).

## 전체 흐름

```
[분석]  02_anal/00_code/*  (R/Python/MATLAB — 도구 중립)
   │  실행
   ▼
[reporting]  02_anal/03_results/06_reporting/{docs,figures,tables}/{main,supplementary}
   │  sync_reporting_assets.R (렌더가 자동 호출; reporting_root 기본 = 02_anal/03_results/06_reporting)
   ▼
[미러]  01_manuscript/04_synced/{tables,figures}      ← 읽기 전용
   │  render_with_insertions.R 가 마커를 실제 파일로 치환
   ▼
[원고]  01_manuscript/manuscript.md  +  03_assets/figures (손제작)
   │  quarto render (embed-resources HTML)
   ▼
[산출물]  01_manuscript/05_output/manuscript.docx, manuscript.html
```

## 단계별 명령

1. **분석 실행** (결과·수치가 바뀐 경우):
   ```bash
   cd 02_anal
   # R 예: Rscript 00_code/00_setup.R … (번호 순서대로)
   # Python 예: python 00_code/00_setup.py …
   # 결과가 03_results/06_reporting 에 갱신됨
   ```
   > 분석 도구는 자유(R/Python/MATLAB). `render_with_insertions.R`(마커·표 삽입)만 R이 필요하다.

2. **동기화 확인(선택)**:
   ```bash
   cd 01_manuscript
   Rscript _scripts/sync_reporting_assets.R --dry-run
   ```

3. **렌더**(동기화 자동 포함):
   ```bash
   cd 01_manuscript
   Rscript _scripts/render_with_insertions.R
   # 또는 Finder에서 01_source/render.command 더블클릭
   ```

4. **결과 확인**: `05_output/manuscript.docx`, `manuscript.html`.

## 주의

- **외형만 변경**(figure 제목/라벨/서식)도 분석 코드/라벨 설정에서 한다. 원고나 `04_synced/`에서 직접 고치지 않는다(다음 동기화 때 덮어써짐).
- 렌더 전에 **Word에서 열려 있는 `manuscript.docx`를 닫는다**(잠금 시 덮어쓰기 실패; `~$...docx` 잠금파일이 흔적).
- `05_output/`에 그림/스타일 **복사 폴더**가 생기면 `_quarto.yml`의 html에 `embed-resources: true`가 있는지 확인(단일 HTML로 임베드 → 복사 안 생김).
- 표/그림을 추가·삭제하면 `render_with_insertions.R` 안의 **마커 매핑**과 `sync_reporting_assets.R`의 **copy_specs**를 함께 갱신한다.
