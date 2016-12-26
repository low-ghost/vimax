function! vimax#util#is_non_empty_list(list)
  return type(a:list) == type([]) && !empty(a:list)
endfunction

"Escape and replace chars
function! vimax#util#escape(str, ...)
  "Append argument to existing escape chars, if provided
  let to_escape = a:0 > 0 ? a:1 . g:VimaxEscapeChars : g:VimaxEscapeChars
  let final_str = escape(a:str, g:VimaxEscapeChars)
  for item in g:VimaxReplace
    let final_str = substitute(final_str, item[0], item[1], "")
  endfor
  return final_str
endfunction

"get an address from the format used in vimax#List
function vimax#util#nvim_insert_fix()
  if has('nvim')
    call feedkeys('A', 'n')
  endif
endfunction

"set VimaxLastAddress if the selection is not empty
function! vimax#util#set_last_address(picked)
  if !empty(a:picked)
    let g:VimaxLastAddress = vimax#util#get_address_from_list_item(a:picked)
    return g:VimaxLastAddress
  else
    return g:vimax#none
  endif
endfunction

" Adapted tpope's unimpaired.vim
function! vimax#util#do_action(type)
  let vcount = v:count
  let sel_save = &selection
  let cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  let reg_save = @@

  if a:type == 'current_line'
    silent exe 'normal! V$y'
  elseif a:type =~ '^.$'
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]y"
  else
    silent exe "normal! `[v`]y"
  endif

  if exists('s:vimax_motion_address') && s:vimax_motion_address != g:vimax#none
    let address = s:vimax_motion_address
    let s:vimax_motion_address = g:vimax#none
  else
    let address = vimax#util#get_address(g:vimax#none, vcount)
  endif
  let g:VimaxLastAddress = address

  if (g:VimaxSplitOrJoinLines == 'split')
    call vimax#SendLines(@@, address)
  else
    call vimax#SendText(substitute(@@, "\n", "", "g"), address)
    call vimax#SendKeys('Enter', address)
  endif
  let s:last_range_type = a:type
  "TODO
  "silent! call repeat#set("\<Plug>Vimax...")

  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! vimax#util#action_setup()
  "just added
  if exists('v:count') && v:count != 0
    let s:vimax_motion_address = s:get_address_from_vcount(v:count)
  endif
  setlocal opfunc=vimax#util#do_action
endfunction

function! vimax#util#MotionSendLastRegion()
  if !exists('s:last_range_type')
    echo 'no last vimax region to perform'
    return
  endif
  return vimax#util#do_action(s:last_range_type)
endfunction
