"Scatch buffer functionality based on scratch.vim
"https://github.com/vim-scripts/scratch.vim
"by Yegappan Lakshmanan (yegappan AT yahoo DOT com)

let g:VimaxScratchBufferName = "__VimaxScratch__"

"TODO: choose size/orientation
function! vimax#scratch#open_scratch()
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

function! vimax#scratch#close_scratch()
  let bnum = bufnr(g:VimaxScratchBufferName)
  if bnum == -1
    echo "No scratch open"
  else
    exe "bd " . bnum
  endif
endfunction

function! s:set_buffer_local_opts()
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal buflisted
endfunction

function! vimax#scratch#append_to_scratch(to_append)
  call vimax#scratch#open_scratch()
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
