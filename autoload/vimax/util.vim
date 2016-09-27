"function! vimax#util#address_split_length(address)
  "let split_address = split(a:address, '\:\|\.')
  "return [ split_address, len(split_address) ]
"endfunction

function! s:get_address_from_vcount(vcount)
  "join a two or three digit count with a dot so that 10 refers to 1.0 or window 1,
  "pane 0. could also give 3 numbers to indicate session, window, pane
  let split_count = split(string(a:vcount), '\zs')
  let length_split = len(split_count)
  if length_split < 3
    return join(split_count, '.')
  endif
  let [ session; rest ] = split_count
  return session.':'.join(rest, '.')
endfunction

"TODO: check address existence
"uses 'none' string b/c of high possibility of 0 address
function! vimax#util#get_address(specified_address, ...)

  let prompt_string = "Tmux address 'session:win.pane', 'win.pane' or 'pane'> "
  let vcount = exists('a:1') ? a:1 : exists('v:count') && v:count != 0 ? v:count : 'none'
  if a:specified_address == 'prompt'
    return input(prompt_string)
  elseif a:specified_address != 'none'
    "directly pass address as the second argument
    return
      \ type(a:specified_address) == 1
      \ ? a:specified_address
      \ : string(a:specified_address)
  elseif vcount != 'none'
    return s:get_address_from_vcount(vcount)
  elseif exists('g:VimaxLastAddress')
    "use last address as the default
    return g:VimaxLastAddress
  else
    "if no specified, count or last address, prompt for input
    return input(prompt_string)
  endif
endfunction

function! vimax#util#escape(str, ...)
  let to_escape = exists('a:1') ? a:1.g:VimaxEscapeChars : g:VimaxEscapeChars
  return escape(a:str, to_escape)
endfunction

"function to return to last vim address, good for functions that need to be in
"the pane to execute but return to original vim. See VimaxScrollUpInspect
"and ...Down...
"function! vimax#util#return_to_last_vim_address()
  "let [ split_address, len_address ] =
    "\ vimax#util#address_split_length(g:VimaxLastVimAddress)
  "if len_address < 3
    "let [ window_address, pane_address ] = split_address
  "else
    "let [ session, window, pane_address ] = split_address
    "let window_address = session.':'.window
  "endif
  "call system('tmux select-window -t '
    "\ .window_address
    "\ .'; tmux select-pane -t '
    "\ .pane_address)
"endfunction

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

  if exists('s:vimax_motion_address') && s:vimax_motion_address != 'none'
    let address = s:vimax_motion_address
    let s:vimax_motion_address = 'none'
  else
    let address = vimax#util#get_address('none', vcount)
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

let g:VimaxScratchBufferName = "__VimaxScratch__"

"Scatch buffer functionality based on scratch.vim
"https://github.com/vim-scripts/scratch.vim
"by Yegappan Lakshmanan (yegappan AT yahoo DOT com)
"TODO: choose size/orientation
function! vimax#util#open_scratch()
  let bnum = bufnr(g:VimaxScratchBufferName)
  if bnum == -1
    exe "new " . g:VimaxScratchBufferName
  else
    let wnum = bufwinnr(bnum)
    if wnum != -1
      if winnr() != wnum
        exe wnum . "wincmd w"
      endif
    else
      "bring existing buffer into view
      exe "split +buffer" . bnum
    endif
  endif
endfunction

function! s:set_buffer_local_opts()
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal buflisted
endfunction

function! vimax#util#append_to_scratch(to_append)
  call vimax#util#open_scratch()
  let last_scratch_line = line('$')
  if last_scratch_line ==# 1 && !strlen(getline(1))
    " line is empty, we overwrite it
    call append(0, a:to_append)
    silent exe 'normal! Gdd$'
  else
    call append(last_scratch_line, a:to_append)
    silent exe 'normal! G$'
  endif
  " remove trailing white space
  silent! exe '%s/\s\+$/'
endfunction

autocmd BufNewFile __VimaxScratch__ call s:set_buffer_local_opts()
