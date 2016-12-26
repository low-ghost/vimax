"fzf variations of fuzzy search buffer functionality

function! vimax#fzf#run(opts)
  "opts { mode, source, sink, header, ?prompt, ?bindings }
  let capital_mode = vimax#util#capitalize(a:opts.mode)
  let options_prompt = capital_mode . ' ' . get(a:opts, 'prompt', 'list')
  let options_init = '+m --ansi --prompt="' . options_prompt . '> "'
  let bindings = has_key(a:opts, 'bindings') ? ' --expect="' . a:opts.bindings . '"' : ''
  let header = ' --header "' . capital_mode . ' '  . a:opts.header . '"'
  let options = options_init . bindings . header . ' --tiebreak=index'

  return fzf#run(extend({
    \ 'source': a:opts.source,
    \ 'sink*': function(a:opts.sink),
    \ 'options': options,
    \ }, g:VimaxFzfLayout))
endfunction

function! s:create_ctrl_binding(key)
  "returns pair of bindings, [ fzf ]
  return 'ctrl-' . a:key
endfunction

function! s:create_alt_binding(key)
  "returns alt bindings, [ fzf ]
  return 'alt-' . a:key
endfunction

function! vimax#fzf#generate_binds(mode, kind)
  "generates or retrieves from cache all bindings for a mode for all fzf kinds,
  "but only returns the specified kind
  let prefix = 'vimax#' . a:mode
  let name = prefix . '#bindings'
  let existing_binds = get(g:, name, v:null)
  "cached
  if !(existing_binds is v:null)
    return existing_binds[a:kind]
  endif

  execute 'let g:' . name . ' = {}'
  "we'll mutate this and in tern mutate g:<name>
  let global_binds = get(g:, name)

  for kind in ['list', 'history']
    "get mode specific bindings if they exist at vimax#mode#list_bindings or
    "get the global bindings defaulted in /plugin at vimax#list_bindings
    let global_binds[kind] = {}
    let bindings = get(g:, prefix . '#list_bindings', get(g:, 'vimax#list_bindings'))

    for [key, value] in items(bindings)
      let global_binds[kind][key] = s:create_ctrl_binding(value)
    endfor
  endfor

  return global_binds[kind]
endfunction

function! vimax#fzf#list_sink(lines)

  if !len(a:lines)
    return g:vimax#none
  endif

  let binds = g:VimaxListBindings
  let [ key, item; rest ] = a:lines
  let picked = vimax#util#get_address_from_list_item(item)

  "history?
  if key == vimax#fuzzy#get_binding(binds.help)[0]
    call input(vimax#fuzzy#help(binds, 'List')."\n\nPress Enter to continue")
  elseif key == vimax#fuzzy#get_binding(binds.go_to)[0]
    return vimax#GoToAddress(picked)
  elseif key == vimax#fuzzy#get_binding(binds.zoom)[0]
    return vimax#ZoomAddress(picked)
  elseif key == vimax#fuzzy#get_binding(binds.inspect)[0]
    return vimax#InspectAddress(picked)
  elseif key == vimax#fuzzy#get_binding(binds.close)[0]
    return vimax#CloseAddress(picked)
  elseif key == vimax#fuzzy#get_binding(binds.prompt)[0]
    return vimax#PromptCommand(picked)
  elseif key == vimax#fuzzy#get_binding(binds.last)[0]
    return vimax#RunLastCommand(picked)
  endif

  let g:VimaxLastAddress = picked
  "restart list if was help command
  call vimax#List()
  return s:nvim_insert_fix()

endfunction

function! vimax#fzf#list_from_history_sink(lines)
  if !len(a:lines)
    return g:vimax#none
  endif

  let [ picked; rest ] = a:lines
  let original_address = g:VimaxLastAddress
  let address = vimax#util#set_last_address(picked)

  if address != g:vimax#none
    let lines = vimax#fuzzy#get_history_lines()

    if s:fzf_history_last_binding == 'change_target'
      call vimax#fzf#history(address, lines)
      return s:nvim_insert_fix()
    endif

    call vimax#RunCommand(s:fzf_history_last, address)
  endif

  call vimax#fzf#history(original_address, lines)
  return s:nvim_insert_fix()
endfunction

function! vimax#fzf#list(lines, header, sink)
  return fzf#run(extend({
    \ 'source': reverse(split(a:lines, '\n')),
    \ 'sink*': function(a:sink),
    \ 'options': '+m --ansi --prompt="Address> "'.
      \ ' --expect='.join(vimax#fuzzy#get_all_bindings('list'), ',').
      \ ' --header '.a:header.
      \ ' --tiebreak=index',
    \ }, g:VimaxFzfLayout))
endfunction

"basically forces startinsert, which isn't working in a second fzf instance
"for some reason or other
function! s:nvim_insert_fix()
  if has('nvim')
    call feedkeys('A', 'n')
  endif
endfunction

"fzf sink. handles keybindings
function! vimax#fzf#history_sink(lines)
  if len(a:lines) < 2
    return
  endif

  let [ key, item; rest ] = a:lines
  let binds = g:VimaxHistoryBindings
  let address = g:VimaxLastAddress

  if key == vimax#fuzzy#get_binding(binds.change_target)[0]
    let s:fzf_history_last_binding = 'change_target'
    call vimax#List('Change Target Address for History', 'vimax#fzf#list_from_history_sink')
    return s:nvim_insert_fix()

  elseif key == vimax#fuzzy#get_binding(binds.help)[0]
    call input(vimax#fuzzy#help(g:VimaxHistoryBindings, 'History')."\n\nPress Enter to continue")

  elseif key == vimax#fuzzy#get_binding(binds.run_at_address)[0]
    call vimax#RunCommand(item, address)

  elseif key == vimax#fuzzy#get_alt_binding(binds.run_at_address)[0]
    let s:fzf_history_last = item
    call vimax#List('Run at Address', 'vimax#fzf#list_from_history_sink')
    return s:nvim_insert_fix()

  elseif key == vimax#fuzzy#get_binding(binds.edit)[0]
    return vimax#util#append_to_scratch(item)

  elseif key == vimax#fuzzy#get_alt_binding(binds.edit)[0]
    let s:fzf_history_last = item
    call vimax#List('Run History Command at Address After Editing', 'vimax#fzf#list_from_history_sink')
    return s:nvim_insert_fix()

  endif

  if index(vimax#fuzzy#get_all_bindings('history'), key) >= 0
    let lines = vimax#fuzzy#get_history_lines()
    call vimax#fzf#history(address, lines)
    return s:nvim_insert_fix()
  endif

  return vimax#RunCommand(item, address)
endfunction

"main fzf history function. 
"expects a single function, or sink, to handle key bindings
"and returns the key and selection after, thus necessitating
"the recursive strategy
function! vimax#fzf#history(address, lines)
  let s:fzf_history_last_binding = g:vimax#none
  let g:VimaxLastAddress = a:address
  return fzf#run(extend({
    \ 'source': reverse(a:lines),
    \ 'sink*': function('vimax#fzf#history_sink'),
    \ 'options': '+m --ansi --prompt="Hist> "'.
      \ ' --expect='.join(vimax#fuzzy#get_all_bindings('history'), ',').
      \ ' --header "'.vimax#fuzzy#history_header().'"'.
      \ ' --tiebreak=index',
    \ }, g:VimaxFzfLayout))
endfunction
