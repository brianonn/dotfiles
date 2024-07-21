" init.vim                  - for neovim (nvim)
" shared with ~/.vim/vimrc  - for vim
" ~/.vim/vimrc should just be a link to this init.vim
"

let g:is_nvim = has('nvim')
let g:is_vim8 = v:version >= 800 ? 1 : 0
let g:config_dir = g:is_nvim ? stdpath('config') : $HOME . '/.vim'

let g:vimdata = has('win32') ? expand("$APPDATA") : expand("~/.cache/vim-data")
if !isdirectory(g:vimdata) | call mkdir(g:vimdata, 'p', 0o0700) | endif

let &directory = g:vimdata . '/swap/'         | call mkdir(&directory, 'p', 0o0700)
let &backupdir = g:vimdata . '/autobackups//' | call mkdir(&backupdir, 'p', 0o700)
let &undodir   = g:vimdata . '/undo//'        | call mkdir(&undodir, 'p', 0o700)
" echom 'swap: ' . &directory
" echom 'backup: ' . &backupdir
" echom 'undo: ' . &undodir
set backup
set undofile
augroup prewrites
    autocmd BufWritePre,FileWritePre * let &bex = "-" . strftime("%Y%m%d-%H%M%S") . "~"
augroup end

" Reuse nvim's runtimepath and packpath in vim
if !g:is_nvim && g:is_vim8
  set runtimepath-=~/.vim
    \ runtimepath^=~/.local/share/nvim/site runtimepath^=~/.vim
    \ runtimepath-=~/.vim/after
    \ runtimepath+=~/.local/share/nvim/site/after
    \ runtimepath+=~/.vim/after
    \ runtimepath+=~/.fzf
  let &packpath = &runtimepath
endif

" setup plugins
call plug#begin("~/.config/nvim/plugged")

Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'norcalli/nvim-colorizer.lua'
Plug 'lewis6991/gitsigns.nvim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'wting/rust.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': { -> fzf#install} }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'nvim-tree/nvim-web-devicons' " instead of NERDTree
Plug 'nvim-tree/nvim-tree.lua'
Plug 'tmhedberg/SimpylFold' " python aware folding. See also FastFold: https://github.com/Konfekt/FastFold
Plug 'sbdchd/neoformat'     " code formatter
Plug 'neomake/neomake'      " async make
Plug 'unblevable/quick-scope' " f, F, t, T helper
Plug 'sirver/ultisnips'   " snippet engine
Plug 'honza/vim-snippets' " some useful snippets for ultisnip
" These ones I am not sure about them all
Plug 'easymotion/vim-easymotion'
Plug 'yegappan/taglist'
Plug 'mhinz/vim-grepper'
Plug 'preservim/tagbar'
Plug 'williamboman/mason.nvim'   " dependency manager
Plug 'williamboman/mason-lspconfig.nvim'   " dependency manager

let g:UltiSnipsExpandTrigger="<tab>"
" I removed these plugins
"Plug 'projekt0n/caret.nvim'
"Plug 'junegunn/rainbow_parentheses.vim'

call plug#end()

" ==============================
" === Options
" ==============================
set background="dark"
set autoindent
set copyindent
set enc=utf-8
set expandtab
set hidden
set history=1000
set hlsearch
set ignorecase
set incsearch
set infercase
set modeline
set nocompatible
set noerrorbells
set nowrap
set number
set relativenumber
set ruler
set scrolloff=2
set shiftround
set shiftwidth=4
set showmatch
set smartcase
set smartindent
set smarttab
set tabstop=4
set termguicolors
set undolevels=1000
set visualbell
set nofoldenable


set background="dark"
silent! colorscheme snow
hi Normal guibg=#0a0a0a

set wildignore=*~,*.swp,*.bak,*.bck,*.pyc,*.class,*.o,*.obj,*.a,*.DS_Store,*.__*,*/node_modules/*,_site,__pycache__,*/venv/*,*,*,*/.log/,*/.aux,*/.cls
if exists("&wildignorecase")
    set wildignorecase
endif

" use :set list  to turn on (use :set nolist to turn off)
set listchars=eol:$,tab:>.,trail:.,extends:>,precedes:<

" let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
let g:fzf_layout = { 'left': '~70%' }
"set backup
"let b = g:config_dir . '/autobackups'
""echom 'backups: ' . b
"echom 'data: ' . stdpath('data')

"if !isdirectory(backupdir)
"    call mkdir(backupdir)
"endif
"let &backupdir = backupdir

" ==============================
" === Mappings
" ==============================
let mapleader=','

nmap <space> zz         "center the line

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

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

nmap <silent> <leader>/ :nohlsearch<CR>

" stop J from jumoing to the end of the joined text, by setting a mark
nnoremap J mzJ`z

" center after next search and paragraph movements
nnoremap n nzz
nnoremap N Nzz
nnoremap } }zz
nnoremap { {zz

" map ; to : so you can press ;w not <shift>:<unshift>w
nnoremap ; :

" forgot to SU?? can't write a file?? use w!!
cmap w!! w !sudo tee % >/dev/null

" If we're in neovim, run Lua init at the end
if g:is_nvim
    lua require('init')
endif

" finally, source local scripts
exe 'source ' . g:config_dir . '/script/a.vim'

