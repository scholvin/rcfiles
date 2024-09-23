" Ab Initio file handling

autocmd BufNewFile,BufRead *.dml set filetype=abinitio
autocmd BufNewFile,BufRead *.xfr set filetype=abinitio

autocmd BufRead,BufNewFile *.appconf set filetype=xml
autocmd BufRead,BufNewFile *.apptempl set filetype=xml

autocmd BufRead,BufNewFile *.sas set filetype=sas


" generic stuff

set ts=4
set expandtab
set shiftwidth=4
set softtabstop=4

set textwidth=0
set wrapmargin=0
set formatoptions-=t
filetype plugin indent on
syntax on
cnoreabbrev Q q
autocmd BufEnter * :highlight cTodo term=NONE
