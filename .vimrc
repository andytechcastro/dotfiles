""""""""""""""""""""""""""""""""
""" Andres Castro Vim Config """
""""""""""""""""""""""""""""""""

filetype off                  " required
set nocompatible
syntax on
set wrap
set encoding=utf8
set relativenumber
set number
set hlsearch
set incsearch
:highlight LineNr ctermfg=grey
set tabstop=4 shiftwidth=4 expandtab 
au BufRead,BufNewFile *.hx set filetype=hx
autocmd BufRead,BufNewFile *.blade.php set filetype=blade
filetype plugin on
set omnifunc=syntaxcomplete#Complete

call has('python3')
 
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

Plugin 'jiangmiao/auto-pairs'

Plugin 'altercation/vim-colors-solarized'

Plugin 'arcticicestudio/nord-vim'

Plugin 'mhinz/vim-signify'

Plugin 'airblade/vim-gitgutter'

Plugin 'tpope/vim-fugitive'

Plugin 'jwilm/i3-vim-focus'

Plugin 'alvan/vim-closetag'

Plugin 'ctrlpvim/ctrlp.vim'

Plugin 'scrooloose/syntastic'

Plugin 'jalvesaq/Nvim-R'

Plugin 'chrisbra/csv.vim'

Plugin 'valloric/youcompleteme'

Plugin 'majutsushi/tagbar'

Plugin 'honza/vim-snippets'

Plugin 'MarcWeber/vim-addon-mw-utils'

Plugin 'tomtom/tlib_vim'

Plugin 'garbas/vim-snipmate'

Plugin 'jimf/vim-pep8-text-width'

Plugin 'francoiscabrol/ranger.vim'

Plugin 'vim-vdebug/vdebug'

Plugin 'grep.vim'

Plugin 'jwalton512/vim-blade'

Plugin 'OrangeT/vim-csharp'

Plugin 'stephpy/vim-php-cs-fixer'

Plugin 'powerline/powerline'

Plugin 'yggdroot/indentline'

Plugin 'stanangeloff/php.vim'

Plugin 'hashivim/vim-terraform'

Plugin 'juliosueiras/vim-terraform-completion'

Plugin 'ekalinin/dockerfile.vim'

Plugin 'stephpy/vim-yaml'

Plugin 'dbakker/vim-projectroot'

"maps NERDTree
map <Tab> :NERDTreeToggle<CR>

"Colors Solarized Dark
syntax enable
set background=dark
colorscheme nord

"vim-airline
"let g:airline_solarized_bg='dark'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts=1
let g:Powerline_symbols='unicode'
let g:powerline_pycmd = 'py3'
set  rtp+=/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim/
set laststatus=2
set t_Co=256
set term=xterm-kitty

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
noremap <c-m>1 :call CutilDebug()<CR>

function! CutilDebug()
    r ~/.vim/recordings/debug
    normal! 2f,
    call feedkeys('i')
endfunction

"Funciones llamando texto
noremap <c-m>c :call CController()<CR>
noremap <c-m>m :call CModel()<CR>
noremap <c-m>f :call CForm()<CR>
noremap <c-m>v :call CValidator()<CR>

"syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_php_phpcs_args='--standard=PSR2'

"Tagbar
nmap <F8> :TagbarToggle<CR>

let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]

"VDebug
let g:vdebug_features = { 'max_children': 256 }
let g:vdebug_options = {'ide_key': 'docker'}
let g:vdebug_options = {'break_on_open': 0}
"let g:vdebug_options = {'server': '172.17.0.1'}
let g:vdebug_options = {'server': '127.0.0.1'}
let g:vdebug_options = {'port': '9000'}
"let g:vdebug_options = {'path_maps':{'/var/www/html':'/home/andres/public_html/newWordpress/wordpress/_data'}}
"let g:vdebug_options = {'path_maps':{'/var/www/html': getcwd()}}

" PROJECTROOT
"let g:rootmarkers = ['.projectroot', 'docker-compose.yml', '.git', '.hg', '.svn', '.bzr','_darcs','build.xml']
let g:rootmarkers = ['.projectroot']

function! SetupDebug()
  let g:vdebug_options['path_maps'] = {'/var/www/html': call('projectroot#get', a:000)}
  " Hack to override vdebug options
  source ~/.vim/bundle/vdebug/plugin/vdebug.vim
endfunction
autocmd VimEnter * :call SetupDebug()

"open horizontal windows dow
:set splitbelow

"open vertical windows rigth
:set splitright

let g:php_cs_fixer_rules = "@PSR2"
autocmd BufWritePost *.php silent! call PhpCsFixerFixFile()

"terraform
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1

let g:ctrlp_working_path_mode=0


" workaround issue with powerline + virtualenv
" https://github.com/powerline/powerline/issues/1908
python3 << EOF
import sys
path = "/usr/lib/python{}.{}/site-packages/".format(
    sys.version_info.major, sys.version_info.minor)
sys.path.append(path)
EOF
