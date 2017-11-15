if exists('g:vimax_tmux_loaded') || &compatible
  finish
endif
let g:vimax_tmux_loaded = 1

""
" Tmux address format information for prompt
let g:vimax_tmux_address_format = "'sess:win.pane', 'win.pane' or 'pane'"

let g:vimax_tmux_version = get(g:, 'vimax_tmux_version', '2.3')

let g:vimax_all_modes = get(g:, 'vimax_all_modes', []) + ['tmux']

if has('nvim') && has('python3')
  ""
  " Neovim and python enabled for async execution
  let g:vimax_tmux_py_enabled = get(g:, 'vimax_tmux_py_enable', 1)
endif
