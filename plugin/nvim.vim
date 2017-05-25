if exists('g:vimax_nvim_loaded') || &compatible
  finish
endif
let g:vimax_nvim_loaded = 1

""
" Dictionary of nvim buffers {
"   buffer: {[buffer_id: number]: number},
"   job: {[job_id]: number]: number},
" }
let g:vimax_nvim_buffers = { 'buffer': {}, 'job': {} }

""
" Nvim scroll up sequence
let g:vimax_nvim_scroll_up_sequence = "\<C-u>"

""
" Nvim scroll down sequence
let g:vimax_nvim_scroll_down_sequence = "\<C-d>"

let g:vimax_all_modes = get(g:, 'vimax_all_modes', []) + ['nvim']
let g:vimax_nvim_get_last_command_default = get(g:, 'vimax_nvim_get_last_command_default', "!!\t")
let g:vimax_get_last_command_default = extend(get(g:, 'vimax_get_last_command_default', {}),
  \ { 'nvim': g:vimax_nvim_get_last_command_default })

""
" Adds to and removes from g:vimax#nvim#buffers on any terminal open or close
augroup vimax#nvim
  au!
  au TermOpen * call vimax#nvim#au#add_to_buffer_list()
  au TermClose * call vimax#nvim#au#remove_from_buffer_list()
augroup END

