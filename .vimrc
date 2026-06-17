:set ts=4
:syn on

" copilot
call plug#begin('~/.vim/plugged')
Plug 'github/copilot.vim'                " base Copilot
Plug 'DanBradbury/copilot-chat.vim'      " chat plugin (pure Vimscript)
call plug#end()

filetype plugin indent on

" optional keymaps
nnoremap <leader>cc :CopilotChatOpen<CR>
vmap <leader>a <Plug>CopilotChatAddSelection>


