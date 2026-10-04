# Vim 설정 점검

실제 시작 파일은 `~/.vimrc`이며 amix 설정을 읽은 뒤
`~/.vim_runtime/my_configs.vim`으로 덮어쓴다. 저장소 루트의 `.vimrc`는
이와 다른 간단한 설정이다. 이번 변경은 실제 사용하는 개인 설정에 적용했다.

## 확인한 문제와 변경

| 기존 설정 | 판단과 적용 |
| --- | --- |
| `colorscheme default` + 강제 `background=dark` | 터미널 배경을 유지하려는 목적은 타당하지만 밝은 배경과 진단·diff 색상까지 보장하지 못했다. 배경별 접근성 테마를 추가했다. |
| 주석 처리된 검색 강조 | `Search`의 기존 배경색까지 초기화하고 반전으로 표시한다. 현재 검색 위치와 괄호에는 굵기도 추가한다. `Esc`로 강조를 지우는 동작은 유지한다. |
| 오류 적색, Git 추가 녹색·삭제 적색 | 파랑·황갈색·자주색과 `E/W/I`, `+/~/-`를 함께 사용한다. 오류 밑줄, 모드 이름, 커서 모양으로 색 이외의 단서도 제공한다. |
| 고정 주황색 커서 | 밝은 배경에서 대비가 부족하다. 밝은 배경은 파랑, 어두운 배경은 주황으로 바꾼다. Normal/Insert/Replace는 블록/세로선/밑줄이다. |
| `t_EI = "\e[2;34m"` 등 | 문자 색상용 SGR 시퀀스다. 커서 모양용 `CSI 2 q / 6 q / 4 q`로 바로잡았다. 종료·일시중지 때 기본 커서를 복원한다. |
| Normal 모드 F5가 항상 C++ 실행 | 모든 모드에서 파일 형식에 맞게 실행한다. C/C++ 컴파일 실패는 quickfix에 표시하고 실행을 중단한다. 파일명은 shell escape하며 실행 파일은 임시 경로에서 정리한다. |
| `noswapfile`, `nowritebackup` | Git은 저장 전 편집을 복구하지 못한다. swap과 저장 중 백업을 활성화하고 Undo/swap 디렉터리를 프로젝트 밖에 생성한다. |
| `textwidth=500` | 긴 코드 줄을 실제 개행할 수 있다. 코드의 자동 개행을 끄고 화면 줄바꿈은 유지한다. `j/k`는 화면 줄, `5j` 등은 실제 줄로 이동한다. |
| 자동 sign 열 | 진단이 나타날 때 화면이 움직인다. 항상 한 칸을 확보하며 같은 줄에서는 진단이 Git 표시보다 우선한다. |
| 저장할 때만 진단 | 파일 진입과 저장 시 검사한다. 입력 중 검사는 기존처럼 끈다. 상태줄에는 오류·경고 개수를 연결한다. |
| 오래된 grep/파일 탐색 설정 | `rg`가 있으면 Ack, `:grep`, CtrlP에 연결한다. Git ignore 규칙을 활용하며 숨김 파일도 CtrlP에서 탐색한다. |
| 수동 folding이 파일 종류별 설정에 덮어써짐 | FileType 이후에도 수동 folding과 열린 fold 수준을 적용한다. |
| Copilot/SnipMate의 `Tab` 충돌 | 기존 스니펫 `Ctrl-j`를 공식 Plug 매핑으로 연결하여 중복 매핑 오류를 제거한다. |
| JS의 `Ctrl-a` / `Ctrl-t`가 전역 매핑 | JavaScript/TypeScript 버퍼에만 적용해 다른 파일에서 기존 키 동작을 보존한다. |
| 터미널 MRU 메뉴 오류 | GUI 메뉴 생성은 GUI에서만 활성화하며 최근 파일 목록 `,f`는 유지한다. |

## 색상 검증

ANSI 16색 슬롯은 터미널 테마에 따라 실제 색이 달라진다. 주요 문법·상태·diff
표시는 256색 팔레트의 고정 인덱스를 쓰고 터미널의 기본 배경은 유지한다.
`termguicolors`를 강제하지 않는다. GUI에서는 같은 RGB 값을 사용한다.
색상 테마 변경 시 Vim의 `background` 값에 따라 다시 적용된다.
터미널이 배경 변경을 알려주지 않으면 `:set background=light` 또는
`:set background=dark`로 맞출 수 있다.

Latte `#eff1f5`, Mocha `#1e1e2e`, GitHub light `#ffffff`, GitHub dark `#0d1117`을
기준으로 주요 문법, 주석, 진단, Git, diff, 팝업, 상태줄의 텍스트 대비를 계산했다.
검증한 색 쌍은 모두 **4.5:1 이상**, 최소 **4.94:1**이다. 이 수치는 검증한
배경에 대한 결과이며 다른 터미널 배경이나 플러그인 고유 강조색 전체를 보장하지는 않는다.
16색 전용 터미널에서는 문법 강조를 기본 전경색과 굵기 중심으로 축소한다.

색만으로 상태를 전달하지 않는 원칙과 대비 계산은
[W3C 색상 사용 지침](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html),
[W3C 대비 지침](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)을 참고했다.

## 기존 선택 중 유지할 이유

- `number relativenumber`: 현재 줄 번호와 상대 이동 거리를 함께 볼 수 있다.
- `nocursorline`: 배경 강조로 문법 색이 흐려지는 것을 피하는 선택이다.
- `foldmethod=manual`: 자동으로 코드가 접히는 것을 원하지 않는 현재 선택을 유지한다.
- GCC/Clang 분리: 코딩 테스트의 `bits/stdc++.h`는 Apple Clang의 libc++에 없다. GCC 모드에서는 `cc` 검사만 사용한다. Clang 모드에서는 설치된 `clangd`로 정의·참조·자동완성을 제공하며, 실제 프로젝트의 `compile_commands.json`을 기준으로 한다.
- `ignorecase smartcase incsearch`, `autoread`, persistent Undo, EditorConfig, surround, repeat, commentary는 이미 포함되어 있다. 같은 기능의 플러그인을 추가할 필요가 없다.
- 시스템 클립보드는 `+` 레지스터 단축키로 연결했다. 기본 yank/delete 레지스터 동작은 유지한다.

[ALE 공식 문서](https://github.com/dense-analysis/ale),
[GitGutter 공식 문서](https://github.com/airblade/vim-gitgutter),
[Vim 복구 문서](https://vimhelp.org/recover.txt.html),
[Vim 터미널 문서](https://vimhelp.org/term.txt.html)를 확인했다.

## 바로 사용할 키

Leader는 기존과 동일한 쉼표다.

| 키 / 명령 | 동작 |
| --- | --- |
| `F5` | C/C++ 컴파일·실행 또는 Python/Shell/Go/Java/Octave 실행, HTML 열기 |
| `:CppCompiler gcc` / `:CppCompiler clang` | 코딩 테스트 / Clang 개발 모드 |
| `]e` / `[e` | 다음 / 이전 진단 |
| `,ad` / `,ai` / `,al` | 진단 목록 / ALE 실행 환경 확인 / 수동 검사 |
| `]q` / `[q` | 다음 / 이전 검색 결과 또는 컴파일 오류 |
| `,g` | 프로젝트 검색 |
| `Ctrl-f` | CtrlP 파일 탐색 |
| `,hp` / `]c` / `[c` | Git 변경 미리보기 / 다음 / 이전 변경 |
| `,ld` / `,lr` / `,lh` / `,ln` | 정의 / 참조 / 설명 / 이름 변경. 해당 언어 서버 필요 |
| `Ctrl-x Ctrl-o` | 수동 자동완성. C++은 Clang 모드의 clangd 필요 |
| `,y` / `,Y` / `,P` | 시스템 클립보드로 선택·모션 복사 / 한 줄 복사 / 붙여넣기 |
| Visual `<` / `>` | 선택을 유지하며 들여쓰기 변경 |

현재 시스템에는 `g++-16`, `clang++`, `clangd`, `rg`가 있다. `flake8`, `eslint`는
PATH에서 발견되지 않았다. Python/JavaScript 진단은 프로젝트에서 해당 실행 파일을
제공해야 하며 `,ai`로 실제 사용 가능 여부를 확인할 수 있다.

## 검증 재실행

`F5`의 외부 프로그램 실행을 확인하므로 첫 명령은 터미널에서 실행한다.

```sh
VIM_COLOR_AUDIT=/tmp/vim-colors.json vim -Nu NONE -i NONE -n -es -S tests/vim_config.vim
node tests/contrast.mjs /tmp/vim-colors.json
```

GCC/Clang 성공, 잘못된 코드의 quickfix, 공백·특수문자 파일명, Python/C 실행,
Undo 재로딩, 밝은·어두운 테마, sign 기호, 모드별 F5, 커서 시퀀스를 검증한다.
