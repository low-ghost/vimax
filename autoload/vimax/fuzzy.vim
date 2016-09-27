"format colors for fzf
function! s:ansi(str, col, bold)
  return printf("\x1b[%s%sm%s\x1b[m", a:col, a:bold ? ';1' : '', a:str)
endfunction

"provide color functions like s:magenta
for [s:c, s:a] in items({'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35, 'cyan': 36})
  execute "function! s:".s:c."(str, ...)\n"
    \ "  return s:ansi(a:str, ".s:a.", get(a:, 1, 0))\n"
    \ "endfunction"
endfor

"returns pair of bindings, [ fzf ]
function! vimax#fuzzy#get_binding(key)
  return [ 'ctrl-'.a:key ]
endfunction

"returns alt bindings, [ fzf ]
function! vimax#fuzzy#get_alt_binding(key)
  return [ 'alt-'.a:key ]
endfunction

let s:all_history_bindings = []
let s:all_list_bindings = []

for func in keys(g:VimaxHistoryBindings)
  let bind = g:VimaxHistoryBindings[func]
  call add(s:all_history_bindings, vimax#fuzzy#get_binding(bind)[0])
  if func == 'run_at_address' || func == 'edit'
    call add(s:all_history_bindings, vimax#fuzzy#get_alt_binding(bind)[0])
  endif
endfor

for func in keys(g:VimaxListBindings)
  let bind = g:VimaxListBindings[func]
  call add(s:all_list_bindings, vimax#fuzzy#get_binding(bind)[0])
endfor

function! vimax#fuzzy#get_all_bindings(group)
  return a:group == 'history' ? s:all_history_bindings : s:all_list_bindings
endfunction


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

function! vimax#fuzzy#get_history_lines()
  let lines = split(system('tail -'.g:VimaxLimitHistory.' '.g:VimaxHistoryFile), '\n')
  if g:VimaxHistoryFile =~ 'zsh'
    return map(lines, "substitute(v:val, ': \\d*:\\d;', '', '')")
  endif
  return lines
endfunction

function! vimax#fuzzy#help(binds, title)
  let header = a:title." Commands\n"
  for func in keys(a:binds)
    let display = vimax#fuzzy#get_binding(a:binds[func])[0]
    let header .= "\n".display.' - '.substitute(func, '_', ' ', 'g')
    if func == 'run_at_address' || func == 'edit'
      let display = vimax#fuzzy#get_alt_binding(a:binds[func])[0]
      let header .= "\n".display.
        \ ' - prompt for a different address and '.substitute(func, '_', ' ', 'g')
    endif
  endfor
  return header
endfunction
