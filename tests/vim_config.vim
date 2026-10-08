" Run in a PTY: vim -Nu NONE -i NONE -n -es -S tests/vim_config.vim
set nocompatible
set t_Co=256
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:runtime = s:root . '/vimrc'
execute 'set runtimepath^=' . fnameescape(s:runtime)
for s:file in ['basic', 'filetypes', 'plugins_config', 'extended']
  execute 'source ' . fnameescape(s:runtime . '/vimrcs/' . s:file . '.vim')
endfor
execute 'source ' . fnameescape(s:runtime . '/my_configs.vim')
runtime plugin/ale.vim
runtime plugin/gitgutter.vim
runtime plugin/lightline.vim
runtime plugin/lightline/ale.vim
runtime plugin/highlightedyank.vim
runtime autoload/ale/sign.vim
let g:ale_enabled = 0
let g:gitgutter_enabled = 0
let s:temp = tempname() . ' vim config'
call mkdir(s:temp, 'p', 0700)
let s:cwd = getcwd()
let s:records = []

try
  call assert_equal('colorblind_terminal', g:colors_name)
  call assert_equal(1, g:matchparen_disable_cursor_hl)
  call assert_equal(0, &termguicolors)
  call assert_equal('yes', &signcolumn)
  call assert_equal(1, &swapfile)
  call assert_equal(1, &writebackup)
  call assert_equal(1, &undofile)
  call assert_equal(0, &textwidth)
  call assert_equal('<Plug>snipMateNextOrTrigger', maparg('<C-j>', 'i'))
  for s:mode in ['n', 'i', 'x']
    call assert_match('PersonalCompileRun', maparg('<F5>', s:mode))
  endfor
  for s:background in ['light', 'dark']
    execute 'set background=' . s:background
    call assert_equal('colorblind_terminal', g:colors_name)
    call assert_equal(s:background ==# 'dark' ? '117' : '25',
          \ synIDattr(hlID('ALEErrorSign'), 'fg', 'cterm'))
    call assert_equal('1', synIDattr(hlID('Search'), 'reverse', 'cterm'))
    call assert_equal('', synIDattr(hlID('Search'), 'bg', 'cterm'))
    for s:highlight_mode in ['cterm', 'gui']
      call assert_equal('1', synIDattr(hlID('MatchParen'), 'bold', s:highlight_mode))
      call assert_equal('1', synIDattr(hlID('MatchParen'), 'underline', s:highlight_mode))
      call assert_notequal('1', synIDattr(hlID('MatchParen'), 'reverse', s:highlight_mode))
      call assert_equal('', synIDattr(hlID('MatchParen'), 'bg', s:highlight_mode))
    endfor
    let s:groups = {}
    for s:group in ['Comment', 'Constant', 'String', 'Identifier', 'Function',
          \ 'Statement', 'PreProc', 'Type', 'Special', 'LineNr',
          \ 'ALEErrorSign', 'ALEWarningSign', 'GitGutterAdd', 'GitGutterDelete',
          \ 'GitGutterChange', 'DiffAdd', 'DiffDelete', 'DiffChange', 'DiffText',
          \ 'StatusLine', 'StatusLineNC', 'Pmenu', 'CopilotSuggestion',
          \ 'HighlightedyankRegion']
      let s:id = synIDtrans(hlID(s:group))
      let s:groups[s:group] = {
            \ 'fg': synIDattr(s:id, 'fg', 'gui'), 'bg': synIDattr(s:id, 'bg', 'gui'),
            \ 'ctermfg': synIDattr(s:id, 'fg', 'cterm'),
            \ 'ctermbg': synIDattr(s:id, 'bg', 'cterm')}
    endfor
    call add(s:records, {'background': s:background, 'groups': s:groups,
          \ 'lightline': deepcopy(g:lightline#colorscheme#colorblind_terminal#palette)})
  endfor
  execute 'source ' . fnameescape(s:runtime . '/my_configs.vim')
  call assert_equal('colorblind_terminal', g:lightline.colorscheme)
  call assert_equal(250, g:highlightedyank_highlight_duration)
  enew
  call setline(1, ['first line', 'second line'])
  normal! yy
  sleep 20m
  let s:yank_matches = filter(getmatches(), 'v:val.group ==# "HighlightedyankRegion"')
  call assert_false(empty(s:yank_matches))
  call assert_equal("first line\n", getreg('"'))
  sleep 300m
  call assert_true(empty(filter(getmatches(), 'v:val.group ==# "HighlightedyankRegion"')))
  normal! 0yw
  sleep 20m
  call assert_false(empty(filter(getmatches(), 'v:val.group ==# "HighlightedyankRegion"')))
  call assert_equal('first ', getreg('"'))
  sleep 300m
  normal! 0v4ly
  sleep 20m
  call assert_false(empty(filter(getmatches(), 'v:val.group ==# "HighlightedyankRegion"')))
  call assert_equal('first', getreg('"'))
  sleep 300m
  normal! dd
  sleep 20m
  call assert_true(empty(filter(getmatches(), 'v:val.group ==# "HighlightedyankRegion"')))
  setlocal nomodified
  call assert_equal('E', sign_getdefined('ALEErrorSign')[0].text->trim())
  call assert_equal('W', sign_getdefined('ALEWarningSign')[0].text->trim())
  call assert_equal('~', sign_getdefined('GitGutterLineModified')[0].text->trim())
  doautocmd CursorColor VimEnter
  call assert_equal("\e[2 q", &t_EI)
  call assert_equal("\e[6 q", &t_SI)
  call assert_equal("\e[4 q", &t_SR)
  enew
  setfiletype javascript
  call assert_equal(1, maparg('<C-a>', 'i', 0, 1).buffer)
  call assert_equal('manual', &foldmethod)
  call assert_equal(999, &foldlevel)
  call assert_equal(0, &textwidth)

  execute 'cd ' . fnameescape(s:temp)
  let s:source = s:temp . "/hello space's !%.cpp"
  call writefile(['#include <fstream>', '#include <bits/stdc++.h>',
        \ 'int main() { std::ofstream("ran.txt") << "gcc"; }'], s:source)
  execute 'edit ' . fnameescape(s:source)
  call assert_equal('ale#completion#OmniFunc', &l:omnifunc)
  call assert_equal('', maparg('<C-a>', 'i'))
  call assert_equal('', maparg('<C-t>', 'i'))
  let s:mp = &makeprg
  let s:efm = &errorformat
  call SetCppCompiler('gcc', 1)
  call assert_equal(['cc'], g:ale_linters.cpp)
  call CompileRunCpp()
  call assert_equal(['gcc'], readfile(s:temp . '/ran.txt'))
  call assert_equal(s:mp, getbufvar(bufnr(s:source), '&makeprg'))
  call assert_equal(s:efm, getbufvar(bufnr(s:source), '&errorformat'))
  call delete(s:temp . '/ran.txt')
  call setline(1, ['int main() { invalid syntax; }'])
  2,$delete _
  call CompileRunCpp()
  call assert_false(filereadable(s:temp . '/ran.txt'))
  call assert_true(len(filter(getqflist(), 'v:val.valid && toupper(v:val.type) ==# "E"')) > 0)
  call assert_equal(s:mp, getbufvar(bufnr(s:source), '&makeprg'))
  call assert_equal(s:efm, getbufvar(bufnr(s:source), '&errorformat'))
  cclose
  execute 'buffer ' . bufnr(s:source)
  call setline(1, ['#include <fstream>',
        \ 'int main() { std::ofstream("ran.txt") << "clang"; }'])
  call SetCppCompiler('clang', 1)
  call assert_equal(['clangd'], g:ale_linters.cpp)
  call CompileRunCpp()
  call assert_equal(['clang'], readfile(s:temp . '/ran.txt'))

  let s:python = s:temp . '/runner space.py'
  call writefile(['from pathlib import Path', 'Path("python.txt").write_text("python")'], s:python)
  execute 'edit ' . fnameescape(s:python)
  call PersonalCompileRun()
  call assert_equal(['python'], readfile(s:temp . '/python.txt'))

  let s:c = s:temp . '/runner space.c'
  call writefile(['#include <stdio.h>',
        \ 'int main(void) { FILE *f = fopen("c.txt", "w"); fputs("c", f); fclose(f); }'], s:c)
  execute 'edit ' . fnameescape(s:c)
  call PersonalCompileRun()
  call assert_equal(['c'], readfile(s:temp . '/c.txt'))

  let s:undo = s:temp . '/undo.txt'
  call writefile(['before'], s:undo)
  execute 'edit ' . fnameescape(s:undo)
  call setline(1, 'after')
  write
  bwipeout
  execute 'edit ' . fnameescape(s:undo)
  undo
  call assert_equal('before', getline(1))
  setlocal nomodified
  if !empty($VIM_COLOR_AUDIT)
    call writefile([json_encode(s:records)], $VIM_COLOR_AUDIT)
  endif
catch
  call add(v:errors, v:exception . ' at ' . v:throwpoint)
finally
  execute 'cd ' . fnameescape(s:cwd)
  call delete(s:temp, 'rf')
endtry
if !empty(v:errors)
  for s:error in v:errors
    echom s:error
  endfor
  cquit
endif
qa!
