""
" Check if argument is a non-empty list.
"
" @public
" {list} List
" returns bool
function! vimax#util#is_non_empty_list(list) abort
  return type(a:list) == type([]) && !empty(a:list)
endfunction

""
" Capitalize first letter of a word.
"
" @public
" {text} str
" returns str
function! vimax#util#capitalize(text) abort
  return toupper(a:text[0]) . a:text[1:]
endfunction

""
" Converts snake case to pascal case.
"
" @public
" {text} str
" returns str
function! vimax#util#pascal_case(text) abort
  return join(map(split(a:text, '_'), 'vimax#util#capitalize(v:val)'), '')
endfunction

""
" Escape and replace chars via @setting(vimax_escape_chars) and
" @setting(vimax_replace). Accepts 2 additional args to add to escape and
" replace, respectfully.
"
" @public
" {str} str
" [additional_escape] str
" [additional_replace] str
function! vimax#util#escape(str, ...) abort
  "Append argument to existing escape chars, if provided
  let l:additional_escape = get(a:, '1', v:null)
  let l:additional_replace = get(a:, '2', v:null)
  let l:to_escape = l:additional_escape is v:null
    \ ? g:vimax_escape_chars
    \ : l:additional_escape . g:vimax_escape_chars
  let l:to_replace = l:additional_replace is v:null
    \ ? g:vimax_replace_chars
    \ : l:additional_replace . g:vimax_replace

  let l:final_str = escape(a:str, g:vimax_escape_chars)
  for l:item in g:vimax_replace
    let l:final_str = substitute(l:final_str, l:item[0], l:item[1], '')
  endfor
  return l:final_str
endfunction

""
" Echo with warning
"
" @public
" {msg} str
" returns str
function! vimax#util#warn(msg) abort
  echohl WarningMsg
  echo '[vimax] ' . a:msg
  echohl None
endfunction

""
" Safe to string function
"
" @public
" {val} any
" returns str
function! vimax#util#to_str(val) abort
  return type(a:val) == type('') ? a:val : string(a:val)
endfunction
