let g:vimax_nvim_last_command_dict = get(g:, 'vimax#nvim#last_command_dict', {})

""
" Get job id and buffer num from an order argument, the count or argument
" specifying nth nvim target
"
" @private
" {order_arg} str
" returns {Tuple[int, int]}
function! s:get_info_for_address(order_arg) abort
  let l:buffer_num = get(keys(g:vimax#nvim#buffers), a:order_arg - 1)
  let l:job_id = g:vimax_nvim_buffers[l:buffer_num]
  return [l:job_id, l:buffer_num]
endfunction

""
" Get address from count
"
"@public
"{count} int
"returns {int} buffer
function! vimax#nvim#format_address_from_vcount(count) abort
  return s:get_info_for_address(a:count)[0]
endfunction

""
" Get address from count
"
"@public
"{arg} str
"returns {int} buffer
function! vimax#nvim#format_address_from_arg(arg) abort
  return s:get_info_for_address(a:arg)[0]
endfunction

function! vimax#nvim#format_address_from_fzf_item(item) abort
  "TODO
  return string(a:item)
endfunction

function! vimax#nvim#send_keys(job_id, keys) abort
  silent! call jobsend(a:job_id, a:keys)
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

function! s:go_to(address_arg, cb, return)
  let buffer_num = vimax#nvim#get_info_from_args(a:address_arg)[1]
  let previous_location = [ winnr(), bufnr('%') ]
  if buffer_num
    call vimax#buffer#go_to(buffer_num)
    return a:cb is v:null ? 0 : a:cb()
  else
    echo 'No terminal exists at that address'
  endif
  if !(a:return is v:null)
    call s:return_to_previous_location(previous_location)
  endif
endfunction

function! s:start_insert()
  "With exclamation!
  silent! startinsert!
endfunction

function! vimax#nvim#go_to(...)
  return s:go_to(a:000, function('s:start_insert'), v:null)
endfunction

function! vimax#nvim#inspect(...)
  return s:go_to(a:000, v:null, v:null)
endfunction

function! s:return_to_previous_location(previous_location)
  silent! execute a:previous_location[0] . "wincmd w"
  silent! execute 'b ' . a:previous_location[1]
endfunction

function! s:scroll_and_return(up, previous_location)
  let sequence = a:up is v:true ? g:VimaxScrollUpSequence : g:VimaxScrollDownSequence
  execute 'normal! ' . sequence
endfunction

function! vimax#nvim#scroll_up(...)
  let up = v:true
  call s:go_to(a:000, function('s:scroll_and_return', [ up ]), v:true)
endfunction

function! vimax#nvim#scroll_down(...)
  let down = v:false
  call s:go_to(a:000, function('s:scroll_and_return', [ down ]), v:true)
endfunction

function! vimax#nvim#send_text(job_id, text)
  let escaped = vimax#util#escape(a:text)
  call vimax#nvim#send_keys(a:job_id, escaped)
endfunction

function! vimax#nvim#interrupt(...)
  let job_id = vimax#nvim#get_info_from_args(a:000)[2]
  return vimax#nvim#send_keys(job_id, "\<C-c>")
endfunction

function! vimax#nvim#run_command(command, ...)
  "duplicating a little bit of logic later with get_job_id_from_args...
  let [ address, _, job_id ] = vimax#nvim#get_info_from_args(a:000)
  if empty(address)
    echo 'No address specified'
    return 0
  endif
  let send_direct_text = get(a:, '2')
  "save to global last command, last address and a dict of key=last address
  "value=last command
  let g:vimax#nvim#last_address = address
  let g:vimax#nvim#last_command_dict[address] = a:command
  call vimax#nvim#send_text(job_id, a:command)
  if !send_direct_text
    call vimax#nvim#send_keys(job_id, "\<cr>")
  endif
endfunction

function! vimax#nvim#prompt_command(...)
  let command = input(g:VimaxPromptString)
  if empty(command)
    echo 'No command specified'
  else
    call vimax#nvim#run_command(command, get(a:, '1', v:null))
  endif
endfunction

function! vimax#nvim#close(...)
  let buffer_num = vimax#nvim#get_info_from_args(a:000)[1]
  execute "bd! " . buffer_num
endfunction

function! vimax#nvim#zoom(...)
  call s:go_to(a:000, function('vimax#buffer#zoom_toggle'), v:null)
endfunction

function! vimax#nvim#run_last_command(...)
   let address = vimax#nvim#get_info_from_args(a:000)[0]
   let command = get(g:vimax#nvim#last_command, address, 'Up')
   call call("vimax#nvim#run_command", [command] + a:000)
endfunction
