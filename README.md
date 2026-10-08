# Vim Colorblind

Vim에서 사용하는 파랑·황갈색·자주색 문법 팔레트를 Zed와 iTerm2로 옮긴 테마다.
GitHub의 흰색 / `#0d1117` 배경을 유지하며 Light/Dark 버전을 제공한다.

## Zed

`vim-colorblind.json`을 `~/.config/zed/themes/`에 설치하고 다음 설정으로 선택한다.
새 테마가 목록에 나타나지 않으면 Zed를 다시 실행한다.

```json
{
  "theme": {
    "mode": "system",
    "light": "Vim Colorblind Light",
    "dark": "Vim Colorblind Dark"
  }
}
```

문법색, 함수·키워드 굵기, 진단, Git 상태, 검색, 선택, 내장 터미널,
Vim 모드 표시를 포함한다. Zed 선택 영역은 문법색을 유지하므로 반전 대신
옅은 배경을 사용한다. 설정 방법은 [Zed 공식 문서](https://zed.dev/docs/themes)를 따른다.

## iTerm2

`Vim-Colorblind-Light.itermcolors`, `Vim-Colorblind-Dark.itermcolors`는
Settings > Profiles > Colors > Color Presets > Import로 가져올 수 있다.

자동 전환용 `Vim-Colorblind.iterm-profile.json`을
`~/Library/Application Support/iTerm2/DynamicProfiles/Vim-Colorblind.json`에 설치하면
**Profiles > Vim Colorblind**에서 선택할 수 있다. Default 프로필의 폰트·키·쉘 설정을
상속하며 밝은·어두운 색상을 별도로 지정한다. 이 프로필을 기본으로 쓰려면
Settings > Profiles에서 선택한 뒤 Other Actions > Set as Default로 지정한다.

ANSI 적색 슬롯은 자주색, 녹색 슬롯은 파랑으로 표시해 일반적인 Git diff의 삭제·추가를
구분한다. 선택 영역은 검정·흰색 반전이며 커서는 밝은 배경에서 파랑,
어두운 배경에서 주황이다. 글자가 흐려지는 것을 방지하기 위해 투명도와
Smart Cursor Color는 끈다.

[iTerm2 색상 문서](https://iterm2.com/documentation-preferences-profiles-colors.html),
[Dynamic Profiles 문서](https://iterm2.com/documentation-dynamic-profiles.html)를 참고했다.

## 팔레트와 검증

색을 변경할 때는 `colorblind-palette.json`을 수정한 뒤 생성기를 실행한다.
Vim의 문법 팔레트와 일치하는지, 생성된 Zed/iTerm2의 색이 일치하는지도 검사한다.

```sh
python3 scripts/build_colorblind_themes.py
python3 tests/theme_ports.py
```

검증한 문법·선택·검색·diff·진단·UI·ANSI 전경의 최소 텍스트 대비는
Light **4.65:1**, Dark **6.69:1**이다. Zed JSON은 공식 테마 스키마도 통과했다.
터미널 프로그램이 직접 지정하는 RGB/256색이나 임의의 ANSI 배경 조합은
16색 팔레트의 대비 보장 범위에 포함되지 않는다.

Vim 설정 변경 이유와 키 목록은 [VIM_REVIEW.md](VIM_REVIEW.md)에 정리했다.
이번 설치 전 설정은 Zed의 `settings.json.before-vim-colorblind-20261004`와
iTerm2의 `com.googlecode.iterm2.plist.before-vim-colorblind-20261004`에 백업했다.

## tmux

`tmux/tmux.conf`를 `~/.tmux.conf`에 설치한다. 기존 `Ctrl-b`를 유지하며
Vim식 패널 이동·복사, 현재 디렉터리에서 분할, 세션 저장·수동 복원과
밝은/어두운 접근성 팔레트를 제공한다.
플러그인 목록과 짧은 사용법은 [TMUX_GUIDE.md](TMUX_GUIDE.md)에 정리했다.

```sh
python3 tests/tmux_config.py
```

## 기존 GitHub 테마

기존 `github-colorblind-split.json`과 Catppuccin 프리셋은 그대로 제공한다.

```sh
cp github-colorblind-split.json ~/.config/zed/themes/
```
