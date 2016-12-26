let g:vimax#nvim#last_command_dict = get(g:, 'vimax#nvim#last_command_dict', {})

function! vimax#nvim#run_in_dir(path, command)
  "TODO: path
  let name = a:command ? fnameescape(a:command) : 'new_terminal'
  silent! execute 'sp ' . name
  silent! set ft=zsh
  silent! resize 10
  let job_id = termopen('zsh')
  if !empty(a:command)
    call vimax#nvim#send_keys(job_id, a:command . "\r")
  endif
  startinsert!
endfunction

function! vimax#nvim#get_address(specified_address, ...)
  let prompt_string = "nvim address> "
  let retrieved_arg = get(a:, '1')
  if retrieved_arg && !(retrieved_arg is v:null)
    let retrieved_count = retrieved_arg
  elseif exists('v:count') && v:count != 0
    let retrieved_count = v:count
  else
    let retrieved_count = v:null
  endif
  if vimax#util#is_non_empty_list(a:specified_address)
    let [address] = a:specified_address
    return address
  elseif !(retrieved_count is v:null)
    return retrieved_count
  elseif exists('g:vimax#nvim#last_address')
    "use last address as the default
    return g:vimax#nvim#last_address
  else
    "if no specified, count or last address, prompt for input
    return input(prompt_string)
  endif
endfunction

function! vimax#nvim#get_info_from_args(args)
  let address = vimax#nvim#get_address(a:args)
  let buffer_num = get(keys(g:vimax#nvim#buffers), address - 1)
  let job_id = g:vimax#nvim#buffers[buffer_num]
  return [ address, buffer_num, job_id ]
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

function! vimax#nvim#send_keys(job_id, keys)
  silent! call jobsend(a:job_id, a:keys)
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
