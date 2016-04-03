"TODO: check address existence
"uses 'none' string b/c of high possibility of 0 address
function! s:GetAddress(specified_address)

  let prompt_string = "Tmux address as session:window.pane, session and window optional> "
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
"args: address, default, commandmode
function! vimax#PromptCommand(...)
  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  if exists('a:2')
    let command = input(g:VimaxPromptString, a:2)
  else
    let command = input(g:VimaxPromptString)
  endif
  if empty(command)
    echo 'No command specified'
  else
    call vimax#RunCommand(command, address)
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
  call vimax#SendKeys(shellescape(a:text), a:address)
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
  let g:VimaxLastVimAddress = system("tmux display-message -p '#S:#I.#P'")
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

"open a new tmux split in current directory
"and run a command from prompt or from first arg
function! vimax#RunCommandInDir(...)
  let path = shellescape(expand('%:p:h'), 1)
  let command = exists('a:1')
    \ ? shellescape(a:1)
    \ : shellescape(input(g:VimaxPromptString))
  let g:VimaxLastAddress = system(
    \ 'tmux split-window -'.
    \ g:VimaxOrientation.' -l '.g:VimaxHeight.
    \ "\\\; send-keys 'cd ".path." && ".command."'".
    \ "\\\; send-keys 'Enter'".
    \ "\\\; display-message -p '#S:#I.#P'"
    \ )
  call system('tmux last-pane')
endfunction

"FuzzyBuffer funtions

"returns pair of bindings, [ tlib, fzf ]
"fzf (1) also used for display
function! s:GetBinding(key)
  return [ '<C-'.a:key.'>', 'ctrl-'.a:key ]
endfunction

function! s:GetAltBinding(key)
  return [ '<M-'.a:key.'>', 'alt-'.a:key ]
endfunction

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

"get an address from the format used in vimax#List
function! s:GetAddressFromListItem(item)
  let [ _, session, window, pane; rest ] =
    \ matchlist(a:item, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
  return session.':'.window.'.'.pane
endfunction

"set VimaxLastAddress if the selection is not empty
function! s:SetAndReturnLastAddress(picked)
  if !empty(a:picked)
    let g:VimaxLastAddress = s:GetAddressFromListItem(a:picked)
    return g:VimaxLastAddress
  else
    return 'none'
  endif
endfunction

"tlib variation of the list function
function! s:TlibList(lines, header)
  let state = {
    \ 'type': 's',
    \ 'query': a:header,
    \ 'pick_last_item': 0,
    \ }
  let state.base = split(a:lines, '\n')
  let picked = tlib#input#ListD(state)
  return s:SetAndReturnLastAddress(picked)
endfunction

function! FzfListSink(lines)

  if !len(a:lines)
    return 'none'
  endif

  let [ picked; rest ] = a:lines
  return s:SetAndReturnLastAddress(picked)

endfunction

function! FzfListFromHistorySink(lines)

  if !len(a:lines)
    return 'none'
  endif

  let [ picked; rest ] = a:lines
  let original_address = g:VimaxLastAddress
  let address = s:SetAndReturnLastAddress(picked)

  if address != 'none'
    let lines = s:get_history_lines()

    if s:fzf_history_last_binding == 'change_target'
      return s:FzfHistory(address, lines)
    endif

    call vimax#RunCommand(s:fzf_history_last, address)
    return s:FzfHistory(original_address, lines)
  endif

  return s:FzfHistory(original_address, lines)
endfunction

"fzf variation of the list function
function! s:FzfList(lines, header, sink)
  return fzf#run({
    \ 'source': reverse(split(a:lines, '\n')),
    \ 'sink*': function(a:sink),
    \ 'options': '--ansi --prompt="Address> "'.
      \ ' --header '.a:header.
      \ ' --tiebreak=index',
    \ })
endfunction

"main address listing function.
"Selects function for fuzzy listing
"or just echoes the list
function! vimax#List(...)

  let lines = system(
    \ 'tmux lsp'.
    \ ' -a -F'.
    \ ' "#S:#{=10:window_name}-#I:#P'.
    \ ' #{pane_current_command}'.
    \ ' #{?pane_active,(active),}"'
    \ )

  let unquoted_header = exists('a:1') ? a:1 : 'Vimax Address List'
  let fzf_sink = exists('a:2') ? a:2 : 'FzfListSink'
  let header = '"'.unquoted_header.'"'

  if g:VimaxFuzzyBuffer == 'none'
    echo lines
  elseif g:VimaxFuzzyBuffer == 'tlib'
    return s:TlibList(lines, header)
  elseif g:VimaxFuzzyBuffer == 'fzf'
    return s:FzfList(lines, header, fzf_sink)
  endif

  return 'none'

endfunction

"format history header based on fzf vs tlib
function! s:GetHistoryHeader()
  let history_header = 'Vimax History'
  let display = s:GetBinding(g:VimaxHistoryBindings['help'])[1]

  let colored = g:VimaxFuzzyBuffer == 'fzf'
    \ ? s:magenta(display)
    \ : display

  let history_header .= ' :: '.colored.
    \ ' - show key bindings'
  return history_header
endfunction

function! s:HistoryHelp()
  let binds = g:VimaxHistoryBindings
  let history_header = "History Commands\n"
  for func in keys(binds)
    let display = s:GetBinding(binds[func])[1]
    let history_header .= "\n".display.
      \ ' - '.substitute(func, '_', ' ', 'g')
    if func == 'run_at_address' || func == 'edit'
      let display = s:GetAltBinding(binds[func])[1]
      let history_header .= "\n".display.
        \ '  - prompt for a different address and '.substitute(func, '_', ' ', 'g')
    endif
  endfor
  return history_header
endfunction

"tlib variation of change target function including nested list
function! TlibChangeTarget(state, items)
  for i in a:items
    let new_address = vimax#List('Change Target Address for History')
    let s:state.address = new_address
  endfor
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

"tlib variation of change target function including nested list
function! TlibExecuteAtAddress(state, items)
  for i in a:items
    let address = vimax#List('Run at Address')
    call vimax#RunCommand(i, address)
  endfor
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

"tlib variation of edit function including nested list
function! TlibEdit(state, items)
  for i in a:items
    let address = vimax#List('Run History Command at Address After Editing')
    call vimax#PromptCommand(address, i)
  endfor
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

"tlib variation of display help
function! TlibHelp(state, items)
  call input(s:HistoryHelp()."\n\nPress Enter to continue")
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

"tlib history function.
"expects individual functions to handle key bindings
function! s:TlibHistory(address, lines)

  let binds = g:VimaxHistoryBindings

  "to get the key number for a <C-<key>> bind w/ stridx
  let all_possible_keys = '0abcdefghijklmnopqrstuvwxyz'

  let s:state = {
    \ 'type': 's',
    \ 'query': s:GetHistoryHeader(),
    \ 'key_handlers': [
      \ {
      \ 'key': stridx(all_possible_keys, binds.change_target),
      \ 'agent': 'TlibChangeTarget',
      \ 'key_name': s:GetBinding(binds.change_target)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.run_at_address),
      \ 'agent': 'TlibExecuteAtAddress',
      \ 'key_name': s:GetBinding(binds.run_at_address)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.edit),
      \ 'agent': 'TlibEdit',
      \ 'key_name': s:GetBinding(binds.edit)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.help),
      \ 'agent': 'TlibHelp',
      \ 'key_name': s:GetBinding(binds.help)[0]
      \ },
    \ ],
    \ 'pick_last_item': 0,
    \ 'address': a:address
    \ }
  let s:state.base = a:lines
  let command = tlib#input#ListD(s:state)

  if !empty(command)
    call vimax#RunCommand(command, s:state.address)
  else
    echo 'No command specified'
  endif

endfunction

"fzf sink. handles keybindings
function! FzfRunCommand(lines)
  if len(a:lines) < 2
    return
  endif

  let [ key, item; rest ] = a:lines
  let binds = g:VimaxHistoryBindings
  let address = g:VimaxLastAddress

  if key == s:GetBinding(binds.change_target)[1]
    let s:fzf_history_last_binding = 'change_target'
    return vimax#List('Change Target Address for History', 'FzfListFromHistorySink')

  elseif key == s:GetBinding(binds.help)[1]
    call input(s:HistoryHelp()."\n\nPress Enter to continue")

  elseif key == s:GetBinding(binds.run_at_address)[1]
    call vimax#RunCommand(item, address)

  elseif key == s:GetAltBinding(binds.run_at_address)[1]
    let s:fzf_history_last = item
    return vimax#List('Run at Address', 'FzfListFromHistorySink')

  elseif key == s:GetBinding(binds.edit)[1]
    call vimax#PromptCommand(address, item)

  elseif key == s:GetAltBinding(binds.edit)[1]
    let s:fzf_history_last = item
    return vimax#List('Run History Command at Address After Editing', 'FzfListFromHistorySink')

  endif

  if index(s:all_key_bindings, key) >= 0
    let lines = s:get_history_lines()
    return s:FzfHistory(address, lines)
  endif

  return vimax#RunCommand(item, address)

endfunction

let s:all_key_bindings = []
let binds = g:VimaxHistoryBindings
for func in keys(g:VimaxHistoryBindings)
  call add(s:all_key_bindings, s:GetBinding(binds[func])[1])
  if func == 'run_at_address' || func == 'edit'
    call add(s:all_key_bindings, s:GetAltBinding(binds[func])[1])
  endif
endfor

"main fzf history function. 
"expects a single function, or sink, to handle key bindings
"and returns the key and selection after, thus necessitating
"the recursive strategy
function! s:FzfHistory(address, lines)
  let s:fzf_history_last_binding = 'none'
  let g:VimaxLastAddress = a:address
  return fzf#run({
    \ 'source': a:lines,
    \ 'sink*': function('FzfRunCommand'),
    \ 'options': '+m --ansi --prompt="Hist> "'.
      \ ' --expect='.join(s:all_key_bindings, ',').
      \ ' --header "'.s:GetHistoryHeader().'"'.
      \ ' --tiebreak=index',
    \ })

endfunction

function s:get_history_lines()
  let lines = split(system('tail -'.g:VimaxLimitHistory.' '.g:VimaxHistoryFile), '\n')
  if g:VimaxHistoryFile =~ 'zsh'
    return map(lines, "substitute(v:val, ': \\d*:\\d;', '', '')")
  endif
  return lines
endfunction

"main history function.
"Lists command line history for execution and
"gives keybingings for additional features
function! vimax#History(...)

  let address = s:GetAddress(exists('a:1') ? a:1 : 'none')
  let lines = s:get_history_lines()

  if g:VimaxFuzzyBuffer == 'none'
    let g:VimaxLastAddress = address
    echo "Neither Tlib nor FZF is loaded.\n
      \You'll have to call :VimaxRunCommand <command> yourself\n\n"
    echo lines
    return 1
  elseif g:VimaxFuzzyBuffer == 'tlib'
    return s:TlibHistory(address, lines)
  elseif g:VimaxFuzzyBuffer == 'fzf'
    return s:FzfHistory(address, lines)
  endif

endfunction
