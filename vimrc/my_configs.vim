"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Accessible colors; terminal background, adaptive semantic highlights
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Undo the upstream forced dark background so OSC 11 can detect the terminal.
if get(g:, 'colors_name', '') !=# 'colorblind_terminal'
  set background&
endif
if !has('gui_running') && has('termguicolors')
  set notermguicolors
endif
if exists('g:lightline')
  let g:lightline.colorscheme = 'colorblind_terminal'
  let g:lightline.component_expand = {
        \ 'linter_checking': 'lightline#ale#checking',
        \ 'linter_errors': 'lightline#ale#errors',
        \ 'linter_warnings': 'lightline#ale#warnings',
        \ }
  let g:lightline.component_type = {'linter_errors': 'error', 'linter_warnings': 'warning'}
  let g:lightline.active.right = [
        \ ['linter_checking', 'linter_errors', 'linter_warnings'], ['lineinfo'], ['percent']]
  let g:lightline.component.readonly = '%{&readonly?"RO":""}'
endif
colorscheme colorblind_terminal

" Keep matching-paren highlights from overriding the actual cursor.
let g:matchparen_disable_cursor_hl = 1

" DECSCUSR uses a space before q; SGR color codes do not set cursor shape.
function! s:ConfigureCursor() abort
  let &t_EI = "\e[2 q"
  let &t_SI = "\e[6 q"
  let &t_SR = "\e[4 q"
  let l:color = &background ==# 'dark' ? '#ffaf00' : '#005faf'
  call echoraw("\e]12;" . l:color . "\x07")
endfunction

if !has('gui_running') && exists('*echoraw')
  augroup CursorColor
    autocmd!
    autocmd VimEnter,VimResume * call <SID>ConfigureCursor()
    autocmd OptionSet background call <SID>ConfigureCursor()
    autocmd ColorScheme colorblind_terminal call <SID>ConfigureCursor()
    autocmd VimLeave,VimSuspend * call echoraw("\e]112\x07\e[0 q")
  augroup END
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Settings carried over from the old vimrc, not covered above
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Clear search highlights until the next search.
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
set number relativenumber
set softtabstop=4
set nocursorline
set fileencoding=utf-8
set foldmethod=manual
set foldlevel=999
set ttimeoutlen=50
" 자동 주석 생성 autocmd FileType * setlocal formatoptions-=r formatoptions-=o

" Prefer 5 lines of scroll context over the awesome vimrc default of 7
set scrolloff=5
set signcolumn=yes
set textwidth=0
set wildmode=longest:full,full
set wildignorecase
set wildignore+=*/node_modules/*,*/.venv/*,*/__pycache__/*

" Keep recovery files outside projects. Git does not protect unsaved edits.
let s:state = empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME
let s:state .= '/vim'
call mkdir(s:state . '/swap', 'p', 0700)
call mkdir(s:state . '/undo', 'p', 0700)
let &directory = s:state . '/swap//'
let &undodir = s:state . '/undo//'
set swapfile writebackup nobackup undofile

" Official Plug mappings let SnipMate see Ctrl-j and leave Copilot's Tab.
imap <C-j> <Plug>snipMateNextOrTrigger
smap <C-j> <Plug>snipMateNextOrTrigger
let g:MRU_Add_Menu = has('gui_running')

function! s:ScopeJavaScriptMappings() abort
  silent! iunmap <C-t>
  silent! iunmap <C-a>
  inoremap <buffer> <C-t> console.log();<Esc>hi
  inoremap <buffer> <C-a> alert();<Esc>hi
endfunction

augroup PersonalEditing
  autocmd!
  " Upstream FileType callbacks otherwise re-enable syntax folding in JS.
  autocmd FileType * setlocal foldmethod=manual foldlevel=999
  autocmd FileType c,cpp,python,javascript,typescript,go setlocal textwidth=0
  autocmd FileType cpp setlocal omnifunc=ale#completion#OmniFunc
  autocmd FileType javascript,typescript call <SID>ScopeJavaScriptMappings()
  autocmd CursorHold * if mode() !=# 'c' | checktime | endif
augroup END

" Follow wrapped screen lines while retaining counted j/k motions.
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
xnoremap < <gv
xnoremap > >gv
nnoremap <silent> <leader>y "+y
xnoremap <silent> <leader>y "+y
nnoremap <silent> <leader>Y "+yy
nnoremap <silent> <leader>P "+p

if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case --color=never'
  set grepprg=rg\ --vimgrep\ --smart-case\ --color=never
  set grepformat=%f:%l:%c:%m
  let g:ctrlp_user_command = 'rg --files --hidden -g "!.git" %s'
  let g:ctrlp_use_caching = 0
endif
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]e :ALENextWrap<CR>
nnoremap <silent> [e :ALEPreviousWrap<CR>
nnoremap <silent> <leader>ad :lopen<CR>
nnoremap <silent> <leader>ai :ALEInfo<CR>
nnoremap <silent> <leader>al :ALELint<CR>
nnoremap <silent> <leader>hp :GitGutterPreviewHunk<CR>
nnoremap <silent> <leader>ld :ALEGoToDefinition<CR>
nnoremap <silent> <leader>lr :ALEFindReferences<CR>
nnoremap <silent> <leader>lh :ALEHover<CR>
nnoremap <silent> <leader>ln :ALERename<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => C++ compiler switch (coding-test GCC vs regular-dev Clang)
"    :CppCompiler gcc    -> g++-16 (GNU/libstdc++, has bits/stdc++.h,
"                           for coding-test sites that assume GCC)
"    :CppCompiler clang  -> clang++ (LLVM/libc++, for normal dev)
"    Drives F5 and selects ALE's compiler checker or Clang language server.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:cpp_compilers = {
\   'gcc':   {'exe': 'g++-16', 'opts': '-std=c++17 -Wall -O2'},
\   'clang': {'exe': 'clang++', 'opts': '-std=c++17 -Wall -O2'},
\}

function! SetCppCompiler(name, ...) abort
  let l:silent = a:0 > 0 && a:1
  if !has_key(s:cpp_compilers, a:name)
    echoerr 'Unknown cpp compiler: ' . a:name . ' (use gcc or clang)'
    return
  endif
  if !executable(s:cpp_compilers[a:name].exe)
    echoerr 'Compiler not found: ' . s:cpp_compilers[a:name].exe
    return
  endif
  let g:cpp_compiler = a:name
  let g:ale_cpp_cc_executable = s:cpp_compilers[a:name].exe
  let g:ale_cpp_cc_options = s:cpp_compilers[a:name].opts
  " clangd uses the project's compile_commands.json; GCC avoids its false
  " bits/stdc++.h diagnostics. Manual completion: <C-x><C-o>.
  let g:ale_linters.cpp = a:name ==# 'clang' && executable('clangd') ? ['clangd'] : ['cc']
  if &filetype ==# 'cpp' && exists(':ALELint')
    ALELint
  endif
  if !l:silent
    echo 'cpp compiler: ' . a:name . ' (' . s:cpp_compilers[a:name].exe . ')'
  endif
endfunction

command! -nargs=1 -complete=customlist,{a,l,p->keys(s:cpp_compilers)} CppCompiler call SetCppCompiler(<f-args>)

function! CompileRunCpp() abort
  let l:c = s:cpp_compilers[get(g:, 'cpp_compiler', 'gcc')]
  if &filetype ==# 'c'
    let l:exe = get(g:, 'cpp_compiler', 'gcc') ==# 'gcc' && executable('gcc-16') ? 'gcc-16' : 'clang'
    let l:c = {'exe': l:exe, 'opts': '-std=c17 -Wall -O2'}
  endif
  if empty(expand('%:p')) || &buftype !=# ''
    echoerr 'Open a C++ source file first'
    return
  endif
  if !executable(l:c.exe)
    echoerr 'Compiler not found: ' . l:c.exe
    return
  endif
  write
  let l:binary = tempname()
  let l:buffer = bufnr('')
  let l:makeprg = &l:makeprg
  let l:errorformat = &l:errorformat
  let l:compiler = get(b:, 'current_compiler', '')
  try
    compiler gcc
    let l:command = shellescape(l:c.exe) . ' ' . l:c.opts . ' -fdiagnostics-color=never '
          \ . shellescape(expand('%:p')) . ' -o ' . shellescape(l:binary)
    let l:output = system(l:command)
    let l:failed = v:shell_error
    call setqflist([], ' ', {'title': l:c.exe . ' ' . expand('%:t'),
          \ 'lines': split(l:output, "\n"), 'efm': &l:errorformat})
    if l:failed
      copen
      echohl ErrorMsg
      echom 'Compilation failed; see quickfix (:cnext / :cprevious)'
      echohl None
      return
    endif
    cwindow
    execute '!' . shellescape(l:binary, 1)
  finally
    call setbufvar(l:buffer, '&makeprg', l:makeprg)
    call setbufvar(l:buffer, '&errorformat', l:errorformat)
    if empty(l:compiler)
      call win_execute(bufwinid(l:buffer), 'unlet! b:current_compiler')
    else
      call setbufvar(l:buffer, 'current_compiler', l:compiler)
    endif
    call delete(l:binary)
  endtry
endfunction

function! PersonalCompileRun() abort
  if &filetype ==# 'cpp' || &filetype ==# 'c'
    call CompileRunCpp()
    return
  endif
  let l:runners = {
        \ 'python': ['python3'], 'sh': ['bash'], 'go': ['go', 'run'],
        \ 'matlab': ['octave'], 'java': ['java'],
        \ }
  if &filetype ==# 'html'
    let l:runners.html = has('macunix') ? ['open'] : ['xdg-open']
  endif
  if !has_key(l:runners, &filetype)
    echoerr 'F5 runner not configured for filetype: ' . &filetype
    return
  endif
  if empty(expand('%:p')) || &buftype !=# ''
    echoerr 'Open a source file first'
    return
  endif
  let l:argv = l:runners[&filetype] + [expand('%:p')]
  if !executable(l:argv[0])
    echoerr 'Runner not found: ' . l:argv[0]
    return
  endif
  write
  execute '!' . join(map(l:argv, 'shellescape(v:val, 1)'), ' ')
endfunction
nnoremap <silent> <F5> :call PersonalCompileRun()<CR>
inoremap <silent> <F5> <Esc>:call PersonalCompileRun()<CR>
xnoremap <silent> <F5> <Esc>:call PersonalCompileRun()<CR>

" Default to GCC (current coding-test setup); switch anytime with
" :CppCompiler clang
let s:default_cpp = executable('g++-16') ? 'gcc' : 'clang'
call SetCppCompiler(get(g:, 'cpp_compiler', s:default_cpp), 1)

" Signs and underlines carry meaning independently of hue.
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
let g:ale_sign_info = 'I'
let g:ale_sign_style_error = 'E'
let g:ale_sign_style_warning = 'W'
let g:ale_sign_priority = 100
let g:ale_echo_msg_format = '[%severity%] %linter%: %s'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_save = 1
let g:ale_set_highlights = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Git gutter
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" plugins_config.vim turns it off; show git diff signs by default.
" ,d still toggles it.
let g:gitgutter_enabled = 1
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '-'
let g:gitgutter_sign_removed_above_and_below = '--'
let g:gitgutter_sign_modified_removed = '~-'
let g:gitgutter_sign_priority = 10
let g:gitgutter_set_sign_backgrounds = 0
