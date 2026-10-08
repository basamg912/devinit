" Keep the terminal background; use hue plus weight, symbols and contrast.
highlight clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'colorblind_terminal'

let s:dark = &background ==# 'dark'
let s:fg = s:dark ? ['#eeeeee', 255] : ['#262626', 235]
let s:bg = s:dark ? ['#262626', 235] : ['#eeeeee', 255]
let s:muted = s:dark ? ['#bcbcbc', 250] : ['#626262', 241]
let s:blue = s:dark ? ['#87d7ff', 117] : ['#005faf', 25]
let s:amber = s:dark ? ['#ffaf00', 214] : ['#875f00', 94]
let s:purple = s:dark ? ['#ffafd7', 218] : ['#870087', 90]
let s:panel = s:dark ? ['#444444', 238] : ['#d0d0d0', 252]
let s:ansi256 = has('gui_running') || &t_Co >= 256

function! s:Hi(group, fg, bg, attr) abort
  execute 'highlight ' . a:group
        \ . ' guifg=' . a:fg[0] . ' guibg=' . a:bg[0] . ' gui=' . a:attr
        \ . ' ctermfg=' . (s:ansi256 ? a:fg[1] : 'NONE')
        \ . ' ctermbg=' . (s:ansi256 ? a:bg[1] : 'NONE')
        \ . ' cterm=' . a:attr . ' term=' . a:attr
endfunction

let s:none = ['NONE', 'NONE']
call s:Hi('Normal', s:fg, s:bg, 'NONE')
highlight Normal ctermfg=NONE ctermbg=NONE
call s:Hi('Comment', s:muted, s:none, 'NONE')
call s:Hi('Constant', s:amber, s:none, 'NONE')
call s:Hi('String', s:blue, s:none, 'NONE')
call s:Hi('Identifier', s:fg, s:none, 'NONE')
call s:Hi('Function', s:blue, s:none, 'bold')
call s:Hi('Statement', s:blue, s:none, 'bold')
call s:Hi('PreProc', s:purple, s:none, 'bold')
call s:Hi('Type', s:purple, s:none, 'NONE')
call s:Hi('Special', s:amber, s:none, 'bold')
call s:Hi('Underlined', s:blue, s:none, 'underline')
call s:Hi('Ignore', s:muted, s:none, 'NONE')
call s:Hi('Todo', s:none, s:none, 'reverse,bold')
call s:Hi('Error', s:none, s:none, 'reverse,bold')

for s:group in ['Search', 'Visual', 'PmenuSel', 'QuickFixLine']
  call s:Hi(s:group, s:none, s:none, 'reverse')
endfor
for s:group in ['IncSearch', 'CurSearch']
  call s:Hi(s:group, s:none, s:none, 'reverse,bold')
endfor
call s:Hi('MatchParen', s:none, s:none, 'bold,underline')
call s:Hi('HighlightedyankRegion', s:fg, s:panel, 'bold')
call s:Hi('LineNr', s:muted, s:none, 'NONE')
call s:Hi('CursorLineNr', s:fg, s:none, 'bold')
call s:Hi('SignColumn', s:none, s:none, 'NONE')
call s:Hi('FoldColumn', s:muted, s:none, 'NONE')
call s:Hi('Folded', s:fg, s:panel, 'NONE')
call s:Hi('NonText', s:muted, s:none, 'NONE')
call s:Hi('SpecialKey', s:muted, s:none, 'NONE')
call s:Hi('Pmenu', s:fg, s:panel, 'NONE')
call s:Hi('PmenuSbar', s:none, s:panel, 'NONE')
call s:Hi('PmenuThumb', s:none, s:muted, 'NONE')
call s:Hi('StatusLine', s:bg, s:fg, 'bold')
call s:Hi('StatusLineNC', s:fg, s:panel, 'NONE')
highlight! link TabLine StatusLineNC
highlight! link TabLineSel StatusLine
highlight! link TabLineFill StatusLineNC
call s:Hi('VertSplit', s:muted, s:none, 'NONE')
call s:Hi('Directory', s:blue, s:none, 'bold')
call s:Hi('Title', s:purple, s:none, 'bold')
call s:Hi('ErrorMsg', s:blue, s:none, 'bold,underline')
call s:Hi('WarningMsg', s:amber, s:none, 'bold')
call s:Hi('MoreMsg', s:fg, s:none, 'bold')
call s:Hi('Question', s:fg, s:none, 'bold')
call s:Hi('ModeMsg', s:fg, s:none, 'bold')
for s:group in ['SpellBad', 'SpellCap', 'SpellLocal', 'SpellRare']
  call s:Hi(s:group, s:none, s:none, 'underline')
endfor
call s:Hi('CopilotSuggestion', s:muted, s:none, 'italic')

call s:Hi('ALEErrorSign', s:blue, s:none, 'bold')
call s:Hi('ALEWarningSign', s:amber, s:none, 'bold')
call s:Hi('ALEInfoSign', s:muted, s:none, 'bold')
call s:Hi('ALEError', s:none, s:none, 'underline,bold')
call s:Hi('ALEWarning', s:none, s:none, 'underline')
highlight! link ALEStyleErrorSign ALEErrorSign
highlight! link ALEStyleWarningSign ALEWarningSign
highlight! link ALEStyleError ALEError
highlight! link ALEStyleWarning ALEWarning
highlight! link ALEInfo ALEWarning

call s:Hi('GitGutterAdd', s:blue, s:none, 'bold')
call s:Hi('GitGutterChange', s:amber, s:none, 'bold')
call s:Hi('GitGutterDelete', s:purple, s:none, 'bold')
highlight! link GitGutterChangeDelete GitGutterDelete
highlight! link diffAdded GitGutterAdd
highlight! link diffChanged GitGutterChange
highlight! link diffRemoved GitGutterDelete
call s:Hi('DiffAdd', s:fg, s:dark ? ['#005f87', 24] : ['#afd7ff', 153], 'NONE')
call s:Hi('DiffDelete', s:fg, s:dark ? ['#5f005f', 53] : ['#ffd7ff', 225], 'bold')
call s:Hi('DiffChange', s:fg, s:panel, 'NONE')
call s:Hi('DiffText', s:fg, s:dark ? ['#875f00', 94] : ['#ffd7af', 223], 'bold,underline')

" Lightline's default palette includes red/green mode blocks.
let s:strong = [s:bg[0], s:fg[0], s:bg[1], s:fg[1], 'bold']
let s:quiet = [s:fg[0], s:panel[0], s:fg[1], s:panel[1]]
let s:middle = [s:fg[0], s:bg[0], s:fg[1], s:bg[1]]
let g:lightline#colorscheme#colorblind_terminal#palette = {
      \ 'normal': {'left': [s:strong, s:quiet], 'right': [s:strong, s:quiet],
      \            'middle': [s:middle], 'error': [s:strong], 'warning': [s:strong]},
      \ 'inactive': {'left': [s:quiet], 'right': [s:quiet], 'middle': [s:middle]},
      \ 'tabline': {'left': [s:quiet], 'right': [s:quiet],
      \             'middle': [s:middle], 'tabsel': [s:strong]},
      \ }
for s:mode in ['insert', 'replace', 'visual', 'command', 'terminal']
  let g:lightline#colorscheme#colorblind_terminal#palette[s:mode] =
        \ deepcopy(g:lightline#colorscheme#colorblind_terminal#palette.normal)
endfor
if exists('g:loaded_lightline')
  call lightline#init()
  call lightline#colorscheme()
  call lightline#update()
endif
