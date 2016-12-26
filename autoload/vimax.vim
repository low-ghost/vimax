"TODO: ensure mode compat? as in 'in tmux?', 'has nvim?'
"TODO: type define opts

function! s:call_mode_function(opts, ...)
  "type: (opts: Opts, *Any) -> Any
  "calls mode specific function <name> and passes args
  let mode_final = type(a:opts.mode) != type(v:null) ? a:opts.mode : g:vimax#mode
  let func_args = a:000
  if has_key(a:opts, 'needs_address')
    let address = call("vimax#get_address", [mode_final] + a:000)
    let func_args = [address] + func_args
    if empty(address)
      echo 'No address specified'
      return v:null
    endif
    if has_key(a:opts, 'save_address')
      let g:vimax#last_address[mode_final] = address
    endif
  endif
  let result = call('vimax#' . mode_final . '#' . a:opts.name, func_args)
  if has_key(a:opts, 'repeat')
    execute 'silent! call repeat#set("\<Plug>Vimax#' . a:opts.name . '")'
  endif
  if has_key(a:opts, 'save_address') && !has_key(a:opts, 'needs_address')
    let g:vimax#last_address[mode_final] = result
  endif
  return result
endfunction

function! vimax#get_address(mode, ...)
  "type: (mode: str, address: Optional[Union[str, int]], vcount: Optional[int] -> Union[str, int]
  "TODO: check address existence
  let retrieved_address = get(a:, '1', v:null)
  let retrieved_count = get(a:, '2',
    \ exists('v:count') && v:count != 0 ? v:count : v:null)

  if !(retrieved_address is v:null)
    "TODO: this provides a way to add a default above
    return call('s:call_mode_function', [{'mode': a:mode, 'name': 'format_address_from_arg'},
                                         \ retrieved_address])
  endif

  if !(retrieved_count is v:null)
    return call('s:call_mode_function', [{'mode': a:mode, 'name': 'format_address_from_vcount'},
                                         \ retrieved_count])
  endif
  let last_address = get(g:vimax#last_address, a:mode, v:null)
  if !(last_address is v:null)
    return last_address
    "use last address as the default
  else
    let address_format = get(g:, 'vimax#' . a:mode . '#address_format', '')
    let prompt_end = !empty(address_format) ? ' ' . address_format : ''
    let prompt_string =  a:mode . ' address' . prompt_end . '> '
    "if no specified, count or last address, prompt for input
    return input(prompt_string)
  endif
endfunction

"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! vimax#run_command(mode, command, ...)
  let mode_final = type(a:mode) != type(v:null) ? a:mode : g:vimax#mode
  "type (command: str, address: Optional[str]) -> void
  let address = call("vimax#get_address", [mode_final] + a:000)

  if empty(address)
    echo 'No address specified'
    return v:null
  endif
  if empty(a:command)
    echo 'No command specified'
    return v:null
  endif

  "TODO: reinstate for 'prompt'?
  let send_direct_text = get(a:, '2')

  "save to global last command, last address and a dict of key=last address
  "execute let_prefix . 'command = ' . a:command 
  let g:vimax#last_address[mode_final] = address
  let g:vimax#last_command_dict[mode_final][address] = a:command

  if !send_direct_text
    call call("s:call_mode_function", [{'mode': mode_final, 'name': 'send_reset'}, address])
  endif
  call call("s:call_mode_function", [{'mode': mode_final, 'name': 'send_text'}, address, a:command])
  if !send_direct_text
    call call("s:call_mode_function", [{'mode': mode_final, 'name': 'send_return'}, address])
  endif
  silent! call repeat#set('\<Plug>Vimax#run_last_command')
endfunction

function! vimax#prompt_command(mode, ...)
  "ask for a command to run and execute it in pane from count, arg, last address, or prompt
  "args: mode, address, default
  let command = input(g:VimaxPromptString)
  return vimax#run_command(a:mode, command)
endfunction

"run last command from dict based on pane from count, arg, last address,
"or prompt. If no last command and buffer exists send, 'Up' and 'Enter'
function! vimax#run_last_command(mode, ...)
  let mode_final = type(a:mode) != type(v:null) ? a:mode : g:vimax#mode
  "type (command: str, address: Optional[str]) -> void
  let address = call("vimax#get_address", [mode_final] + a:000)
  let command = get(g:vimax#last_command_dict[mode_final], address, 'Up')
  return vimax#run_command(mode_final, command, address)
endfunction

function! vimax#close(mode, ...)
  "kill a specific address
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'close',
    \ 'needs_address': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

function! vimax#zoom(mode, ...)
  "travel to an address and zoom in
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'zoom',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

function! vimax#scroll_up(mode, ...)
  "travel to address, insert copy mode, page up, then return to vim
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'scroll_up',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"travel to address, insert copy mode, page down, then return to vim
"TODO: solve reliance on C-d as page-down
function! vimax#scroll_down(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'scroll_down',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"send an interrupt sequence (control-c) to address
function! vimax#interrupt(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'interrupt',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"clear an address's tmux history and clear the terminal
function! vimax#clear_history(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'clear_history',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"send escaped text by calling VimaxSendKeys. Needs text and pane explicitly
"TODO
"function! vimax#SendLines(text, address)
  "let split_text = split(a:text, "\n")
  "for i in split_text
    "let escaped = vimax#util#escape(shellescape(i))
    "call vimax#SendKeys(escaped, a:address)
    "call vimax#SendKeys('Enter', a:address)
  "endfor
"endfunction

"travel to an address and persist it as the last-used
function! vimax#go_to(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'go_to',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"enter window and pane in copy mode
function! vimax#inspect(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'inspect',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call("s:call_mode_function", [opts] + a:000)
endfunction

"open a new tmux split in current directory
"and run a command from prompt or from first arg
function! vimax#run_in_dir(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let path = shellescape(expand('%:p:h'), 1)
  let command = get(a:, '1', input(g:VimaxPromptString))
  return call("s:call_mode_function", [opts, path, command] + a:000)
endfunction

function! vimax#run_at_git_root(mode, ...)
  let opts = {
    \ 'mode': a:mode,
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let path = systemlist('git rev-parse --show-toplevel')[0]
  if v:shell_error
    return s:warn('Not in git repo')
  endif
  let command = get(a:, '1', input(g:VimaxPromptString))
  return call("s:call_mode_function", [opts, path, command] + a:000)
endfunction

function! Echo(...)
  echo a:000
endfunction

function! vimax#list(mode, ...)
  "type: (mode: str, header: Optional[str], sink: Optional[Callable]) -> Fzf
  "main address listing function.
  "Selects function for fuzzy listing
  "or just echoes the list
  let mode_final = type(a:mode) != type(v:null) ? a:mode : g:vimax#mode
  let prefix = 'vimax#' . mode_final . '#'
  let source = call(prefix . 'list_source', a:000)
  let header = get(a:, '1', 'Address List')
  let prompt = 'Address'
  let bindings = join(values(vimax#fzf#generate_binds(mode_final, 'list')), ',')

  if g:VimaxFuzzyBuffer == v:null
    "TODO: inputlist and only 'select' option on enter
    echo lines
  elseif g:VimaxFuzzyBuffer == 'fzf'
    let sink = get(a:, '2', prefix . 'list_sink')
    let opts = {
      \ 'mode': mode_final,
      \ 'source': source,
      \ 'sink': sink,
      \ 'header': header,
      \ 'prompt': prompt,
      \ 'bindings': bindings }
    return vimax#fzf#run(opts)
  endif

endfunction

function! vimax#History(...)
  "type: (address: Optional[str]) -> Fzf
  "Main history function.
  "Lists command line history for execution and gives keybingings for additional features
  let address = vimax#util#get_address(a:000)
  let lines = vimax#fuzzy#get_history_lines()

  if g:VimaxFuzzyBuffer == g:vimax#none
    let g:VimaxLastAddress = address
    echo "FZF is not loaded.\n
      \You'll have to call :VimaxRunCommand <command> yourself\n\n"
    echo lines
    return 1
  elseif g:VimaxFuzzyBuffer == 'fzf'
    return vimax#fzf#history(address, lines)
  endif
endfunction

function! vimax#switch_mode()
  "type: () -> void
  "Switch the primary mode of vimax via incrementing
  let current_index = index(g:vimax#all_modes, g:vimax#mode)
  let next_index = current_index + 1 == len(g:vimax#all_modes) ? 0 : current_index + 1
  let g:vimax#mode = g:vimax#all_modes[next_index]
  echo g:vimax#mode
endfunction
