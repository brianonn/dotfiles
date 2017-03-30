set nocompatible
set nowrap
set ignorecase
set smartcase
set smarttab
set autoindent
set copyindent
set smartindent
set tabstop=4
set shiftwidth=4
set shiftround
set expandtab
set showmatch
set hidden
set visualbell
set noerrorbells
set ruler
set hls
set incsearch
set number
set title
set nobackup
set enc=utf-8
set modeline

"TODO: install vundle plugin manager
"ctrlp - fuzzt file finder like sublime
"fugitive git tool
"syntastic ??

"set directory=~/.vim/swapfiles,.
set shell=/bin/bash

set history=1000
set undolevels=1000
set ignorecase
set infercase
set wildignore=*.swp,*.bak,*.pyc,*.class,*.o,*.obj,*.a
if exists("&wildignorecase")
    set wildignorecase
endif

filetype on
filetype plugin indent on 
call pathogen#infect()
call pathogen#helptags()

if has('autocmd')

    " Remove all autocommands first so they don't duplicate when sourcing this file
    autocmd! 

    autocmd BufRead,BufNewFile *.v,*.vh setfiletype verilog
    autocmd BufRead,BufNewFile *.vhd    setfiletype vhdl

    autocmd FileType c,cc,cpp,h set cindent
    autocmd FileType c,cc,cpp,h colorscheme  camo
    autocmd FileType ruby,python colorscheme camo
    autocmd FileType python set expandtab
    autocmd FileType verilog set expandtab tabstop=4 softtabstop=2 shiftwidth=2
    autocmd FileType vhdl    set expandtab tabstop=4 softtabstop=2 shiftwidth=2
    autocmd FileType ChangeLog set tw=80
    autocmd Filetype gitcommit setlocal spell textwidth=72
endif

let mapleader=','
" center the line
nmap <space> zz 

" highlight next
nnoremap <silent> n n:call HLNext(0.4)<cr>
nnoremap <silent> N N:call HLNext(0.4)<cr>

" function HLNext (blinktime)
"     set invcursorline
"     redraw
"     exec 'sleep ' . float2nr(a:blinktime * 1000) . 'm'
"     set invcursorline
"     redraw
" endfunction

function! HLNext (blinktime)
    let [bufnum, lnum, col, off] = getpos('.')
    let matchlen = strlen(matchstr(strpart(getline('.'),col-1),@/))
    let target_pat = '\c\%#'.@/
    let blinks = 3
    for n in range(1,blinks)
        let red=matchadd('WarningMsg', target_pat, 101)
        redraw
        exec 'sleep ' . float2nr(a:blinktime / (2*blinks) * 1000) . 'm'
        call matchdelete(red)
        redraw
        exec 'sleep ' . float2nr(a:blinktime / (2*blinks) * 1000) . 'm'
    endfor
endfunction

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>


if has("win32")
    "Windows options here
else
  if has("unix")
     let s:uname = system("uname -s")
     if (match(s:uname,'Darwin') >= 0)
       "Mac options here
     endif
     if (match(s:uname,'SunOS') >= 0)
       "SunOS options here
       set guifont=*   " fixes "E665: Cannot start GUI, no valid font found"
     endif
  endif
endif

" syntax hylighting if there are enough colors
if &t_Co > 2 || has('gui_running')
  syntax on
  colorscheme camo
endif

"-----------------------------------------------------------
" scroll horizontally     {{{2
"-----------------------------------------------------------
nnoremap <M-Left>  zH
nnoremap <M-Right> zL
inoremap <M-Left>  <Esc>zHi
inoremap <M-Right> <Esc>zLi
nnoremap j gj
nnoremap k gk
" navigate windows more easily
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

"emacs like begin/end of line and enter insert mode
map <C-a> <ESC>I
imap <C-a> <ESC>I
map <C-e> <ESC>A
imap <C-e> <ESC>A

nmap <silent> ,/ :nohlsearch<CR>

" map ; to : so you can press ;w not <shift>:<unshift>w 
nnoremap ; :

" swap tick and backtick.  backtick command is more useful but tick is easier
" to reach
nnoremap ' `
nnoremap ` '

vmap Q gq
nmap Q gqap

" forgot to SU?? can't write a file?? use w!! 
cmap w!! w !sudo tee % >/dev/null

"Rebuild cscope
map <Leader>cs !cscope -bqk<cr>:cs add cscope.out<cr>

let g:tag = '<C-]>'     " push a ctags tag
let g:pop = '<C-[>'     " pop a ctags tag

"CCTree.vim support
"
fun! VimrcSetupCCTree()
    "prefer cctree.out over cscope.out

    if filereadable('cctree.out') 
	CCTreeLoadXRefDBFromDisk cctree.out
    elseif filereadable('cscope.out') 
	CCTreeLoadDB cscope.out
    endif

    let g:CCTreeKeyTraceForwardTree = '<C-\>>'
    let g:CCTreeKeyTraceReverseTree = '<C-\><'
    let g:CCTreeKeyHilightTree = '<C-l>'        " Static highlighting
    let g:CCTreeKeySaveWindow = '<C-\>y'
    let g:CCTreeKeyToggleWindow = '<C-\>w'
    let g:CCTreeKeyCompressTree = 'zs'     " Compress call-tree
    let g:CCTreeKeyDepthPlus = '<C-\>='
    let g:CCTreeKeyDepthMinus = '<C-\>-'

endfun

autocmd VimEnter * call VimrcSetupCCTree()
" TagsList doesn't work on MacOSX, use Tagbar instead. Seems better anyways.
" autocmd VimEnter * TlistToggle
"autocmd VimEnter * TagbarToggle
" nmap <F8> :TagbarToggle<CR>
" let g:Tlist_Use_Right_Window = 1  

"autocmd VimEnter * NERDTree

set ofu=syntaxcomplete#Complete

autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP

" Replaced by clang_complete for now
" " autocmd FileType c set omnifunc=ccomplete#CompleteCpp

fun! StripTrailingWhitespace()
endfun
"do something before writing a file
"autocmd BufWritePre * call StripTrailingWhitespace()

" use :set list  to turn on (use :set nolist to turn off)
set listchars=eol:$,tab:>.,trail:.,extends:>,precedes:<

"source ~/.vim/plugin/matchit.vim
if exists('loaded_matchit')
let b:match_ignorecase=0
let b:match_words=
\ '\<begin\>:\<end\>,' .
\ '\<if\>:\<else\>,' .
\ '\<module\>:\<endmodule\>,' .
\ '\<class\>:\<endclass\>,' .
\ '\<program\>:\<endprogram\>,' .
\ '\<clocking\>:\<endclocking\>,' .
\ '\<property\>:\<endproperty\>,' .
\ '\<sequence\>:\<endsequence\>,' .
\ '\<package\>:\<endpackage\>,' .
\ '\<covergroup\>:\<endgroup\>,' .
\ '\<primitive\>:\<endprimitive\>,' .
\ '\<specify\>:\<endspecify\>,' .
\ '\<generate\>:\<endgenerate\>,' .
\ '\<interface\>:\<endinterface\>,' .
\ '\<function\>:\<endfunction\>,' .
\ '\<task\>:\<endtask\>,' .
\ '\<case\>\|\<casex\>\|\<casez\>:\<endcase\>,' .
\ '\<fork\>:\<join\>\|\<join_any\>\|\<join_none\>,' .
\ '`ifdef\>:`else\>:`endif\>,'
endif

augroup HiglightTODO
    autocmd!
    autocmd WinEnter,VimEnter * :silent! call matchadd('myTodo', '\(GGGG\|TODO\|FIXME\|XXX\)[:]?',-1)
augroup END

command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
 	\ | wincmd p | diffthis

command! MyMake make! -j4 | copen
map <f2> :MyMake<CR>
map <f3> :cp<CR>
map <f4> :cn<CR>
imap <f2> <ESC>:MyMake<CR>
imap <f3> <ESC>:cp<CR>
imap <f4> <ESC>:cn<CR>

"add a W command to write when you have no permission. :W will do it
command! W w !sudo tee % > /dev/null

if has('gui_running')
  set lines=50
  set columns=175
endif

if exists('&relativenumber')
  set relativenumber
  autocmd InsertLeave,BufWinEnter,WinEnter,FocusGained * :setlocal relativenumber
  autocmd InsertEnter,BufWinLeave,WinLeave,FocusLost   * :setlocal number
endif

"paste code use :IX or :SP or :start,end SP. URL is in clipbpard register +
command! -range=% SP  silent execute <line1> . "," . <line2> . "w !curl -F 'sprunge=<-' http://sprunge.us | tr -d '\\n' | xclip -selection clipboard"
command! -range=% IX  silent execute <line1> . "," . <line2> . "w !curl -F 'f:1=<-' ix.io | tr -d '\\n' | xclip -selection clipboard"

