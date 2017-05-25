let g:vimax_nvim_last_command_dict = get(g:, 'vimax#nvim#last_command_dict', {})

function! s:return_to_previous_location(previous_location)
  silent! execute a:previous_location[0] . "wincmd w"
  silent! execute 'b ' . a:previous_location[1]
endfunction

function! s:go_to(job_id, cb, return)
  let l:buffer_num = get(g:vimax_nvim_buffers['job'], a:job_id, v:null)
  let l:to_return = !(a:return is v:null)

  if l:to_return
    let l:previous_location = [ winnr(), bufnr('%') ]
  endif

  if !(l:buffer_num is v:null)
    call vimax#buffer#go_to(l:buffer_num)
    if !(a:cb is v:null)
      call a:cb()
    endif
  else
    echo 'No terminal exists at that address'
    return v:null
  endif

  if l:to_return
    call s:return_to_previous_location(l:previous_location)
  endif
endfunction

""
" Get address from count
"
"@public
"{count} int
"returns {int} buffer
function! vimax#nvim#format_address_from_vcount(count) abort
  let l:buffer_num = get(keys(g:vimax_nvim_buffers['buffer']), a:count - 1)
  let l:job_id = get(g:vimax_nvim_buffers['buffer'], l:buffer_num, v:null)
  return l:job_id
endfunction

""
" Get address from arg (is just the arg itself for nvim, so must be the
" job_id)
"
"@public
"{arg} str
"returns {int} buffer
function! vimax#nvim#format_address_from_arg(arg) abort
  return a:arg
endfunction

function! vimax#nvim#format_address_from_fzf_item(item) abort
  "TODO
  return string(a:item)
endfunction

function! vimax#nvim#send_keys(job_id, keys) abort
  silent! call jobsend(a:job_id, a:keys)
endfunction

function! vimax#nvim#send_text(job_id, text) abort
  "send escaped text by calling VimaxSendKeys. Needs text and job_id explicitly
  let l:escaped = vimax#util#escape(a:text)
  call vimax#nvim#send_keys(a:job_id, l:escaped)
endfunction

function! vimax#nvim#send_return(job_id, ...) abort
  call vimax#nvim#send_keys(a:job_id, "\<cr>")
endfunction

function! vimax#nvim#close(job_id, ...) abort
  let l:buffer_num = g:vimax_nvim_buffers['job'][a:job_id]
  execute "bd! " . l:buffer_num
endfunction

function! vimax#nvim#zoom(job_id, ...) abort
  call s:go_to(a:job_id, function('vimax#buffer#zoom_toggle'), v:null)
endfunction

function! s:scroll(up) abort
  let l:sequence = a:up is v:true
    \ ? g:vimax_nvim_scroll_up_sequence
    \ : g:vimax_nvim_scroll_down_sequence
  execute 'normal! ' . l:sequence
endfunction

function! vimax#nvim#scroll_up(job_id, ...) abort
  let l:up = v:true
  call s:go_to(a:job_id, function('s:scroll', [ l:up ]), v:true)
endfunction

function! vimax#nvim#scroll_down(job_id, ...) abort
  let l:down = v:false
  call s:go_to(a:job_id, function('s:scroll', [ l:down ]), v:true)
endfunction

function! s:start_insert()
  "With exclamation!
  silent! startinsert!
endfunction

function! vimax#nvim#run_in_dir(path, command, ...) abort
  "TODO: path and return address
  let l:name = a:command ? fnameescape(a:command) : 'new_terminal'
  let l:win_id = win_getid()
  silent! execute 'sp ' . l:name
  silent! set ft=zsh
  silent! resize 10
  let l:job_id = termopen('zsh')
  if !empty(a:command)
    call vimax#nvim#send_keys(l:job_id, a:command . "\r")
    call win_gotoid(l:win_id)
  else
    startinsert!
  endif
endfunction

function! vimax#nvim#go_to(job_id, ...) abort
  return s:go_to(a:job_id, function('s:start_insert'), v:null)
endfunction

function! vimax#nvim#inspect(job_id, ...) abort
  return s:go_to(a:job_id, v:null, v:null)
endfunction

function! vimax#nvim#interrupt(job_ib, ...) abort
  return vimax#nvim#send_keys(a:job_id, "\<C-c>")
endfunction

function! vimax#nvim#send_command(job_id, command, send_direct_text) abort
  call vimax#nvim#send_text(a:job_id, a:command)
  if !a:send_direct_text
    call vimax#nvim#send_return(a:job_id)
  endif
endfunction
