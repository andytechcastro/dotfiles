""""""""""""""""""""""""""""""""
""" Andres Castro Vim Config """
""""""""""""""""""""""""""""""""

filetype off                  " required
set nocompatible
syntax on
set nowrap
set encoding=utf8
set relativenumber
set number
set hlsearch
:highlight LineNr ctermfg=grey
set tabstop=4 shiftwidth=4 expandtab 
au BufRead,BufNewFile *.hx set filetype=hx
 
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')
 
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
 
" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
" Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
" Plugin 'user/L9', {'name': 'newL9'}
 
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

Plugin 'scrooloose/nerdtree'

Plugin 'vim-airline/vim-airline'

Plugin 'vim-airline/vim-airline-themes'

Plugin 'severin-lemaignan/vim-minimap'

Plugin 'tpope/vim-surround'

Plugin 'Valloric/MatchTagAlways'

Plugin 'vim-scripts/RltvNmbr.vim'

Plugin 'shawncplus/phpcomplete.vim'

Plugin 'Townk/vim-autoclose'

Plugin 'altercation/vim-colors-solarized'

Plugin 'mhinz/vim-signify'

Plugin 'airblade/vim-gitgutter'

Plugin 'tpope/vim-fugitive'

Plugin 'jwilm/i3-vim-focus'

Plugin 'alvan/vim-closetag'

"maps NERDTree
map <Tab> :NERDTreeToggle<CR>

"Colors Solarized Dark
syntax enable
set background=dark
colorscheme solarized

"vim-airline
let g:airline_solarized_bg='dark'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts=1
let g:Powerline_symbols='unicode'
set  rtp+=/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim/
set laststatus=2
set t_Co=256

"set moving between windows to ctrl+arrows
nnoremap <silent> <C-Right> <c-w>l
nnoremap <silent> <C-Left> <c-w>h
nnoremap <silent> <C-Up> <c-w>k
nnoremap <silent> <C-Down> <c-w>j

" set moving between windows to ctrl+hjkl
noremap <silent> <C-l> <c-w>l
noremap <silent> <C-h> <c-w>h
noremap <silent> <C-k> <c-w>k
noremap <silent> <C-j> <c-w>j

"Funciones llamando texto
inoremap <buffer><expr> <c-f> Debug()

function! Debug()
    return "\\CUtil::debug('andres', print_r('',true).chr(10), FILE_APPEND);"
endfunction
