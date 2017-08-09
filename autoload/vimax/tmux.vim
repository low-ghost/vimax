function! vimax#tmux#format_address_from_vcount(count) abort
  "type: (count_arg: int) -> str
  "join a two or three digit count with a dot so that 10 refers to 1.0 or window 1,
  "pane 0. could also give 3 numbers to indicate session, window, pane
  let l:split_count = split(string(a:count), '\zs')
  if len(l:split_count) < 3
    return join(l:split_count, '.')
  endif
  let [l:session; l:rest] = l:split_count
  return l:session . ':' . join(l:rest, '.')
endfunction

function! vimax#tmux#format_address_from_arg(address_arg) abort
  "type: (address_arg: Union[int, str]) -> str
  return type(a:address_arg) == type('')
    \ ? a:address_arg
    \ : string(a:address_arg)
endfunction

function! vimax#tmux#format_address_from_fzf_item(item) abort
  let [ l:_, l:session, l:window, l:pane; l:rest ] =
    \ matchlist(a:item, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
  return l:session . ':' . l:window . '.' . l:pane
endfunction

function! vimax#tmux#send_keys(address, keys, ...) abort
  "type: (address: Address, keys: str, ) 
  "send specific keys to a tmux pane
  "TODO: string coercion still necessary?
  let l:address = type(a:address) == type('') ? a:address : string(a:address)
  let l:tmux_command = 'send-keys -t ' . l:address . ' '
  let l:initial  = 'tmux ' . l:tmux_command . a:keys
  let l:single_or_multi_send_key = a:0 == 0
    \ ? l:initial
    \ : join([l:initial] + a:000, '\; ' . l:tmux_command)
  call system(l:single_or_multi_send_key)
endfunction

function! vimax#tmux#send_text(address, text) abort
  "send escaped text by calling VimaxSendKeys. Needs text and pane explicitly
  let l:escaped = vimax#util#escape(shellescape(a:text))
  call vimax#tmux#send_keys(a:address, l:escaped)
endfunction

function! vimax#tmux#send_return(address, ...) abort
  "send the return key to pane
  call vimax#tmux#send_keys(a:address, 'Enter')
endfunction

function! vimax#tmux#send_reset(address, ...) abort
  "send reset to pane
  "call vimax#tmux#send_keys(a:address, '-X cancel')
  call vimax#tmux#send_keys(a:address, 'C-c')
endfunction

function! vimax#tmux#send_command(address, command, send_direct_text) abort
  if !a:send_direct_text
    call vimax#tmux#send_reset(a:address)
  endif
  call vimax#tmux#send_text(a:address, a:command)
  if !a:send_direct_text
    call vimax#tmux#send_return(a:address)
  endif
endfunction

function! vimax#tmux#close(address, ...) abort
  "type: (address: str) -> void
  call system('tmux kill-pane -t ' . a:address)
endfunction

function! vimax#tmux#zoom(address, ...) abort
  "type: (address: str) -> void
  call vimax#tmux#go_to_address_additional(a:address, 'resize-pane -Z -t' . a:address)
endfunction

function! vimax#tmux#scroll_up(address, ...) abort
  "type: (address: str) -> void
  "TODO: goes too far?
  call system('tmux copy-mode -u -t ' . a:address)
endfunction

function! vimax#tmux#scroll_down(address, ...) abort
  "type: (address: str) -> void
  "Possibly this is a pre tmux 2.1 solution
  "call system('tmux copy-mode -t ' . a:address . '\; send-keys -t ' . a:address . ' C-d')
  call system('tmux copy-mode -t ' . a:address . '\; send-keys -t ' . a:address
              \ . ' -X -N 5 scroll-down')
endfunction

function! vimax#tmux#run_in_dir(path, command, ...) abort
  "open a tmux split in specified path, send a <command> and get the new
  "address via display-message so it can be set to g:vimax_last_address
  let l:is_command = strlen(a:command) > 0
  "Todo: should be escaped text
  let l:send_instructions = l:is_command ? '\; send-keys "' . a:command . "\" 'Enter'" : ''
  let l:opposite_orient_for_tmux = g:vimax_orientation ==? 'h' ? 'v' : 'h'
  let l:address = substitute(system(
    \ 'tmux split-window -' . l:opposite_orient_for_tmux . ' -l ' . g:vimax_size . ' -c ' . a:path
    \ . l:send_instructions
    \ . '\; display-message -p ' . "'#S:#I.#P'"
    \ ), "\n", '', '')
  " Only go back to vim if a command is actually run, otherwise the assumption
  " is the user wants to land in the new target to execute commands
  if l:is_command
    call system('tmux last-pane')
  endif
  return l:address
endfunction

function! vimax#tmux#go_to_address_additional(address, ...) abort
  "travel to an address and persist it as the last-used
  let l:additional = get(a:, '1', '')

  "set vim and tmux VimaxLastVimAddress variables
  let g:vimax_last_vim_address = system("tmux display-message -p '#S:#I.#P'")
  call system('touch ~/.vimaxenv && echo "' . g:vimax_last_vim_address . '" > ~/.vimaxenv')
  let l:address_parts = split(a:address, '\:\|\.')
  let l:len_address = len(l:address_parts)
  let l:additional_with_end = !empty(l:additional) ? l:additional . '\; ' : ''

  if l:len_address == 3
    "Go to a different session
    call system(
      \ 'tmux select-window -t ' . a:address . '\; '
      \ . 'select-pane -t ' . a:address . '\; '
      \ . l:additional_with_end
      \ . 'switch-client -t ' . l:address_parts[0]
      \ )
  elseif l:len_address == 2
    "Go to a different window
    call system(
      \ 'tmux select-window -t ' . a:address . '\; '
      \ . 'select-pane -t ' . a:address . '\; '
      \ . l:additional
      \ )
  else
    "Go to a different pane
    call system('tmux select-pane -t ' . a:address . '\; ' . l:additional)
  endif
endfunction

function! vimax#tmux#go_to(address, ...) abort
  call vimax#tmux#go_to_address_additional(a:address)
endfunction

function! vimax#tmux#inspect(address, ...) abort
  "type: (address: Address): void
  "enter window and pane in copy mode
  call vimax#tmux#go_to_address_additional(a:address, 'copy-mode')
endfunction

function! vimax#tmux#interrupt(address, ...) abort
  "type: (address: Address): void
  "send standard console interrupt and tmux interrupt in that order so that
  "interrupt also works as 'exit inspect mode' in various tmux versions
  call vimax#tmux#send_keys(a:address, '^C')
  "Might be needed for tmux > 2.3
  "...'^C', '-X cancel')
endfunction

function! vimax#tmux#clear_history(address, ...) abort
  "type: (address: Address): void
  "clear tmux history and call 'clear' in term
  call system('tmux clear-history -t ' . a:address)
  call vimax#tmux#send_text(a:address, 'clear')
  call vimax#tmux#send_return(a:address)
endfunction

"TODO: run in dir and run at root accept numerical targets. If target exists,
"split it in whichever orientation gives it more screen space

function! vimax#tmux#split_target(orientation, ...) abort
  "(orientation: Union['h', 'v'], address: Optional[Union[str, int]]) -> void
  let l:address = call('vimax#get_address', ['tmux'] + a:000)
  let l:opposite_orient_for_tmux = a:orientation ==? 'h' ? '-v' : '-h'
  call system('tmux split-window ' . l:opposite_orient_for_tmux . ' -t ' . l:address)
endfunction

function! vimax#tmux#list_source(...) abort
  "type: (*Any) -> List[str]
  return reverse(split(system(
    \ 'tmux lsp'.
    \ ' -a -F'.
    \ ' "#S:#{=10:window_name}-#I:#P'.
    \ ' #{pane_current_command}'.
    \ ' #{?pane_active,(active),}"'
    \ ), '\n'))
endfunction
