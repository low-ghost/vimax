"fzf variations of fuzzy search buffer functionality

function! vimax#fzf#list_sink(lines)

  if !len(a:lines)
    return 'none'
  endif

  let [ picked; rest ] = a:lines
  return vimax#util#set_last_address(picked)

endfunction

function! vimax#fzf#list_from_history_sink(lines)

  if !len(a:lines)
    return 'none'
  endif

  let [ picked; rest ] = a:lines
  let original_address = g:VimaxLastAddress
  let address = vimax#util#set_last_address(picked)

  if address != 'none'
    let lines = vimax#fuzzy#get_history_lines()

    if s:fzf_history_last_binding == 'change_target'
      return vimax#fzf#history(address, lines)
    endif

    call vimax#RunCommand(s:fzf_history_last, address)
    return vimax#fzf#history(original_address, lines)
  endif

  return vimax#fzf#history(original_address, lines)
endfunction

function! vimax#fzf#list(lines, header, sink)
  let picked = fzf#run({
    \ 'source': reverse(split(a:lines, '\n')),
    \ 'sink*': function(a:sink),
    \ 'options': '--ansi --prompt="Address> "'.
      \ ' --header '.a:header.
      \ ' --tiebreak=index',
    \ })
  "if !has('nvim')
    "call function(a:sink)(picked)
  "endif
endfunction

"fzf sink. handles keybindings
function! vimax#fzf#history_sink(lines)
  if len(a:lines) < 2
    return
  endif

  let [ key, item; rest ] = a:lines
  let binds = g:VimaxHistoryBindings
  let address = g:VimaxLastAddress

  if key == vimax#fuzzy#get_binding(binds.change_target)[1]
    let s:fzf_history_last_binding = 'change_target'
    return vimax#List('Change Target Address for History', 'vimax#fzf#list_from_history_sink')

  elseif key == vimax#fuzzy#get_binding(binds.help)[1]
    call input(vimax#fuzzy#history_help()."\n\nPress Enter to continue")

  elseif key == vimax#fuzzy#get_binding(binds.run_at_address)[1]
    call vimax#RunCommand(item, address)

  elseif key == vimax#fuzzy#get_alt_binding(binds.run_at_address)[1]
    let s:fzf_history_last = item
    return vimax#List('Run at Address', 'vimax#fzf#list_from_history_sink')

  elseif key == vimax#fuzzy#get_binding(binds.edit)[1]
    call vimax#PromptCommand(address, item)

  elseif key == vimax#fuzzy#get_alt_binding(binds.edit)[1]
    let s:fzf_history_last = item
    return vimax#List('Run History Command at Address After Editing', 'vimax#fzf#list_from_history_sink')

  endif

  if index(vimax#fuzzy#get_all_bindings(), key) >= 0
    let lines = vimax#fuzzy#get_history_lines()
    return vimax#fzf#history(address, lines)
  endif

  return vimax#RunCommand(item, address)

endfunction

"main fzf history function. 
"expects a single function, or sink, to handle key bindings
"and returns the key and selection after, thus necessitating
"the recursive strategy
function! vimax#fzf#history(address, lines)
  let s:fzf_history_last_binding = 'none'
  let g:VimaxLastAddress = a:address
  return fzf#run({
    \ 'source': a:lines,
    \ 'sink*': function('vimax#fzf#history_sink'),
    \ 'options': '+m --ansi --prompt="Hist> "'.
      \ ' --expect='.join(vimax#fuzzy#get_all_bindings(), ',').
      \ ' --header "'.vimax#fuzzy#history_header().'"'.
      \ ' --tiebreak=index',
    \ })

endfunction
