"TODO: ensure mode compat? as in 'in tmux?', 'has nvim?'
"TODO: type define opts

""
" Gets the last address from @setting(vimax_last_address)
"
" @public
function! vimax#get_last_address() abort
  return get(g:vimax_last_address, g:vimax_mode, v:null)
endfunction

""
" Sets global last address for mode on g:vimax_last_address[mode] to
" a formatted address
"
" @public
" {address} str already formatted and ready for consumption
function! vimax#set_last_address(address) abort
  let g:vimax_last_address[g:vimax_mode] = a:address
endfunction

function! vimax#set_last_command(address, command) abort
  call vimax#set_last_address(a:address)
  let g:vimax_last_command_dict[g:vimax_mode][a:address] = a:command
endfunction

function! vimax#get_last_command(address) abort
  let l:default = get(g:vimax_get_last_command_default, g:vimax_mode, "")
  return get(g:vimax_last_command_dict[g:vimax_mode], a:address, l:default)
endfunction

""
" Calls mode specific function of name and passes args along. {opts} has mode, save_address, name
" and repeat. [func_args] are passed on to get_address and the function itself
function! vimax#call_mode_function(opts, ...) abort
  "type: (opts: Opts, *Any) -> Any
  let l:func_args = a:000
  if has_key(a:opts, 'needs_address')
    let l:address = call('vimax#get_address', a:000)
    let l:func_args = [l:address] + l:func_args
    if empty(l:address)
      echo 'No address specified'
      return v:null
    endif
    if has_key(a:opts, 'save_address')
      call vimax#set_last_address(l:address)
    endif
  endif
  let l:should_py = get(g:, 'vimax_' . g:vimax_mode . '_py_enabled')
  if l:should_py
    let l:py_func = '_vimax_' . g:vimax_mode . '_' . a:opts.name
    let l:result = call(l:py_func, l:func_args)
    if a:opts.name !~# 'format_address'
      let l:result = v:null
    endif
  else
    let l:vim_func = 'vimax#' . g:vimax_mode . '#' . a:opts.name
    let l:result = call(l:vim_func, l:func_args)
  endif
  if has_key(a:opts, 'repeat')
    execute 'silent! call repeat#set("\<Plug>Vimax#' . a:opts.name . '")'
  endif
  if has_key(a:opts, 'save_address')
     \ && !has_key(a:opts, 'needs_address')
     \ && !l:should_py
    call vimax#set_last_address(l:result)
  endif
  return l:result
endfunction

""
" [retrieved_address] str
" [retrieved_count] int
function! vimax#get_address(...) abort
  "type: (mode: str, address: Optional[Union[str, int]], vcount: Optional[int] -> Union[str, int]
  "TODO: check address existence
  let l:retrieved_address = get(a:, '1', v:null)
  if get(a:, '2', v:null) is v:null
    let l:retrieved_count = exists('v:count') && v:count != 0 ? v:count : v:null
  else
    let l:retrieved_count = get(a:, '2')
  endif

  if !(l:retrieved_address is v:null)
    let l:params = [
      \ {'name': 'format_address_from_arg'},
      \ l:retrieved_address
      \ ]
    return call('vimax#call_mode_function', l:params)
  endif

  if !(l:retrieved_count is v:null)
    let l:params = [
      \ {'name': 'format_address_from_vcount'},
      \ l:retrieved_count
      \ ]
    return call('vimax#call_mode_function', l:params)
  endif

  let l:last_address = vimax#get_last_address()
  if !(l:last_address is v:null)
    return l:last_address
    "use l:last address as the default
  else
    let l:address_format = get(g:, 'vimax_' . g:vimax_mode . '_address_format', '')
    let l:prompt_end = !empty(l:address_format) ? ' ' . l:address_format : ''
    let l:prompt_string =  g:vimax_mode . ' address' . l:prompt_end . '> '
    "if no specified, count or l:last address, l:prompt for input
    return input(l:prompt_string)
  endif
endfunction

""
"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
"TODO: does ... here ever include 'retrieved_count'? Make explicit either way
function! vimax#run_command(command, ...) abort
  "type (command: str, address: Optional[str]) -> void
  let l:address = call('vimax#get_address', a:000)

  if empty(l:address)
    echo 'No address specified'
    return v:null
  endif
  if empty(a:command)
    echo 'No command specified'
    return v:null
  endif

  "save to global last command, last address and a dict of key=last address
  "execute let_prefix . 'command = ' . a:command 
  call vimax#set_last_command(l:address, a:command)

  call call('vimax#call_mode_function',
            \ [{'name': 'send_command'}, l:address, a:command,
            \ g:vimax_send_direct_text])
  silent! call repeat#set('\<Plug>Vimax#run_last_command')
endfunction

function! vimax#prompt_command() abort
  "ask for a command to run and execute it in pane from count, arg, last address, or prompt
  "args: mode, address, default
  let l:command = input(g:vimax_prompt_string)
  return vimax#run_command(l:command)
endfunction

"run last command from dict based on pane from count, arg, last address,
"or prompt. If no last command and buffer exists send, 'Up' and 'Enter'
function! vimax#run_last_command(...) abort
  "type (command: str, address: Optional[str]) -> void
  let l:address = call('vimax#get_address', a:000)
  let l:command = vimax#get_last_command(l:address)
  return vimax#run_command(l:command, l:address)
endfunction

function! vimax#close(...) abort
  "kill a specific address
  let l:opts = {
    \ 'name': 'close',
    \ 'needs_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#send_return(...) abort
  "kill a specific address
  let l:opts = {
    \ 'name': 'send_return',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#zoom(...) abort
  "travel to an address and zoom in
  let l:opts = {
    \ 'name': 'zoom',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

function! vimax#scroll_up(...) abort
  "travel to address, insert copy mode, page up, then return to vim
  let l:opts = {
    \ 'name': 'scroll_up',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"travel to address, insert copy mode, page down, then return to vim
"TODO: solve reliance on C-d as page-down
function! vimax#scroll_down(...) abort
  let l:opts = {
    \ 'name': 'scroll_down',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"send an interrupt sequence (control-c) to address
function! vimax#interrupt(...) abort
  let l:opts = {
    \ 'name': 'interrupt',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ 'repeat': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"clear an address's tmux history and clear the terminal
function! vimax#clear_history(...) abort
  let l:opts = {
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
function! vimax#go_to(...) abort
  let l:opts = {
    \ 'name': 'go_to',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"enter window and pane in copy mode
function! vimax#inspect(...) abort
  let l:opts = {
    \ 'name': 'inspect',
    \ 'needs_address': v:true,
    \ 'save_address': v:true,
    \ }
  return call('vimax#call_mode_function', [l:opts] + a:000)
endfunction

"open a new tmux split in current directory
"and run a command from prompt or from first arg
function! vimax#run_in_dir(...) abort
  let l:opts = {
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let l:path = shellescape(expand('%:p:h'), 1)
  let l:command = get(a:, '1', input(g:vimax_prompt_string))
  return call('vimax#call_mode_function', [l:opts, l:path, l:command] + a:000)
endfunction

function! vimax#run_at_git_root(...) abort
  let l:path = systemlist('git rev-parse --show-toplevel')[0]
  if v:shell_error
    return vimax#util#warn('Not in git repo')
  endif
  let l:opts = {
    \ 'name': 'run_in_dir',
    \ 'save_address': v:true,
    \ }
  let l:command = get(a:, '1', input(g:vimax_prompt_string))
  return call('vimax#call_mode_function', [l:opts, l:path, l:command] + a:000)
endfunction

function! vimax#list(...) abort
  "type: (header: Optional[str], sink: Optional[Callable]) -> Fzf
  "main address listing function.
  "Selects function for fuzzy listing
  "or just echoes the list
  let l:prefix = 'vimax#' . g:vimax_mode . '#'
  let l:source = call(l:prefix . 'list_source', a:000[2:])
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
      let l:Sink = function('vimax#fzf#default_list_sink')
    endif
    let l:opts = {
      \ 'source': l:source,
      \ 'sink': l:Sink,
      \ 'header': l:header,
      \ 'prompt': l:prompt,
      \ 'bindings': l:bindings
      \ }
    return vimax#fzf#run(l:opts)
  endif
endfunction

function! vimax#history(...) abort
  "type: (address: Optional[str], *Any) -> Fzf
  "Main history function.
  "Lists command line history for execution and gives keybingings for additional features
  let l:prefix = 'vimax#' . g:vimax_mode . '#'
  let l:has_mode_history_source = exists('*' . l:prefix . 'history_source')
  let l:source = l:has_mode_history_source
    \ ? call(l:prefix . 'history_source', a:000[1:])
    \ : call('vimax#fzf#default_history_source', a:000[1:])
  let l:header = 'History'
  let l:prompt = 'Hist'
  let l:bindings = join(values(g:vimax_history_bindings), ',')
  let l:address = call('vimax#get_address', a:000)

  if g:vimax_fuzzy_buffer is v:null
    echo "FZF is not loaded.\n
      \You'll have to call :VimaxRunCommand <command> yourself\n\n"
    echo l:source
  elseif g:vimax_fuzzy_buffer ==? 'fzf'
    if exists('*' . l:prefix . 'history_sink')
      let l:Sink = function(l:prefix . 'history_sink', [l:address])
    else
      let l:Sink = function('vimax#fzf#default_history_sink', [l:address])
    endif
    let l:opts = {
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
