"TODO: ensure mode compat? as in 'in tmux?', 'has nvim?'
"TODO: type define opts

""
" Gets the last address from @setting(vimax_last_address) for the given
" mode
"
" @public
" {mode} str property of @setting(vimax_mode)
function! vimax#get_last_address(mode) abort
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  return get(g:vimax_last_address, l:mode_final, v:null)
endfunction

""
" Sets global last address for mode on g:vimax_last_address[mode] to
" a formatted address
"
" @public
" {mode} str from @setting(g:vimax_all_modes)
" {address} str already formatted and ready for consumption
function! vimax#set_last_address(mode, address) abort
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  let g:vimax_last_address[l:mode_final] = a:address
endfunction

function! vimax#set_last_command(mode, address, command) abort
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  call vimax#set_last_address(l:mode_final, a:address)
  let g:vimax_last_command_dict[l:mode_final][a:address] = a:command
endfunction

function! vimax#get_last_command(mode, address, default) abort
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  return get(g:vimax_last_command_dict[l:mode_final], a:address, a:default)
endfunction

""
" Calls mode specific function of name and passes args along. {opts} has mode, save_address, name
" and repeat. [func_args] are passed on to get_address and the function itself
function! vimax#call_mode_function(opts, ...) abort
  "type: (opts: Opts, *Any) -> Any
  let l:mode_final = !(a:opts.mode is v:null) ? a:opts.mode : g:vimax_mode
  let l:func_args = a:000
  if has_key(a:opts, 'needs_address')
    let l:address = call('vimax#get_address', [l:mode_final] + a:000)
    let l:func_args = [l:address] + l:func_args
    if empty(l:address)
      echo 'No address specified'
      return v:null
    endif
    if has_key(a:opts, 'save_address')
      call vimax#set_last_address(l:mode_final, l:address)
    endif
  endif
  let l:should_py = get(g:, 'vimax_' . l:mode_final . '_py_enabled')
  if l:should_py
    let l:py_func = '_vimax_' . l:mode_final . '_' . a:opts.name
    let l:result = call(l:py_func, l:func_args)
    if a:opts.name !~# 'format_address'
      let l:result = v:null
    endif
  else
    let l:vim_func = 'vimax#' . l:mode_final . '#' . a:opts.name
    let l:result = call(l:vim_func, l:func_args)
  endif
  if has_key(a:opts, 'repeat')
    execute 'silent! call repeat#set("\<Plug>Vimax#' . a:opts.name . '")'
  endif
  if has_key(a:opts, 'save_address')
     \ && !has_key(a:opts, 'needs_address')
     \ && !l:should_py
    call vimax#set_last_address(l:mode_final, l:result)
  endif
  return l:result
endfunction

""
" {mode} str
" [retrieved_address] str
function! vimax#get_address(mode, ...) abort
  "type: (mode: str, address: Optional[Union[str, int]], vcount: Optional[int] -> Union[str, int]
  "TODO: check address existence
  let l:retrieved_address = get(a:, '1', v:null)
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  if get(a:, '2', v:null) is v:null
    let l:retrieved_count = exists('v:count') && v:count != 0 ? v:count : v:null
  else
    let l:retrieved_count = get(a:, '2')
  endif

  if !(l:retrieved_address is v:null)
    let l:params = [
      \ {'mode': l:mode_final, 'name': 'format_address_from_arg'},
      \ l:retrieved_address
      \ ]
    return call('vimax#call_mode_function', l:params)
  endif

  if !(l:retrieved_count is v:null)
    let l:params = [
      \ {'mode': l:mode_final, 'name': 'format_address_from_vcount'},
      \ l:retrieved_count
      \ ]
    return call('vimax#call_mode_function', l:params)
  endif

  let l:last_address = vimax#get_last_address(l:mode_final)
  if !(l:last_address is v:null)
    return l:last_address
    "use l:last address as the default
  else
    let l:address_format = get(g:, 'vimax_' . l:mode_final . '_address_format', '')
    let l:prompt_end = !empty(l:address_format) ? ' ' . l:address_format : ''
    let l:prompt_string =  l:mode_final . ' address' . l:prompt_end . '> '
    "if no specified, count or l:last address, l:prompt for input
    return input(l:prompt_string)
  endif
endfunction

""
"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! vimax#run_command(mode, command, ...) abort
  "type (mode: str, command: str, address: Optional[str]) -> void
  let l:address = call('vimax#get_address', [a:mode] + a:000)

  if empty(l:address)
    echo 'No address specified'
    return v:null
  endif
  if empty(a:command)
    echo 'No command specified'
    return v:null
  endif

  "TODO: reinstate for 'prompt'?
  let l:send_direct_text = get(a:, '2')

  "save to global last command, last address and a dict of key=last address
  "execute let_prefix . 'command = ' . a:command 
  call vimax#set_last_command(a:mode, l:address, a:command)

  call call('vimax#call_mode_function',
            \ [{'mode': a:mode, 'name': 'send_command'}, l:address, a:command,
            \ l:send_direct_text])
  silent! call repeat#set('\<Plug>Vimax#run_last_command')
endfunction

function! vimax#prompt_command(mode, ...) abort
  "ask for a command to run and execute it in pane from count, arg, last address, or prompt
  "args: mode, address, default
  let l:command = input(g:vimax_prompt_string)
  return vimax#run_command(a:mode, l:command)
endfunction

"run last command from dict based on pane from count, arg, last address,
"or prompt. If no last command and buffer exists send, 'Up' and 'Enter'
function! vimax#run_last_command(mode, ...) abort
  "type (command: str, address: Optional[str]) -> void
  let l:address = call('vimax#get_address', [a:mode] + a:000)
  let l:command = vimax#get_last_command(a:mode, l:address, 'Up')
  return vimax#run_command(a:mode, l:command, l:address)
endfunction

function! vimax#close(mode, ...) abort
  "kill a specific address
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'close',
    \ 'needs_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#send_return(mode, ...) abort
  "kill a specific address
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'send_return',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#zoom(mode, ...) abort
  "travel to an address and zoom in
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'zoom',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#scroll_up(mode, ...) abort
  "travel to address, insert copy mode, page up, then return to vim
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'scroll_up',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"travel to address, insert copy mode, page down, then return to vim
"TODO: solve reliance on C-d as page-down
function! vimax#scroll_down(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'scroll_down',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"send an interrupt sequence (control-c) to address
function! vimax#interrupt(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'interrupt',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"clear an address's tmux history and clear the terminal
function! vimax#clear_history(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'clear_history',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
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
function! vimax#go_to(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'go_to',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"enter window and pane in copy mode
function! vimax#inspect(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'inspect',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"open a new tmux split in current directory
"and run a command from prompt or from first arg
function! vimax#run_in_dir(mode, ...) abort
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let l:path = shellescape(expand('%:p:h'), 1)
  let l:command = get(a:, '1', input(g:vimax_prompt_string))
  return call('vimax#call_mode_function', [l:opts, l:path, l:command] + a:000)
endfunction

function! vimax#run_at_git_root(mode, ...) abort
  let l:path = systemlist('git rev-parse --show-toplevel')[0]
  if v:shell_error
    return vimax#util#warn('Not in git repo')
  endif
  let l:opts = {
    \ 'mode': a:mode,
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let l:command = get(a:, '1', input(g:vimax_prompt_string))
  return call('vimax#call_mode_function', [l:opts, l:path, l:command] + a:000)
endfunction

function! vimax#list(mode, ...) abort
  "type: (mode: str, header: Optional[str], sink: Optional[Callable]) -> Fzf
  "main address listing function.
  "Selects function for fuzzy listing
  "or just echoes the list
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  let l:prefix = 'vimax#' . l:mode_final . '#'
  let l:source = call(l:prefix . 'list_source', a:000[3:])
  let l:header = get(a:, '1', 'Address List')
  let l:prompt = 'Address'
  let l:bindings = join(values(g:vimax_list_bindings), ',')

  if g:vimax_fuzzy_buffer is v:null
    "TODO: inputlist and only 'select' option on enter
    echo l:source
  elseif g:vimax_fuzzy_buffer ==? 'fzf'
    if a:0 > 1
      let l:Sink = a:2
    elseif exists('*' . l:prefix . 'list_sink')
      let l:Sink = function(l:prefix . 'list_sink')
    else
      let l:Sink = function('vimax#fzf#default_list_sink', [l:mode_final])
    endif
    let l:opts = {
      \ 'mode': l:mode_final,
      \ 'source': l:source,
      \ 'sink': l:Sink,
      \ 'header': l:header,
      \ 'prompt': l:prompt,
      \ 'bindings': l:bindings
      \ }
    return vimax#fzf#run(l:opts)
  endif

endfunction

function! vimax#history(mode, ...) abort
  "type: (mode: str, address: Optional[str], *Any) -> Fzf
  "Main history function.
  "Lists command line history for execution and gives keybingings for additional features
  let l:mode_final = !(a:mode is v:null) ? a:mode : g:vimax_mode
  let l:prefix = 'vimax#' . l:mode_final . '#'
  let l:has_mode_history_source = exists('*' . l:prefix . 'history_source')
  let l:source = l:has_mode_history_source
    \ ? call(l:prefix . 'history_source', a:000[1:])
    \ : call('vimax#fzf#default_history_source', [l:mode_final] + a:000[1:])
  let l:header = 'History'
  let l:prompt = 'Hist'
  let l:bindings = join(values(g:vimax_history_bindings), ',')
  let l:address = call('vimax#get_address', [l:mode_final] + a:000)

  if g:vimax_fuzzy_buffer is v:null
    echo "FZF is not loaded.\n
      \You'll have to call :VimaxRunCommand <command> yourself\n\n"
    echo l:source
  elseif g:vimax_fuzzy_buffer ==? 'fzf'
    if exists('*' . l:prefix . 'history_sink')
      let l:Sink = function(l:prefix . 'history_sink', [l:address])
    else
      let l:Sink = function('vimax#fzf#default_history_sink',
                            \ [l:mode_final, l:address])
    endif
    let l:opts = {
      \ 'mode': l:mode_final,
      \ 'source': l:source,
      \ 'sink': l:Sink,
      \ 'header': l:header,
      \ 'prompt': l:prompt,
      \ 'bindings': l:bindings
      \ }
    return vimax#fzf#run(l:opts)
  endif
endfunction

function! vimax#alternate_mode() abort
  "type: () -> void
  "Switch the primary mode of vimax via incrementing
  let l:current_index = index(g:vimax_all_modes, g:vimax_mode)
  let l:next_index = l:current_index + 1 == len(g:vimax_all_modes)
    \ ? 0
    \ : l:current_index + 1
  let g:vimax_mode = g:vimax_all_modes[l:next_index]
  echo g:vimax_mode
endfunction
