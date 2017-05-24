""
" Creates commands and maps for a method, essentially
" >
"   command! -nargs=* VimaxMethod call vimax#method(v:null, <f-args>)
"   command! -nargs=* VimaxMode1Method call vimax#method('mode1', <f-args>)
" <
" ...for all modes
" >
"   nnoremap <unique> <Plug>Vimax#method :<C-U>call vimax#method(v:null)<CR>
"   nnoremap <unique> <Plug>Vimax#mode1#method
"     \ :<C-U>call vimax#method('mode1')<CR>
" <
" ...for all modes
" {method} str used for command, plug mapping and normal mode mapping itself
" {bind} str keys used to trigger command if user opts in to default mappings
function! vimax#init#register_method(method, bind) abort
  let l:capitaled_method = vimax#util#pascal_case(a:method)
  let l:function_name = 'vimax#' . a:method
  "Base plug passes v:null and will figure out mode based on v:vimax_mode
  execute 'nnoremap <unique> <Plug>Vimax#' . a:method
    \ . ' :<C-U>call ' . l:function_name . '(v:null)<CR>'
  "Add map itself if user has opted in to defaults
  if get(g:, 'vimax_default_mappings') == 1
    execute 'nmap <silent> ' . g:vimax_leader . a:bind . ' <Plug>Vimax#'
      \ . a:method
  endif
  for l:mode in g:vimax_all_modes
    let l:command_name = vimax#util#pascal_case(l:mode) . l:capitaled_method
    let l:plug_name = 'Vimax#' . l:mode . '#' . a:method
    let l:mode_arg = "'" . l:mode . "'"
    execute 'command! -nargs=* Vimax' . l:command_name
      \ . ' call ' . l:function_name . '(' . l:mode_arg . ', <f-args>)'
    execute 'nnoremap <unique> <Plug>' . l:plug_name .
      \ ' :<C-U>call ' . l:function_name . '(' . l:mode_arg . ')<CR>'
  endfor
endfunction

function! vimax#init#register_motions() abort
  for l:mode in [v:null] + g:vimax_all_modes
    let l:prefix = l:mode is v:null ? '' : l:mode . '#'
    let l:mode_arg = l:mode is v:null ? 'v:null' : "'" . l:mode . "'"
    execute 'nnoremap <unique> <Plug>Vimax#' . l:prefix . 'motion'
      \ . ' :<C-U>call vimax#motion#action_setup(' . l:mode_arg . ')<CR>g@'
    execute 'xnoremap <unique> <Plug>Vimax#' . l:prefix . 'motion'
      \ . ' :<C-U>call vimax#motion#do_action(visualmode(), ' . l:mode_arg . ')<CR>'
    execute 'nnoremap <unique> <Plug>Vimax#' . l:prefix . 'motion#current_line'
      \ . " :<C-U>call vimax#motion#do_action('current_line', " .  l:mode_arg
      \ . ')<CR>'

    execute 'nnoremap <unique> <Plug>Vimax#' . l:prefix . 'motion#last_region'
      \ . ' :<C-U>call vimax#motion#send_last_region(' . l:mode_arg . ')<CR>'
    "Base command created in plugin/vimax.vim for documentation purposes
    if (l:mode is v:null)
      continue
    endif
    execute 'command Vimax' . vimax#util#pascal_case(l:mode) . 'SendLastRegion'
      \ . ' call vimax#motion#send_last_region(' . l:mode . ')'
    execute 'command Vimax' . vimax#util#pascal_case(l:mode) . 'SendCurrentLine'
      \ . " call vimax#motion#do_action('current_line', " . l:mode_arg . ')'
  endfor
endfunction

