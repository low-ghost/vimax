if exists('g:loaded_vimux_plex') || &cp
  finish
endif
let g:loaded_vimux_plex = 1

"TODO: check address existence
"Possible TODO: localize to script
function! VimuxPlexGetAddress(specified_address)

  if a:specified_address
    "directly pass address as the second argument
    return
      \ type(a:specified_address) == 1
      \ ? a:specified_address
      \ : string(a:specified_address)
  elseif exists('v:count') && v:count != 0
    "join a two or three digit count with a dot so that 10 refers to 1.0 or window 1,
    "pane 0. could also give 3 numbers to indicate session, window, pane
    return join(split(string(v:count), '\zs'), '.')
  elseif exists('g:VimuxPlexLastAddress')
    "use last address as the default
    return g:VimuxPlexLastAddress
  else
    "if no last address, prompt for input
    return input('Enter address number: ')
  endif

endfunction

"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! VimuxPlexRunCommand(command, ...)

  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)

  if empty(address)
    echo 'No address specified'
    return 0
  endif

  let l:auto_return = 1
  if exists('a:2')
    let l:auto_return = a:2
  endif

  let reset_sequence =
    \ exists('g:VimuxPlexResetSequence')
    \ ? g:VimuxPlexResetSequence
    \ : 'q C-u'
  "save to global last command, last address and a dict of key=last address
  "value=last command
  let g:VimuxPlexLastCommand = a:command
  let g:VimuxPlexLastAddress = address
  if !exists('g:VimuxPlexLastCommandDict')
    let g:VimuxPlexLastCommandDict = {}
  endif
  let g:VimuxPlexLastCommandDict[address] = a:command

  call VimuxPlexSendKeys(reset_sequence, address)
  call VimuxPlexSendText(a:command, address)

  if l:auto_return == 1
    call VimuxPlexSendKeys('Enter', address)
  endif

endfunction

"run last command from dict based on pane from count, arg, last address,
"or prompt. If no last command and buffer exists send, 'Up' and 'Enter'
function! VimuxPlexRunLastCommand(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  if exists('g:VimuxPlexLastCommandDict')
    let command = get(g:VimuxPlexLastCommandDict, address, 'Up')
    call VimuxPlexRunCommand(command, address)
  endif
  if exists('g:repeat_tick')
    call repeat#set('\<Plug>VimuxPlexRunLastCommand', v:count)
  endif
endfunction

"ask for a command to run and execute it in pane from count, arg, last address, or prompt
function! VimuxPlexPromptCommand(...)
  let default = a:0 == 1 ? a:1 : ""
  let command = input(
    \ exists('g:VimuxPlextPromptString')
    \ ? g:VimuxPromptString
    \ : 'Command? '
    \ , default)
  if empty(command)
    echo 'No command specified'
  else
    call VimuxPlexRunCommand(command)
  endif
  if exists('g:repeat_tick')
    call repeat#set('\<Plug>VimuxPlexRunLastCommand', v:count)
  endif
endfunction

"kill a specific address
function! VimuxPlexCloseAddress()
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  "TODO: handle session
  let [ split_address, len_address ] = s:AddressSplitLength(address)
  if (len_address < 3)
    call system('tmux kill-pane -t '.address)
  endif
endfunction

"turns pane into a window and a window into a pane
"TODO:
"function! VimuxPlexToggleAddress()
"  if _VimuxRunnerType() == "window"
"    call system("tmux join-pane -d -s ".g:VimuxRunnerIndex." -p "._VimuxOption("g:VimuxHeight", 20))
"    let g:VimuxRunnerType = "pane"
"  elseif _VimuxRunnerType() == "pane"
"    let g:VimuxRunnerIndex = substitute(system("tmux break-pane -d -t ".g:VimuxRunnerIndex." -P -F '#{window_index}'"), "\n", "", "")
"    let g:VimuxRunnerType = "window"
"  endif
"endfunction

"travel to an address and zoom in
function! VimuxPlexZoomAddress(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call VimuxPlexGoToAddress(address)
  call system('tmux resize-pane -Z')
endfunction

"function to return to last vim address, good for functions that need to be in
"the pane to execute but return to original vim. See VimuxPlexScrollUpInspect
"and ...Down...
function! s:VimuxPlexReturnToLastVimAddress()
  "Potential TODO: respect session
  let split_address = split(g:VimuxPlexLastVimAddress, '\.')
  call system('tmux select-window -t '.split_address[0].'; tmux select-pane -t '.split_address[1])
endfunction

"travel to address, insert copy mode, page up, then return to vim
function! VimuxPlexScrollUpInspect(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  call VimuxPlexInspectAddress(address)
  call s:VimuxPlexReturnToLastVimAddress()
  call VimuxPlexSendKeys('C-u', address)
  if exists('g:repeat_tick')
    call repeat#set('\<Plug>VimuxPlexScrollUpInspect', v:count)
  endif
endfunction

"travel to address, insert copy mode, page down, then return to vim
function! VimuxPlexScrollDownInspect(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  call VimuxPlexInspectAddress(address)
  call s:VimuxPlexReturnToLastVimAddress()
  call VimuxPlexSendKeys('C-d', address)
  if exists('g:repeat_tick')
    call repeat#set('\<Plug>VimuxPlexScrollDownInspect', v:count)
  endif
endfunction

"send an interrupt sequence (control-c) to address
function! VimuxPlexInterruptAddress(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimuxPlexLastAddress = address
  call VimuxPlexSendKeys('^C', address)
  if exists('g:repeat_tick')
    call repeat#set('\<Plug>VimuxPlexInterruptAddress', v:count)
  endif
endfunction

"clear an address's tmux history and clear the terminal
function! VimuxPlexClearAddressHistory(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimuxPlexLastAddress = address
  "TODO: handle session
  let [ split_address, len_address ] = s:AddressSplitLength(address)
  if (len_address < 3)
    call system('tmux clear-history -t '.address)
    call VimuxPlexSendText('clear', address)
    call VimuxPlexSendKeys('Enter', address)
  endif
endfunction

"send escaped text by calling VimuxPlexSendKeys. Needs text and pane explicitly
function! VimuxPlexSendText(text, address)
  call VimuxPlexSendKeys('"'.escape(a:text, '"$').'"', a:address)
endfunction

"send specific keys to a tmux pane. Needs keys and address explicitly
function! VimuxPlexSendKeys(keys, address)
  let address = type(a:address) == 1 ? a:address : string(a:address)
  "TODO: handle session
  let [ split_address, len_address ] = s:AddressSplitLength(address)
  if (len_address < 3)
    call system('tmux send-keys -t '.address.' '.a:keys)
  endif
endfunction

function! s:AddressSplitLength(address)
  let split_address = split(a:address, '\.')
  return [ split_address, len(split_address) ]
endfunction

"travel to an address and persist it as the last-used
function! VimuxPlexGoToAddress(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif

  "set vim and tmux VimuxPlexLastVimAddress variables
  "Potential TODO: handle session
  let g:VimuxPlexLastVimAddress = system("tmux display-message -p '#I.#P'")
  call system('tmux set-environment VimuxPlexLastVimAddress '.g:VimuxPlexLastVimAddress)
  let g:VimuxPlexLastAddress = address

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
function! VimuxPlexInspectAddress(...)
  let address = VimuxPlexGetAddress(exists('a:1') ? a:1 : 0)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call VimuxPlexGoToAddress(address)
  call system('tmux copy-mode')
endfunction

function! VimuxPlexList()
  let state = {
    \ 'type': 's',
    \ 'query': 'VimuxPlex List',
    \ 'pick_last_item': 0,
    \ }
  let lines = system('tmux lsp -a -F "#S:#{=10:window_name}-#I:#P #{pane_current_command} #{?pane_active,(active),}"')
  let state.base = split(lines, '\n')
  if exists('g:loaded_tlib')
    let g:picked = tlib#input#ListD(state)
    if !empty(g:picked)
      let [ _, session, window, pane; rest ] = matchlist(g:picked, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
      "TODO: handle session
      "let g:VimuxPlexLastAddress = join([session, window, pane], '.')
      let g:VimuxPlexLastAddress = join([window, pane], '.')
    endif
  endif
endfunction

"mappings which accept a count to specify the window and pane
"one digit is pane only e.g. 1<mapping> is an action for pane 1
"two digits is window, pane e.g. 12<mapping> is an action for window 1, pane 2
nnoremap <unique> <Plug>VimuxPlexPromptCommand :<C-U>call VimuxPlexPromptCommand()<CR>
nnoremap <unique> <Plug>VimuxPlexRunLastCommand :<C-U>call VimuxPlexRunLastCommand()<CR>
nnoremap <unique> <Plug>VimuxPlexInspectAddress :<C-U>call VimuxPlexInspectAddress()<CR>
nnoremap <unique> <Plug>VimuxPlexClearAddressHistory :<C-U>call VimuxPlexClearAddressHistory()<CR>
nnoremap <unique> <Plug>VimuxPlexInterruptAddress :<C-U>call VimuxPlexInterruptAddress()<CR>
nnoremap <unique> <Plug>VimuxPlexZoomAddress :<C-U>call VimuxPlexZoomAddress()<CR>
nnoremap <unique> <Plug>VimuxPlexGoToAddress :<C-U>call VimuxPlexGoToAddress()<CR>
nnoremap <unique> <Plug>VimuxPlexScrollUpInspect :<C-U>call VimuxPlexScrollUpInspect()<CR>
nnoremap <unique> <Plug>VimuxPlexScrollDownInspect :<C-U>call VimuxPlexScrollDownInspect()<CR>
nnoremap <unique> <Plug>VimuxPlexCloseAddress :<C-U>call VimuxPlexCloseAddress()<CR>

"commands which accept args
command -nargs=* VimuxPlexPromptCommand call VimuxPlexPromptCommand(<f-args>)
command -nargs=* VimuxPlexRunLastCommand call VimuxPlexRunLastCommand(<f-args>)
command -nargs=* VimuxPlexInspectAddress call VimuxPlexInspectAddress(<f-args>)
command -nargs=* VimuxPlexClearAddressHistory call VimuxPlexClearAddressHistory(<f-args>)
command -nargs=* VimuxPlexInterruptAddress call VimuxPlexInterruptAddress(<f-args>)
command -nargs=* VimuxPlexZoomAddress call VimuxPlexZoomAddress(<f-args>)
command -nargs=* VimuxPlexGoToAddress call VimuxPlexGoToAddress(<f-args>)
command -nargs=* VimuxPlexScrollUpInspect call VimuxPlexScrollUpInspect(<f-args>)
command -nargs=* VimuxPlexScrollDownInspect call VimuxPlexScrollDownInspect(<f-args>)
command -nargs=* VimuxPlexCloseAddress call VimuxPlexCloseAddress(<f-args>)

"example mappings
"nmap ,vp <Plug>VimuxPlexPromptCommand
"nmap ,vl <Plug>VimuxPlexRunLastCommand
"nmap ,vi <Plug>VimuxPlexInspectAddress
"nmap ,vc <Plug>VimuxPlexClearAddressHistory
"nmap ,vx <Plug>VimuxPlexInterruptAddress
"nmap ,vz <Plug>VimuxPlexZoomAddress
"nmap ,vg <Plug>VimuxPlexGoToAddress
"nmap ,vk <Plug>VimuxPlexScrollUpInspect
"nmap ,vj <Plug>VimuxPlexScrollDownInspect
"nmap ,vq <Plug>VimuxPlexCloseAddress
