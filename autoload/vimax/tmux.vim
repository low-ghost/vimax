function! vimax#tmux#format_address_from_vcount(count_arg)
  "type: (count_arg: int) -> str
  "join a two or three digit count with a dot so that 10 refers to 1.0 or window 1,
  "pane 0. could also give 3 numbers to indicate session, window, pane
  let split_count = split(string(a:count_arg), '\zs')
  if len(split_count) < 3
    return join(split_count, '.')
  endif
  let [session; rest] = split_count
  return session . ':' . join(rest, '.')
endfunction

function! vimax#tmux#format_address_from_arg(address_arg)
  "type: (address_arg: Union[int, str]) -> str
  return type(a:address_arg) == type('')
    \ ? a:address_arg
    \ : string(a:address_arg)
endfunction

function! vimax#tmux#send_keys(address, keys, ...)
  "type: (address: Address, keys: str, ) 
  "send specific keys to a tmux pane
  "TODO: string coercion still necessary?
  let address = type(a:address) == type("") ? a:address : string(a:address)
  let tmux_command = 'send-keys -t ' . address . ' '
  let initial  = 'tmux ' . tmux_command . a:keys
  let single_or_multi_send_key = a:0 == 0 ? initial : join([initial] + a:000, '\; ' . tmux_command)
  call system(single_or_multi_send_key)
endfunction

function! vimax#tmux#send_text(address, text)
  "send escaped text by calling VimaxSendKeys. Needs text and pane explicitly
  let escaped = vimax#util#escape(shellescape(a:text))
  call vimax#tmux#send_keys(a:address, escaped)
endfunction

function! vimax#tmux#send_return(address)
  "send the return key to pain
  call vimax#tmux#send_keys(a:address, 'Enter')
endfunction

function! vimax#tmux#send_reset(address)
  "send the return key to pain
  call vimax#tmux#send_keys(a:address, '-X cancel')
endfunction

function! vimax#tmux#close(address)
  "type: (address: str) -> void
  call system('tmux kill-pane -t ' . a:address)
endfunction

function! vimax#tmux#zoom(address)
  "type: (address: str) -> void
  call vimax#tmux#go_to_address_additional(a:address, 'resize-pane -Z -t' . a:address)
endfunction

function! vimax#tmux#scroll_up(address)
  "type: (address: str) -> void
  "TODO: goes too far?
  call system('tmux copy-mode -u -t ' . a:address)
endfunction

function! vimax#tmux#scroll_down(address)
  "type: (address: str) -> void
  "Possibly this is a pre tmux 2.1 solution
  "call system('tmux copy-mode -t ' . a:address . '\; send-keys -t ' . a:address . ' C-d')
  call system('tmux copy-mode -t ' . a:address . '\; send-keys -t ' . a:address
              \ . ' -X -N 5 scroll-down')
endfunction

function! vimax#tmux#run_in_dir(path, command)
  "open a tmux split in specified path, send a <command> and get the new
  "address via display-message so it can be set to g:VimaxLastAddress
  let is_command = strlen(a:command) > 0
  let send_instructions = is_command ? '\; send-keys "' . a:command . "\" 'Enter'" : ''
  let opposite_orient_for_tmux = g:VimaxOrientation == 'h' ? 'v' : 'h'
  let address = substitute(system(
    \ 'tmux split-window -' . opposite_orient_for_tmux . ' -l ' . g:VimaxSize . ' -c ' . a:path
    \ . send_instructions
    \ . '\; display-message -p ' . "'#S:#I.#P'"
    \ ), "\n", '', '')
  " Only go back to vim if a command is actually run, otherwise the assumption
  " is the user wants to land in the new target to execute commands
  if is_command
    call system('tmux last-pane')
  endif
  return address
endfunction

function! vimax#tmux#go_to_address_additional(address, ...)
  "travel to an address and persist it as the last-used
  let additional = get(a:, '1', '')

  "set vim and tmux VimaxLastVimAddress variables
  let g:VimaxLastVimAddress = system("tmux display-message -p '#S:#I.#P'")
  call system('touch ~/.vimaxenv && echo "' . g:VimaxLastVimAddress . '" > ~/.vimaxenv')
  let address_parts = split(a:address, '\:\|\.')
  let len_address = len(address_parts)
  let additional_with_end = !empty(additional) ? additional . '\; ' : ''

  if len_address == 3
    "Go to a different session
    call system(
      \ 'tmux select-window -t ' . a:address . '\; '
      \ . 'select-pane -t ' . a:address . '\; '
      \ . additional_with_end
      \ . 'switch-client -t ' . address_parts[0]
      \ )
  elseif len_address == 2
    "Go to a different window
    call system(
      \ 'tmux select-window -t ' . a:address . '\; '
      \ . 'select-pane -t ' . a:address . '\; '
      \ . additional
      \ )
  else
    "Go to a different pane
    call system('tmux select-pane -t ' . a:address . '\; ' . additional)
  endif
endfunction

function! vimax#tmux#go_to(address)
  call vimax#tmux#go_to_address_additional(a:address)
endfunction

function! vimax#tmux#inspect(address)
  "type: (address: Address): void
  "enter window and pane in copy mode
  call vimax#tmux#go_to_address_additional(a:address, 'copy-mode')
endfunction

function! vimax#tmux#interrupt(address)
  "type: (address: Address): void
  "send standard console interrupt and tmux interrupt in that order so that
  "interrupt also works as 'exit inspect mode' in various tmux versions
  call vimax#tmux#send_keys(a:address, '^C', '-X cancel')
endfunction

function! vimax#tmux#clear_history(address)
  "type: (address: Address): void
  "clear tmux history and call 'clear' in term
  call system('tmux clear-history -t ' . a:address)
  call vimax#tmux#send_text(a:address, 'clear')
  call vimax#tmux#send_return(a:address)
endfunction

"TODO: run in dir and run at root accept numerical targets. If target exists,
"split it in whichever orientation gives it more screen space

function! vimax#tmux#split_target(orientation, ...)
  "(orientation: Union['h', 'v'], address: Optional[Union[str, int]]) -> void
  let address = call("vimax#get_address", ['tmux'] + a:000)
  let opposite_orient_for_tmux = a:orientation == 'h' ? '-v' : '-h'
  call system('tmux split-window ' . opposite_orient_for_tmux . ' -t ' . address)
endfunction

function! s:get_address_from_fzf_item(item)
  let [ _, session, window, pane; rest ] =
    \ matchlist(a:item, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
  return session.':'.window.'.'.pane
endfunction

function! vimax#tmux#list_source(...)
  "type: (*Any) -> List[str]
  return reverse(split(system(
    \ 'tmux lsp'.
    \ ' -a -F'.
    \ ' "#S:#{=10:window_name}-#I:#P'.
    \ ' #{pane_current_command}'.
    \ ' #{?pane_active,(active),}"'
    \ ), '\n'))
endfunction

function! s:list_switch(binds, key, picked)
  let switch = {
    binds.help: 'help'
    binds.go_to: "vimax#go_to",
    binds.zoom: "vimax#zoom",
    binds.inspect: "vimax#inspect",
    binds.close: "vimax#close",
    binds.prompt: "vimax#prompt_command",
    binds.last: "vimax#run_last_command",
  }
  return get(switch, key, v:null)
endfunction

function! vimax#tmux#list_sink(selections)
  "type: (selections: List[str])
  if !len(a:selections)
    return v:null
  endif

  let binds = vimax#fzf#generate_binds('tmux', 'list')
  let [ key, item; rest ] = a:selections
  let picked = s:get_address_from_fzf_item(item)
  let func = s:list_switch(binds, key, picked)
  if func is v:null
    let g:vimax#tmux#last_address = picked
  elseif func == 'help' 
    call input(vimax#fuzzy#help(binds, 'List') . "\n\nPress Enter to continue")
    "restart list if was help command
    "TODO: check functionality when coming from history and hitting help for list
    "might need more args
    call vimax#list('tmux')
    call vimax#util#nvim_insert_fix()
  else
    return call(func, ['tmux', picked])
  endif
endfunction
