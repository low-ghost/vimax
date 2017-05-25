function! vimax#nvim#au#add_to_buffer_list() abort
  let l:job_id = get(b:, 'terminal_job_id', v:null)
  if !(l:job_id is v:null)
    let l:buffer_num = bufnr('')
    let g:vimax_nvim_buffers['buffer'][l:buffer_num] = l:job_id
    let g:vimax_nvim_buffers['job'][l:job_id] = l:buffer_num
  endif
endfunction

function! vimax#nvim#au#remove_from_buffer_list() abort
  "Note: bufnr('') does not work, needs expand('<abuf>') to get correct
  "deleted buffer
  let l:buffer_num = expand('<abuf>')
  let l:job_id = g:vimax_nvim_buffers['buffer'][l:buffer_num]
  unlet g:vimax_nvim_buffers['buffer'][l:buffer_num]
  unlet g:vimax_nvim_buffers['job'][l:job_id]
endfunction

