function! vimax#util#address_split_length(address)
  let split_address = split(a:address, '\.')
  return [ split_address, len(split_address) ]
endfunction

"TODO: check address existence
"uses 'none' string b/c of high possibility of 0 address
function! vimax#util#get_address(specified_address)

  let prompt_string = "Tmux address as session:window.pane> "
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

"function to return to last vim address, good for functions that need to be in
"the pane to execute but return to original vim. See VimaxScrollUpInspect
"and ...Down...
function! vimax#util#return_to_last_vim_address()
  let [ split_address, len_address ] =
    \ vimax#util#address_split_length(g:VimaxLastVimAddress)
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

"get an address from the format used in vimax#List
function! vimax#util#get_address_from_list_item(item)
  let [ _, session, window, pane; rest ] =
    \ matchlist(a:item, '\(\w\+\):.*-\(\w\+\).\(\w\+\)')
  return session.':'.window.'.'.pane
endfunction

"set VimaxLastAddress if the selection is not empty
function! vimax#util#set_last_address(picked)
  if !empty(a:picked)
    let g:VimaxLastAddress = vimax#util#get_address_from_list_item(a:picked)
    return g:VimaxLastAddress
  else
    return 'none'
  endif
endfunction

" Adapted tpope's unimpaired.vim
function! vimax#util#do_action(type)
  let sel_save = &selection
  let cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  let reg_save = @@

  if a:type =~ '^.$'
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]y"
  else
    silent exe "normal! `[v`]y"
  endif

  if exists('s:vimax_motion_address') && s:vimax_motion_address != 'none'
    let address = s:vimax_motion_address
    let s:vimax_motion_address = 'none'
  else
    let address = vimax#util#get_address('none')
  endif

  call vimax#RunCommand(@@, address)

  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! vimax#util#action_setup()
  let s:vimax_motion_address = vimax#util#get_address('none')
  setlocal opfunc=vimax#util#do_action
endfunction
