""""""""""""""""""""""""""""""""
""" Andres Castro Vim Config """
""""""""""""""""""""""""""""""""

filetype off                  " required
set nocompatible
syntax on
set nowrap
set encoding=utf8
set relativenumber
:highlight LineNr ctermfg=grey
set tabstop=4 shiftwidth=4 smarttab
 
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

"maps NERDTree
map <Tab> :NERDTreeToggle<CR>

"Colors Solarized Dark
syntax enable
set background=dark
colorscheme solarized

"color vim-airline
let g:airline_solarized_bg='dark'
