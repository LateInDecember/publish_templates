# Obsidian 스타터 설정

`01_manuscript/`를 Obsidian vault로 쓸 때 바로 적용할 수 있는 `.obsidian/` 기본 설정입니다.

## 적용 방법

이 폴더의 `.obsidian/`를 `01_manuscript/.obsidian/`로 복사합니다. (bootstrap.sh가 자동으로, 단 기존 `.obsidian/`이 없을 때만 복사합니다.)

```bash
cp -R obsidian_starter/.obsidian "<...>/01_manuscript/.obsidian"
```

## 들어 있는 것

- **app.json**: `detectAllExtensions: true`(.qmd/.R도 보이게), `readableLineLength: false`(긴 표·마커 가독성), `showFrontmatter: true`.
- **community-plugins.json**: 활성화할 커뮤니티 플러그인 ID 목록 — `obsidian-shellcommands`(렌더 실행), `obsidian-citation-plugin`(인용), `dataview`(문헌 대시보드).
- **plugins/obsidian-shellcommands/data.json**: **"Render manuscript" 명령이 사전 바인딩**되어 있습니다. 명령 팔레트(⌘P)에서 실행하면 `Rscript _scripts/render_with_insertions.R`가 돌아갑니다.

## 중요 — 한 번은 GUI에서 직접

`community-plugins.json`은 플러그인을 **활성화**만 합니다. 플러그인 *본체 파일*은 Obsidian이 받아야 합니다:

1. Obsidian → 설정 → **커뮤니티 플러그인** → "Turn on community plugins".
2. **Browse**에서 `Shell commands`, `Citations`, `Dataview`를 설치.
3. 설치 후 Obsidian을 다시 열면 위 설정(렌더 명령 포함)이 적용됩니다.
   - 만약 "Render manuscript" 명령이 안 보이면, Shell commands 설정에서 새 명령으로 아래를 추가하세요:
     ```
     cd "{{vault_path}}" && Rscript _scripts/render_with_insertions.R
     ```

> `data.json` 스키마는 Shell commands 플러그인 버전에 따라 다를 수 있어, 위 prefill이 안 먹으면 UI에서 명령 문자열만 직접 추가하면 됩니다.
> `.obsidian/workspace*.json`(창 레이아웃)은 기기별 상태이므로 동기화/깃에서 제외하세요.
