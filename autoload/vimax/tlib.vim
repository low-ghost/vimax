"tlib variation of the list function
function! vimax#tlib#list(lines, header)
  let state = {
    \ 'type': 's',
    \ 'query': a:header,
    \ 'pick_last_item': 0,
    \ }
  let state.base = split(a:lines, '\n')
  let picked = tlib#input#ListD(state)
  return vimax#util#set_last_address(picked)
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
  call input(vimax#fuzzy#history_help()."\n\nPress Enter to continue")
  let a:state.state = 'display'
  silent exe ':redraw!'
  return a:state
endfunction

"tlib history function.
"expects individual functions to handle key bindings
function! vimax#tlib#history(address, lines)

  let binds = g:VimaxHistoryBindings

  "to get the key number for a <C-<key>> bind w/ stridx
  let all_possible_keys = '0abcdefghijklmnopqrstuvwxyz'

  let s:state = {
    \ 'type': 's',
    \ 'query': vimax#fuzzy#history_header(),
    \ 'key_handlers': [
      \ {
      \ 'key': stridx(all_possible_keys, binds.change_target),
      \ 'agent': 'TlibChangeTarget',
      \ 'key_name': vimax#fuzzy#get_binding(binds.change_target)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.run_at_address),
      \ 'agent': 'TlibExecuteAtAddress',
      \ 'key_name': vimax#fuzzy#get_binding(binds.run_at_address)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.edit),
      \ 'agent': 'TlibEdit',
      \ 'key_name': vimax#fuzzy#get_binding(binds.edit)[0]
      \ },
      \ {
      \ 'key': stridx(all_possible_keys, binds.help),
      \ 'agent': 'TlibHelp',
      \ 'key_name': vimax#fuzzy#get_binding(binds.help)[0]
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
