"Runs a command to an address based on pane from count, arg, last address,
"or prompt. Args: command, address (0 if passing to other optional sources),
"and auto_return (0 if prevent the default of sending an enter key)
"Persists last command and address in variables and in a dict
function! vimax#RunCommand(command, ...)

  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')

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
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
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
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
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
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call system('tmux kill-pane -t '.address)
endfunction

"travel to an address and zoom in
function! vimax#ZoomAddress(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call vimax#GoToAddress(address)
  call system('tmux resize-pane -Z')
endfunction

"travel to address, insert copy mode, page up, then return to vim
function! vimax#ScrollUpInspect(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  call vimax#InspectAddress(address)
  call vimax#util#return_to_last_vim_address()
  call vimax#SendKeys('C-u', address)

  call repeat#set('\<Plug>vimax#ScrollUpInspect', v:count)
endfunction

"travel to address, insert copy mode, page down, then return to vim
function! vimax#ScrollDownInspect(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  call vimax#InspectAddress(address)
  call vimax#util#return_to_last_vim_address()
  call vimax#SendKeys('C-d', address)

  call repeat#set('\<Plug>vimax#ScrollDownInspect', v:count)
endfunction

"send an interrupt sequence (control-c) to address
function! vimax#InterruptAddress(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
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
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
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

"travel to an address and persist it as the last-used
function! vimax#GoToAddress(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif

  "set vim and tmux VimaxLastVimAddress variables
  let g:VimaxLastVimAddress = system("tmux display-message -p '#S:#I.#P'")
  call system('tmux set-environment VimaxLastVimAddress '.g:VimaxLastVimAddress)
  let g:VimaxLastAddress = address

  let [ split_address, len_address ] = vimax#util#address_split_length(address)

  if len_address == 3
    call system('tmux select-window -t '.split_address[0].':'.split_address[1].'; tmux select-pane -t '.split_address[2])
  elseif len_address == 2
    call system('tmux select-window -t '.split_address[0].'; tmux select-pane -t '.split_address[1])
  elseif len_address == 1
    call system('tmux select-pane -t '.split_address[0])
  endif

endfunction
"enter window and pane in copy mode
"
function! vimax#ExitInspect(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  let g:VimaxLastAddress = address
  call vimax#SendKeys(g:VimaxResetSequence, address)
endfunction

"enter window and pane in copy mode
function! vimax#InspectAddress(...)
  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  call vimax#GoToAddress(address)
  call system('tmux copy-mode')
endfunction

function! s:run_in_dir(path, command)
  let g:VimaxLastAddress = system(
    \ 'tmux split-window -'.
    \ g:VimaxOrientation.' -l '.g:VimaxHeight.
    \ "\\\; send-keys 'cd ".a:path." && ".a:command."'".
    \ "\\\; send-keys 'Enter'".
    \ "\\\; display-message -p '#S:#I.#P'"
    \ )
  call system('tmux last-pane')
endfunction

"open a new tmux split in current directory
"and run a command from prompt or from first arg
function! vimax#RunCommandInDir(...)
  let path = shellescape(expand('%:p:h'), 1)
  let command = exists('a:1')
    \ ? shellescape(a:1)
    \ : shellescape(input(g:VimaxPromptString))
  return s:run_in_dir(path, command)
endfunction

function! vimax#RunCommandAtGitRoot(...)
  let path = systemlist('git rev-parse --show-toplevel')[0]
  if v:shell_error
    return s:warn('Not in git repo')
  endif
  let command = exists('a:1')
    \ ? shellescape(a:1)
    \ : shellescape(input(g:VimaxPromptString))
  return s:run_in_dir(path, command)
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
  let fzf_sink = exists('a:2') ? a:2 : 'vimax#fzf#list_sink'
  let header = '"'.unquoted_header.'"'

  if g:VimaxFuzzyBuffer == 'none'
    echo lines
  elseif g:VimaxFuzzyBuffer == 'tlib'
    return vimax#tlib#list(lines, header)
  elseif g:VimaxFuzzyBuffer == 'fzf'
    return vimax#fzf#list(lines, header, fzf_sink)
  endif

  return 'none'

endfunction

"main history function.
"Lists command line history for execution and
"gives keybingings for additional features
function! vimax#History(...)

  let address = vimax#util#get_address(exists('a:1') ? a:1 : 'none')
  let lines = vimax#fuzzy#get_history_lines()

  if g:VimaxFuzzyBuffer == 'none'
    let g:VimaxLastAddress = address
    echo "Neither Tlib nor FZF is loaded.\n
      \You'll have to call :VimaxRunCommand <command> yourself\n\n"
    echo lines
    return 1
  elseif g:VimaxFuzzyBuffer == 'tlib'
    return vimax#tlib#history(address, lines)
  elseif g:VimaxFuzzyBuffer == 'fzf'
    return vimax#fzf#history(address, lines)
  endif

endfunction
