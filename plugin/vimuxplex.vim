if exists('g:vimux_plex_loaded') || &cp
  finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 11
  runtime plugin/02tlib.vim
  let s:has_tlib = (!exists('g:loaded_tlib') || g:loaded_tlib < 11) ? 0 : 1
else
  let s:has_tlib = 1
endif
let g:vimux_plex_loaded = 1


"TODO: check address existence
"uses 'none' string b/c of high possibility of 0 address
function! s:VimuxPlexGetAddress(specified_address)

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
  elseif exists('g:VimuxPlexLastAddress')
    "use last address as the default
    return g:VimuxPlexLastAddress
  else
    "if no specified, count or last address, prompt for input
    return input(prompt_string)
  endif

endfunction

"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! VimuxPlexRunCommand(command, ...)

  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')

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
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  if exists('g:VimuxPlexLastCommandDict')
    let command = get(g:VimuxPlexLastCommandDict, address, 'Up')
    call VimuxPlexRunCommand(command, address)
  endif

  call repeat#set('\<Plug>VimuxPlexRunLastCommand', v:count)
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

  call repeat#set('\<Plug>VimuxPlexRunLastCommand', v:count)
endfunction

"kill a specific address
function! VimuxPlexCloseAddress()
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call system('tmux kill-pane -t '.address)
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
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
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
  let [ split_address, len_address ] =
    \ s:AddressSplitLength(g:VimuxPlexLastVimAddress)
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
function! VimuxPlexScrollUpInspect(...)
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  call VimuxPlexInspectAddress(address)
  call s:VimuxPlexReturnToLastVimAddress()
  call VimuxPlexSendKeys('C-u', address)

  call repeat#set('\<Plug>VimuxPlexScrollUpInspect', v:count)
endfunction

"travel to address, insert copy mode, page down, then return to vim
function! VimuxPlexScrollDownInspect(...)
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  call VimuxPlexInspectAddress(address)
  call s:VimuxPlexReturnToLastVimAddress()
  call VimuxPlexSendKeys('C-d', address)

  call repeat#set('\<Plug>VimuxPlexScrollDownInspect', v:count)
endfunction

"send an interrupt sequence (control-c) to address
function! VimuxPlexInterruptAddress(...)
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimuxPlexLastAddress = address
  call VimuxPlexSendKeys('^C', address)

  call repeat#set('\<Plug>VimuxPlexInterruptAddress', v:count)
endfunction

"clear an address's tmux history and clear the terminal
function! VimuxPlexClearAddressHistory(...)
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let g:VimuxPlexLastAddress = address
  call system('tmux clear-history -t '.address)
  call VimuxPlexSendText('clear', address)
  call VimuxPlexSendKeys('Enter', address)
endfunction

"send escaped text by calling VimuxPlexSendKeys. Needs text and pane explicitly
function! VimuxPlexSendText(text, address)
  call VimuxPlexSendKeys('"'.escape(a:text, '"$').'"', a:address)
endfunction

"send specific keys to a tmux pane. Needs keys and address explicitly
function! VimuxPlexSendKeys(keys, address)
  let address = type(a:address) == 1 ? a:address : string(a:address)
  call system('tmux send-keys -t '.address.' '.a:keys)
endfunction

function! s:AddressSplitLength(address)
  let split_address = split(a:address, '\.')
  return [ split_address, len(split_address) ]
endfunction

"travel to an address and persist it as the last-used
function! VimuxPlexGoToAddress(...)
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
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
  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
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
  if s:has_tlib
    let picked = tlib#input#ListD(state)
    if !empty(picked)
      let [ _, session, window, pane; rest ] = matchlist(picked, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
      let g:VimuxPlexLastAddress = session.':'.window.'.'.pane
      return g:VimuxPlexLastAddress
    endif
  endif
  return 'none'
endfunction

function! ChangeTarget(state, items)
  for i in a:items
    let new_address = VimuxPlexList()
    let s:state.address = new_address
  endfor
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

function! VimuxPlexHistory(...)
  if !s:has_tlib
    echo 'Tlib is not loaded'
    return 0
  endif

  let address = s:VimuxPlexGetAddress(exists('a:1') ? a:1 : 'none')
  let s:state = {
    \ 'type': 's',
    \ 'query': 'VimuxPlex History | <C-t> - change target | ',
    \ 'key_handlers': [
        \ {'key': 1, 'agent': 'ChangeTarget', 'key_name': '<C-a>'},
    \ ],
    \ 'pick_last_item': 0,
    \ 'address': address
    \ }
  let limit = exists('g:VimuxPlexLimitHistory')
    \ ? g:VimuxPlexLimitHistory
    \ : 25

  let lines = system('tail -'.limit.' /home/lowghost/.bash_history')
  let s:state.base = split(lines, '\n')
  let command = tlib#input#ListD(s:state)
  if !empty(command)
    call VimuxPlexRunCommand(command, s:state.address)
  else
    echo 'No command specified'
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
nnoremap <unique> <Plug>VimuxPlexHistory :<C-U>call VimuxPlexHistory()<CR>
nnoremap <unique> <Plug>VimuxPlexList :call VimuxPlexList()<CR>

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
command -nargs=* VimuxPlexHistory call VimuxPlexHistory(<f-args>)
command VimuxPlexList call VimuxPlexList()

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
