set nocompatible              " be iMproved, required

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" ************** plugins **************

" editor
Plug 'sjl/gundo.vim'

" Style and syntax
"Plug 'altercation/vim-colors-solarized'
Plug 'crusoexia/vim-monokai'
Plug 'vim-syntastic/syntastic'
Plug 'pearofducks/ansible-vim'
Plug 'joshdick/onedark.vim'
Plug 'ltlollo/diokai'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'hdima/python-syntax'
Plug 'tmux-plugins/vim-tmux'
Plug 'sheerun/vim-polyglot'
Plug 'segeljakt/vim-silicon'

" File management
Plug 'tpope/vim-fugitive'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
" https://github.com/Xuyuanp/nerdtree-git-plugin
Plug 'ctrlpvim/ctrlp.vim'
" https://github.com/ctrlpvim/ctrlp.vim

" Clojure
Plug 'guns/vim-clojure-static'
Plug 'kien/rainbow_parentheses.vim'
Plug 'tpope/vim-fireplace'
Plug 'vim-scripts/paredit.vim'
" https://github.com/vim-scripts/paredit.vim/blob/master/doc/paredit.txt
Plug 'tpope/vim-surround'
" https://github.com/tpope/vim-surround

call plug#end()
" To ignore plugin indent changes, instead use:
"filetype plugin on

" Brief help
" :PlugList       - lists configured plugins
" :PlugInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PlugSearch foo - searches for foo; append `!` to refresh local cache
" :PlugClean      - confirms removal of unused plugins; append `!` to auto-approve removal

" see :h vundle for more details or wiki for FAQ

" ************** visual **************
"syntax on
"set background=grey
"colorscheme solarized
"colorscheme spacegray
"colorscheme monokai
colorscheme diokai
"colorscheme onedark

"*** vim-airline
set laststatus=2
"let g:airline_theme='understated'
let g:airline_theme='bubblegum'
"let g:airline_theme='ubaryd'
"let g:airline_powerline_fonts = 1
let g:airline_symbols_ascii = 1
let g:Powerline_symbols = 'fancy'
set encoding=utf-8
set t_Co=256
set fillchars+=stl:\ ,stlnc:\
set term=xterm-256color
set termencoding=utf-8
let g:airline#extensions#tabline#enabled = 1
set diffopt+=iwhiteall

" ************** shortcuts **************
" leader Shortcuts
let mapleader = ","

" plugin shortcuts
nnoremap <leader>u :GundoToggle<CR>     " Visual undo
noremap <leader>n :NERDTreeToggle<CR>
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

" tab Management
nnoremap <C-h> :tabp<CR>
nnoremap <C-l> :tabn<CR>
nnoremap <C-n> :tabnew<CR>

" toggle line numbers
noremap <leader>m :set invnumber<CR>
inoremap <leader>m :set invnumber<CR>

" folding
set foldenable          " enable folding
set foldlevelstart=10   " open most folds by default
set foldnestmax=10      " 10 nested fold max
set foldmethod=indent   " fold based on indent level
nnoremap <space> za     " space opens and closes folds

" ui config
set number              " show line numbers
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
set wildmenu            " visual autocomplete for command menu
set pastetoggle=<F2> " paste toggle
noremap <Leader>s :update<CR> " quick save

" spaces and tabs
set tabstop=4  		" number of visual spaces per TAB
set softtabstop=4	" number of spaces in tab when editing
set expandtab 		" tabs are spaces

" searching
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
nnoremap <leader><space> :nohlsearch<CR> " Clear search

" insert mode escape
inoremap jk <Esc>
inoremap kj <Esc>
inoremap jj <Esc>
inoremap kk <Esc>

" remove trailing white space
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" ************** movement **************
" move vertically by visual line
nnoremap j gj
nnoremap k gk
" highlight last inserted text
nnoremap gV `[v`]

" allows cursor change in tmux mode
if exists('$TMUX')
        let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
        let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
        let &t_SI = "\<Esc>]50;CursorShape=1\x7"
        let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" moves the backup dir to tmp
set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set backupskip=/tmp/*,/private/tmp/*
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set writebackup

" " Ensure private editing.
" Usage - VIM_PRIVATE=1 vim
if $VIM_PRIVATE
  set nobackup
  set nowritebackup
  set noundofile
  set noswapfile
  set viminfo=""
  set noshelltemp
  set history=0
  set nomodeline
  set secure
  colorscheme onedark
endif


" ************** fixes **************
" back space
set backspace=indent,eol,start

" removes trailing whitespaces
autocmd BufWritePre *.py :%s/\s\+$//e

" ansible
let g:ansible_options = {'ignore_blank_lines': 0}

" fix slow yaml
au BufNewFile,BufRead *.yaml,*.yml so ~/.vim/yaml.vim

" keeps .netrwlist out of vim
let g:netrw_home=$XDG_CACHE_HOME.'/vim'

" opens nerdtree if vim opens on a dir
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" closes vim if nerdtree is the only window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" ************** syntax **************
" syntax Checker

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%{fugitive#statusline()}
set statusline+=%*

" ansible
let g:ansible_name_highlight = 'd'

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

function Py2()
  let g:syntastic_python_python_exec = '/usr/local/bin/python2.7'
endfunction

function Py3()
  let g:syntastic_python_python_exec = '/usr/local/bin/python3.6'
endfunction

call Py3()   " default to Py3 because I try to use it when possible

