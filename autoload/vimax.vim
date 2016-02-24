"TODO: check address existence
"uses 'none' string b/c of high possibility of 0 address
function! s:GetAddress(specified_address)

  let prompt_string = "Enter tmux address as [[session:]window.]pane, such as 9 or vim.9 or 0:vim.9\n"
  if a:specified_address == 'prompt'
    return input(prompt_string)
  elseif a:specified_address != 'none'
    "directly pass address as the second argument
    return
      \ type(a:specified_address) == 1
      \ ? a:specified_address
      \ : string(a:specified_address)
  elseif exists('v:count') && v:count != 0
    "join a two or three digit count with a dot so that 10 refers to 1.0 or window 1,
    "pane 0. could also give 3 numbers to indicate session, window, pane
    let split_count = split(string(v:count), '\zs')
    let length_split = len(split_count)
    if length_split < 3
      return join(split_count, '.')
    else
      let [ session; rest ] = split_count
      return session.':'.join(rest, '.')
    endif
  elseif exists('g:VimaxLastAddress')
    "use last address as the default
    return g:VimaxLastAddress
  else
    "if no specified, count or last address, prompt for input
    return input(prompt_string)
  endif

endfunction

"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! vimax#RunCommand(command, ...)

  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')

  if empty(address)
    echo 'No address specified'
    return 0
  endif

  let l:auto_return = 1
  if exists('a:2')
    let l:auto_return = a:2
  endif

  "save to global last command, last address and a dict of key=last address
  "value=last command
  let g:VimaxLastCommand = a:command
  let g:VimaxLastAddress = address
  let g:VimaxLastCommandDict[address] = a:command

  call vimax#SendKeys(g:VimaxResetSequence, address)
  call vimax#SendText(a:command, address)

  if l:auto_return == 1
    call vimax#SendKeys('Enter', address)
  endif

endfunction

"run last command from dict based on pane from count, arg, last address,
"or prompt. If no last command and buffer exists send, 'Up' and 'Enter'
function! vimax#RunLastCommand(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  if !empty('g:VimaxLastCommandDict')
    let command = get(g:VimaxLastCommandDict, address, 'Up')
    call vimax#RunCommand(command, address)
  else
    echo 'No last command was found'
  endif

  call repeat#set('\<Plug>vimax#RunLastCommand', v:count)
endfunction

"ask for a command to run and execute it in pane from count, arg, last address, or prompt
function! vimax#PromptCommand(...)
  let default = a:0 == 1 ? a:1 : ""
  let command = input(g:VimaxPromptString, default)
  if empty(command)
    echo 'No command specified'
  else
    call vimax#RunCommand(command)
  endif

  call repeat#set('\<Plug>vimax#RunLastCommand', v:count)
endfunction

"kill a specific address
function! vimax#CloseAddress()
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call system('tmux kill-pane -t '.address)
endfunction

"turns pane into a window and a window into a pane
"TODO:
"function! VimaxToggleAddress()
"  if _VimuxRunnerType() == "window"
"    call system("tmux join-pane -d -s ".g:VimuxRunnerIndex." -p "._VimuxOption("g:VimuxHeight", 20))
"    let g:VimuxRunnerType = "pane"
"  elseif _VimuxRunnerType() == "pane"
"    let g:VimuxRunnerIndex = substitute(system("tmux break-pane -d -t ".g:VimuxRunnerIndex." -P -F '#{window_index}'"), "\n", "", "")
"    let g:VimuxRunnerType = "window"
"  endif
"endfunction

"travel to an address and zoom in
function! vimax#ZoomAddress(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call vimax#GoToAddress(address)
  call system('tmux resize-pane -Z')
endfunction

"function to return to last vim address, good for functions that need to be in
"the pane to execute but return to original vim. See VimaxScrollUpInspect
"and ...Down...
function! s:ReturnToLastVimAddress()
  let [ split_address, len_address ] =
    \ s:AddressSplitLength(g:VimaxLastVimAddress)
  if len_address < 3
    let [ window_address, pane_address ] = split_address
  else
    let [ session, window, pane_address ] = split_address
    let window_address = session.':'.window
  endif
  call system('tmux select-window -t '
    \ .window_address
    \ .'; tmux select-pane -t '
    \ .pane_address)
endfunction

"travel to address, insert copy mode, page up, then return to vim
function! vimax#ScrollUpInspect(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  call vimax#InspectAddress(address)
  call s:ReturnToLastVimAddress()
  call vimax#SendKeys('C-u', address)

  call repeat#set('\<Plug>vimax#ScrollUpInspect', v:count)
endfunction

"travel to address, insert copy mode, page down, then return to vim
function! vimax#ScrollDownInspect(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  call vimax#InspectAddress(address)
  call s:ReturnToLastVimAddress()
  call vimax#SendKeys('C-d', address)

  call repeat#set('\<Plug>vimax#ScrollDownInspect', v:count)
endfunction

"send an interrupt sequence (control-c) to address
function! vimax#InterruptAddress(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimaxLastAddress = address
  call vimax#SendKeys('^C', address)

  call repeat#set('\<Plug>vimax#InterruptAddress', v:count)
endfunction

"clear an address's tmux history and clear the terminal
function! vimax#ClearAddressHistory(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimaxLastAddress = address
  call system('tmux clear-history -t '.address)
  call vimax#SendText('clear', address)
  call vimax#SendKeys('Enter', address)
endfunction

"send escaped text by calling VimaxSendKeys. Needs text and pane explicitly
function! vimax#SendText(text, address)
  call vimax#SendKeys('"'.escape(a:text, '"$').'"', a:address)
endfunction

"send specific keys to a tmux pane. Needs keys and address explicitly
function! vimax#SendKeys(keys, address)
  let address = type(a:address) == 1 ? a:address : string(a:address)
  call system('tmux send-keys -t '.address.' '.a:keys)
endfunction

function! s:AddressSplitLength(address)
  let split_address = split(a:address, '\.')
  return [ split_address, len(split_address) ]
endfunction

"travel to an address and persist it as the last-used
function! vimax#GoToAddress(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif

  "set vim and tmux VimaxLastVimAddress variables
  "Potential TODO: handle session
  let g:VimaxLastVimAddress = system("tmux display-message -p '#I.#P'")
  call system('tmux set-environment VimaxLastVimAddress '.g:VimaxLastVimAddress)
  let g:VimaxLastAddress = address

  let [ split_address, len_address ] = s:AddressSplitLength(address)

  if len_address == 3
    call system('tmux select-window -t '.split_address[0].':'.split_address[1].'; tmux select-pane -t '.split_address[2])
  elseif len_address == 2
    call system('tmux select-window -t '.split_address[0].'; tmux select-pane -t '.split_address[1])
  elseif len_address == 1
    call system('tmux select-pane -t '.split_address[0])
  endif

endfunction

"enter window and pane in copy mode
function! vimax#InspectAddress(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call vimax#GoToAddress(address)
  call system('tmux copy-mode')
endfunction

function! vimax#List()
  let state = {
    \ 'type': 's',
    \ 'query': 'Vimax List',
    \ 'pick_last_item': 0,
    \ }
  let lines = system('tmux lsp -a -F "#S:#{=10:window_name}-#I:#P #{pane_current_command} #{?pane_active,(active),}"')
  let state.base = split(lines, '\n')
  if g:VimaxFuzzyBuffer
    let picked = tlib#input#ListD(state)
    if !empty(picked)
      let [ _, session, window, pane; rest ] = matchlist(picked, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
      let g:VimaxLastAddress = session.':'.window.'.'.pane
      return g:VimaxLastAddress
    endif
  endif
  return 'none'
endfunction

function! ChangeTarget(state, items)
  for i in a:items
    let new_address = vimax#List()
    let s:state.address = new_address
  endfor
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

function! vimax#History(...)
  if !g:VimaxFuzzyBuffer
    echo 'Tlib is not loaded'
    return 0
  endif

  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  let s:state = {
    \ 'type': 's',
    \ 'query': 'Vimax History | <C-t> - change target | ',
    \ 'key_handlers': [
        \ {'key': 1, 'agent': 'ChangeTarget', 'key_name': '<C-a>'},
    \ ],
    \ 'pick_last_item': 0,
    \ 'address': address
    \ }

  let lines = system('tail -'.g:VimaxLimitHistory.' /home/lowghost/.bash_history')
  let s:state.base = split(lines, '\n')
  let command = tlib#input#ListD(s:state)
  if !empty(command)
    call vimax#RunCommand(command, s:state.address)
  else
    echo 'No command specified'
  endif
endfunction

