"format colors for fzf
function! s:ansi(str, col, bold)
  return printf("\x1b[%s%sm%s\x1b[m", a:col, a:bold ? ';1' : '', a:str)
endfunction

"provide color functions like s:magenta
let s:colors = {
  \ 'black': 30,
  \ 'red': 31,
  \ 'green': 32,
  \ 'yellow': 33,
  \ 'blue': 34,
  \ 'magenta': 35,
  \ 'cyan': 36,
  \ }

for [s:c, s:a] in items()
  execute 'function! s:' . s:c . '(str, ...)\n'
        \ '  return s:ansi(a:str, ' . s:a . ', get(a:, 1, 0))\n'
        \ 'endfunction'
endfor

"format history header
function! vimax#fuzzy#history_header()
  let history_header = 'Vimax History'
  let display = vimax#fuzzy#get_binding(g:VimaxHistoryBindings['help'])[0]

  let colored = g:VimaxFuzzyBuffer == 'fzf'
    \ ? s:magenta(display)
    \ : display

  let history_header .= ' :: '.colored.
    \ ' - show key bindings'
  return history_header
endfunction
