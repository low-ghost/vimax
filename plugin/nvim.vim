if exists('g:vimax_nvim_tmux_loaded') || &compatible
  finish
endif
let g:vimax_nvim_tmux_loaded = 1

""
" Dictionary of nvim buffers {[buffer_id: number]: number}, or buffer id to
" job id
let g:vimax_nvim_buffers = {}

""
" Nvim scroll up sequence
let g:vimax_nvim_scroll_up_sequence = "\<C-u>"

""
" Nvim scroll down sequence
let g:vimax_nvim_scroll_down_sequence = "\<C-d>"

let g:vimax_all_modes = get(g:, 'vimax_all_modes', []) + ['nvim']

""
" Adds to and removes from g:vimax#nvim#buffers on any terminal open or close
augroup vimax#nvim
  au!
  au TermOpen * call vimax#nvim#au#add_to_buffer_list()
  au TermClose * call vimax#nvim#au#remove_from_buffer_list()
augroup END

