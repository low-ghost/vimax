""
" Resets private motion_opts to v:null's
function! s:reset_motion_opts() abort
  let s:motion_opts = {'mode': v:null, 'count': v:null}
endfunction

"Call to initially unset ops. Probably not needed
call s:reset_motion_opts()

""
" Adapted tpope's unimpaired.vim
function! vimax#motion#do_action(type, ...) abort
  let l:mode = get(a:, 1, s:motion_opts.mode)
  let l:count_maybe_0 = get(a:, 2, s:motion_opts.count)
  let l:count = l:count_maybe_0 == 0 ? v:null : l:count_maybe_0
  call s:reset_motion_opts()

  let l:sel_save = &selection
  let l:cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  let l:reg_save = @@

  if a:type ==# 'current_line'
    silent execute 'normal! V$y'
  elseif a:type =~# '^.$'
    silent execute 'normal! `<' . a:type . '`>y'
  elseif a:type ==# 'line'
    silent execute "normal! '[V']y"
  elseif a:type ==# 'block'
    silent execute 'normal! `[\<C-V>`]y'
  else
    silent execute 'normal! `[v`]y'
  endif

  let l:address = call('vimax#get_address', [l:mode, v:null, l:count])
  call vimax#set_last_address(l:mode, l:address)

  "TODO
  if (g:vimax_split_or_join_lines == 'split-it')
    call vimax#SendLines(@@, l:address)
  else
    let l:text = substitute(@@, '\n', "\<CR>", 'g')
    call call('vimax#call_mode_function', [{'mode': l:mode,
                                          \ 'name': 'send_text'},
                                          \ l:address, l:text])
  endif
  let s:last_range_type = a:type

  "TODO
  "silent! call repeat#set("\<Plug>Vimax...")

  let @@ = l:reg_save
  let &selection = l:sel_save
  let &clipboard = l:cb_save
endfunction

function! vimax#motion#action_setup(mode) abort
  "we can't prepare operatorfuncs, so carefully set script local and unset
  "it after use
  let s:motion_opts = {'mode': a:mode, 'count': v:count}
  setlocal operatorfunc=vimax#motion#do_action
endfunction

function! vimax#motion#send_last_region(mode) abort
  if !exists('s:last_range_type')
    echo 'no last vimax region to perform'
    return
  endif
  return vimax#motion#do_action(s:last_range_type, a:mode, v:count)
endfunction
