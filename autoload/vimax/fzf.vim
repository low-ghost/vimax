"fzf variations of fuzzy search buffer functionality
"
function! vimax#fzf#help(binds, title) abort
  let l:header = a:title." Commands\n"
  for [l:key, l:value] in items(a:binds)
    let l:header .= "\n" . l:key . ' - ' . substitute(l:value, '_', ' ', 'g')
  endfor
  return l:header . "\n\nPress Enter to continue"
endfunction

function! vimax#fzf#run(opts) abort
  "opts { mode, source, sink, header, ?prompt, ?bindings }
  let l:capital_mode = vimax#util#capitalize(g:vimax_mode)
  let l:options_prompt = l:capital_mode . ' ' . get(a:opts, 'prompt', 'list')
  let l:options_init = '+m --ansi --prompt="' . l:options_prompt . '> "'
  let l:bindings = has_key(a:opts, 'bindings') ? ' --expect="' . a:opts.bindings . '"' : ''
  let l:header = ' --header "' . l:capital_mode . ' '  . a:opts.header . '"'
  let l:options = l:options_init . l:bindings . l:header . ' --tiebreak=index'

  return fzf#run(extend({
    \ 'source': a:opts.source,
    \ 'sink*': a:opts.sink,
    \ 'options': l:options,
    \ }, g:vimax_fzf_layout))
endfunction

function! s:list_switch(binds, key) abort
  let l:switch = {
    \ a:binds.help: 'help',
    \ a:binds.go_to: 'vimax#go_to',
    \ a:binds.zoom: 'vimax#zoom',
    \ a:binds.inspect: 'vimax#inspect',
    \ a:binds.close: 'vimax#close',
    \ a:binds.prompt: 'vimax#prompt_command',
    \ a:binds.last: 'vimax#run_last_command',
    \ }
  return get(l:switch, a:key, v:null)
endfunction

function! vimax#fzf#default_list_sink(selections, ...) abort
  "type: (selections: List[str])
  if !len(a:selections)
    return v:null
  endif

  let l:binds = g:vimax_list_bindings
  let [ l:key, l:item; l:rest ] = a:selections
  let l:picked = call('vimax#' . g:vimax_mode . '#format_address_from_fzf_item', [l:item])
  let l:func = s:list_switch(l:binds, l:key)
  if l:func is v:null
    call vimax#set_last_address(l:picked)
  elseif l:func ==# 'help' 
    call input(vimax#fzf#help(l:binds, 'List'))
    "restart list if was help command
    "TODO: check functionality when coming from history and hitting help for list
    "might need more args
    call vimax#list()
    call vimax#fzf#nvim_insert_fix()
  else
    return call(l:func, [l:picked])
  endif
endfunction

function! vimax#fzf#default_history_source(...) abort
  let l:lines = system('tail -'  . g:vimax_limit_history . ' ' . g:vimax_history_file)
  let l:reverse_split_lines = reverse(split(l:lines, '\n'))
  if g:vimax_history_file =~? 'zsh'
    return map(l:reverse_split_lines, "substitute(v:val, ': \\d*:\\d;', '', '')")
  else
    return l:reverse_split_lines
  endif
endfunction

function! vimax#fzf#list_from_history_sink(extra, selections) abort
  "type: (selections: List[str])
  if !len(a:selections)
    return v:null
  endif

  let [ l:key, l:item; l:rest ] = a:selections
  let l:picked = call('vimax#' . g:vimax_mode . '#format_address_from_fzf_item', [l:item])

  if !(l:picked is v:null)

    call vimax#set_last_address(l:picked)
    if a:extra.binding ==# 'change_target'
      call vimax#history(l:picked)
      return vimax#fzf#nvim_insert_fix()
    else
      call vimax#run_command(a:extra.command, l:picked)
    endif
  endif

  call vimax#history(a:extra.original_address)
  return vimax#fzf#nvim_insert_fix()
endfunction

"basically forces startinsert, which isn't working in a second fzf instance
"for some reason or other
function! vimax#fzf#nvim_insert_fix() abort
  if has('nvim')
    call feedkeys('A', 'n')
  endif
endfunction

"fzf sink. handles keybindings
function! vimax#fzf#default_history_sink(address, selections, ...) abort
  if !len(a:selections)
    return
  endif

  let l:binds = g:vimax_history_bindings
  let [ l:key, l:item; l:rest ] = a:selections
  "TODO: get new address from sub commands (list etc)

  if index(values(l:binds), l:key) >= 0
    if l:key == l:binds.change_target
      let l:extra = {
        \ 'binding': 'change_target',
        \ 'original_address': a:address,
        \ 'command': l:item,
        \ }
      let l:Func = function('vimax#fzf#list_from_history_sink', [l:extra])
      call vimax#list('Change Target Address for History', l:Func)
      return vimax#fzf#nvim_insert_fix()
    elseif l:key == l:binds.help
      call input(vimax#fzf#help(l:binds, 'History'))
    elseif l:key == l:binds.run_at_address
      call vimax#run_command(l:item, a:address)
    elseif l:key == l:binds.alt_run_at_address
      let l:extra = {
        \ 'binding': 'run_at_address',
        \ 'original_address': a:address,
        \ 'command': l:item,
        \ }
      let l:Func = function('vimax#fzf#list_from_history_sink', [l:extra])
      call vimax#list('Run at Address', l:Func)
      return vimax#fzf#nvim_insert_fix()
    elseif l:key == l:binds.edit
      return vimax#scratch#append(l:item)
    elseif l:key == l:binds.alt_edit
      let l:extra = {
        \ 'binding': 'edit',
        \ 'original_address': a:address,
        \ 'command': l:item,
        \ }
      let l:Func = function('vimax#fzf#list_from_history_sink', [l:extra])
      call vimax#list('Run History Command at Address After Editing', l:Func)
      return vimax#fzf#nvim_insert_fix()
    endif

    call vimax#history(a:address)
    call vimax#fzf#nvim_insert_fix()
  elseif !empty(l:item)
    return vimax#run_command(l:item, a:address)
  endif
endfunction
