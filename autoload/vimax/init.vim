""
" Creates commands and maps for a method, essentially
" >
"   command! -nargs=* VimaxMethod call vimax#method(v:null, <f-args>)
"   nnoremap <unique> <Plug>Vimax#method :<C-U>call vimax#method(v:null)<CR>
" <
" {method} str used for command, plug mapping and normal mode mapping itself
" {bind} str keys used to trigger command if user opts in to default mappings
function! vimax#init#register_method(method, bind) abort
  let l:capitaled_method = vimax#util#pascal_case(a:method)
  let l:function_name = 'vimax#' . a:method
  execute 'nnoremap <unique> <Plug>Vimax#' . a:method
    \ . ' :<C-U>call ' . l:function_name . '()<CR>'
  "Add map itself if user has opted in to defaults
  if get(g:, 'vimax_default_mappings') == 1
    execute 'nmap <silent> ' . g:vimax_leader . a:bind . ' <Plug>Vimax#'
      \ . a:method
  endif
endfunction

function! vimax#init#register_motions() abort
  execute 'nnoremap <unique> <Plug>Vimax#motion'
    \ . ' :<C-U>call vimax#motion#action_setup()<CR>g@'
  execute 'xnoremap <unique> <Plug>Vimax#motion'
    \ . ' :<C-U>call vimax#motion#do_action(visualmode())<CR>'
  execute 'nnoremap <unique> <Plug>Vimax#motion#current_line'
    \ . " :<C-U>call vimax#motion#do_action('current_line')<CR>'"
  execute 'nnoremap <unique> <Plug>Vimax#motion#last_region'
    \ . ' :<C-U>call vimax#motion#send_last_region()<CR>'
endfunction
