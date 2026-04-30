call plug#begin()

" -- plugins
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

call plug#end()

" -- lsp enable
let g:lsp_auto_enable = 1
set omnifunc=lsp#complete


" haskell lsp
if executable('haskell-language-server-wrapper')
  augroup lsp_haskell
    autocmd!
    autocmd FileType haskell call lsp#register_server({
          \ 'name': 'haskell-language-server',
          \ 'cmd': {server_info->['haskell-language-server-wrapper', '--lsp']},
          \ 'allowlist': ['haskell'],
          \ })
  augroup END
endif

" -- keymaps
nnoremap gd <plug>(lsp-definition)
nnoremap K  <plug>(lsp-hover)
nnoremap gr <plug>(lsp-references)

" -- why isnt this defualt
colorscheme default
