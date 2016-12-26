function! vimax#nvim#au#add_to_buffer_list()
  let job_id = get(b:, 'terminal_job_id')
  if job_id
    let buffer_num = bufnr('')
    let g:vimax#nvim#buffers[buffer_num] = job_id
  endif
endfunction

function! vimax#nvim#au#remove_from_buffer_list()
  "Note: bufnr('') does not work, needs expand('<abuf>') to get correct
  "deleted buffer
  let buffer_num = expand('<abuf>')
  unlet g:vimax#nvim#buffers[buffer_num]
endfunction

