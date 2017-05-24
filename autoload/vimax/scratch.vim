"Scatch buffer functionality based on scratch.vim
"https://github.com/vim-scripts/scratch.vim
"by Yegappan Lakshmanan (yegappan AT yahoo DOT com)

let g:vimax_scratch_buffer_name = '__VimaxScratch__'

"TODO: choose size/orientation
function! vimax#scratch#open() abort
  let l:bnum = bufnr(g:vimax_scratch_buffer_name)
  if l:bnum == -1
    exe 'new ' . g:vimax_scratch_buffer_name
  else
    let l:wnum = bufwinnr(l:bnum)
    if l:wnum != -1
      if winnr() != l:wnum
        exe l:wnum . 'wincmd w'
      endif
    else
      "bring existing buffer into view
      exe 'split +buffer' . l:bnum
    endif
  endif
endfunction

function! vimax#scratch#close() abort
  let l:bnum = bufnr(g:vimax_scratch_buffer_name)
  if l:bnum == -1
    echo 'No scratch open'
  else
    execute 'bd ' . l:bnum
  endif
endfunction

function! s:set_buffer_local_opts() abort
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal buflisted
endfunction

function! vimax#scratch#append(to_append) abort
  call vimax#scratch#open()
  let l:last_scratch_line = line('$')
  if l:last_scratch_line ==# 1 && !strlen(getline(1))
    " line is empty, we overwrite it
    call append(0, a:to_append)
    silent execute 'normal! Gdd$'
  else
    call append(l:last_scratch_line, a:to_append)
    silent execute 'normal! G$'
  endif
  " remove trailing white space
  silent! execute '%s/\s\+$/'
endfunction

autocmd BufNewFile __VimaxScratch__ call s:set_buffer_local_opts()
