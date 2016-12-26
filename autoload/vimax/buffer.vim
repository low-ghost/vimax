function! vimax#buffer#go_to(buffer_num)
  let win_num = bufwinnr(str2nr(a:buffer_num))
  let win_exists = win_num != -1
  if win_exists
    if winnr() != win_num
      execute win_num . 'wincmd w'
    endif
  else
    "bring existing buffer into view
    let direction_prefix = g:VimaxOrientation == 'v' ? 'v' : ''
    execute 'botright ' . g:VimaxSize . direction_prefix . 'split +buffer' . a:buffer_num
  endif
endfunction

function! vimax#buffer#zoom_toggle() abort
  if exists('t:zoomed') && t:zoomed
    execute t:zoom_winrestcmd
    let t:zoomed = 0
  else
    let t:zoom_winrestcmd = winrestcmd()
    resize
    vertical resize
    let t:zoomed = 1
  endif
endfunction
