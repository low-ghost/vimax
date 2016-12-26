if exists('g:vimax_loaded') || &cp
  finish
endif
let g:vimax_loaded = 1

"Internal use, but you can use/abuse it if you really want to
let g:vimax#none = '__none__'

let g:vimax#leader = get(g:, 'vimax#leader', '<leader>v')

"Fuzzy buffer preference. At the moment, fzf only supported. If none,
"simple vim 'echo's are used
let g:VimaxFuzzyBuffer = get(g:, 'VimaxFuzzyBuffer', 'fzf')

"Limit the size of shell history loaded into list
let g:VimaxLimitHistory = get(g:, 'VimaxLimitHistory', 5000)

"Location of shell history file
let g:VimaxHistoryFile = get(g:, 'VimaxHistoryFile', $HOME.'/.bash_history')

"String presented when prompting for a command
let g:VimaxPromptString = get(g:, 'VimaxPromptString', 'Command? ')

let g:VimaxSplitOrJoinLines = get(g:, 'VimaxSplitOrJoinLines', 'split')

"Command dictionary with Tmux addresses as keys, string commands as props
let g:VimaxLastCommandDict = get(g:, 'VimaxLastCommandDict', {})

let g:VimaxOrientation = get(g:, 'VimaxOrientation', 'h')

let g:VimaxSize = get(g:, 'VimaxSize', 10)

"Always escape these characters. Can be changed at runtime. For instance, to
"always change 'ls; ls -a' to 'ls\; ls \-a' for whatever reason, type
": let VimaxEscapeChars = ';-'
let g:VimaxEscapeChars = get(g:, 'VimaxEscapeChars', '')

"Array of arrays containing [ pattern-to-find, replacement ]. For instance
":let g:VimaxReplace = [ [ 'es.', 'hat' ] ];
":VimaxPrompt test
"will result in passing 'that' to the target rather than 'test'
let g:VimaxReplace = get(g:, 'VimaxReplace', [])

"Single characters to bind ctrl-<char> to action
"run_at_address and edit also have parallel alt bindings
let g:VimaxHistoryBindings = extend({
 \ 'change_target': 't',
 \ 'run_at_address': 'r',
 \ 'edit': 'e',
 \ 'help': 'h',
 \ }, copy(get(g:, 'VimaxHistoryBindings', {})))

"Single characters to bind ctrl-<char> to action
let g:vimax#list_bindings = extend({
 \ 'help': 'h',
 \ 'go_to': 'g',
 \ 'zoom': 'z',
 \ 'inspect': 'i',
 \ 'close': 'q',
 \ 'prompt': 'p',
 \ 'last': 'l',
 \ }, copy(get(g:, 'vimax#list_bindings', {})))

"Fzf layout options
let g:VimaxFzfLayout = get(g:, 'VimaxFzfLayout', get(g:, 'fzf_layout', {'down': '~40%'}))

let g:VimaxScrollUpSequence = "\<C-u>"
let g:VimaxScrollDownSequence = "\<C-d>"

"Initial nvim buffers dict of {[buffer_id]: job_id}. You almost certainly won't need
"to mess with this
"TODO: allow extensions
let g:vimax#nvim#buffers = {}
let g:vimax#all_modes = ['tmux', 'nvim']
let g:vimax#mode = 'tmux'
let g:vimax#last_address = {}
let g:vimax#last_command_dict = {}
for m in g:vimax#all_modes
  let g:vimax#last_command_dict[m] = {}
endfor

let g:vimax#tmux#address_format = "'sess:win.pane', 'win.pane' or 'pane'"

augroup vimax#nvim
  "Adds to and removes from g:vimax#nvim#buffers on any terminal open or close
  au!
  au TermOpen * call vimax#nvim#au#add_to_buffer_list()
  au TermClose * call vimax#nvim#au#remove_from_buffer_list()
augroup END

function! s:pascal_case(text)
  "str -> str
  "Converts snake case to pascal case
  return substitute(a:text, '\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)', '\u\1\2', 'g')
endfunction

function! s:register_method(method, keybind)
  "creates commands and maps for a method
  "essentially
  "command! -nargs=* VimaxMethod call vimax#method(v:null, <f-args>)
  "command! -nargs=* VimaxMode1Method call vimax#method('mode1', <f-args>)
  "...for all modes
  "nnoremap <unique> <Plug>Vimax#method :<C-U>call vimax#method(v:null)
  "nnoremap <unique> <Plug>Vimax#mode1#method :<C-U>call vimax#method('mode1')
  "...for all modes
  let capitaled_method = s:pascal_case(a:method)
  let function_name = 'vimax#' . a:method
  for m in [''] + g:vimax#all_modes
    "will be empty for ''
    let command_name = s:pascal_case(m) . capitaled_method
    let no_mode = empty(m)
    let plug_name = no_mode
      \ ? 'Vimax#' . a:method
      \ : 'Vimax#' . m . '#' . a:method
    let mode_arg = no_mode ? 'v:null' : "'" . m . "'"
    execute 'command! -nargs=* Vimax' . command_name
      \ . ' call ' . function_name . '(' . mode_arg . ', <f-args>)'
    execute 'nnoremap <unique> <Plug>' . plug_name .
      \ ' :<C-U>call ' . function_name . '(' . mode_arg . ')<CR>'
  endfor
  "if exists('g:VimaxDefaultMappings')
    execute 'nmap ' g:vimax#leader . a:keybind . ' <Plug>Vimax#' . a:method
  "endif
endfunction

call s:register_method('clear_history',    'c')
call s:register_method('run_in_dir',       'd')
call s:register_method('go_to',            'g')
call s:register_method('inspect',          'i')
call s:register_method('scroll_down',      'j')
call s:register_method('scroll_up',        'k')
call s:register_method('run_last_command', 'l')
call s:register_method('prompt_command',   'p')
call s:register_method('close',            'q')
call s:register_method('run_at_git_root',  'r')
call s:register_method('interrupt',        'x')
call s:register_method('zoom',             'z')

"mappings which accept a count to specify the window and pane
"one digit is pane only e.g. 1<mapping> is an action for pane 1
"two digits is window, pane e.g. 12<mapping> is an action for window 1, pane 2
nnoremap <unique> <Plug>VimaxHistory              :<C-U>call vimax#History()<CR>
nnoremap <unique> <Plug>VimaxList                 :call vimax#List()<CR>
"TODO not working if no count and no last
nnoremap <silent> <Plug>VimaxMotion               :<C-U>call vimax#util#action_setup()<CR>g@
xnoremap <silent> <Plug>VimaxMotion               :<C-U>call vimax#util#do_action(visualmode())<CR>
nnoremap <silent> <Plug>VimaxMotionCurrentLine    :<C-U>call vimax#util#do_action('current_line')<CR>
nnoremap <silent> <Plug>VimaxMotionSendLastRegion :<C-U>call vimax#util#MotionSendLastRegion()<CR>

nnoremap <silent> <Plug>VimaxOpenScratch          :<C-U>call vimax#scratch#open_scratch()<CR>
nnoremap <silent> <Plug>VimaxCloseScratch         :<C-U>call vimax#scratch#close_scratch()<CR>
nnoremap <silent> <Plug>Vimax#switch_mode         :<C-U>call vimax#switch_mode()<CR>

"commands which accept args
command -nargs=* VimaxHistory             call vimax#History(<f-args>)
"command -nargs=* VimaxRunCommand          call vimax#RunCommand(<f-args>)
command VimaxMotionSendLastRegion         call vimax#util#MotionSendLastRegion()
command VimaxList                         call vimax#List()

command VimaxOpenScratch                  call vimax#scratch#open_scratch()
command VimaxCloseScratch                 call vimax#scratch#close_scratch()
command VimaxSwitchMode                   call vimax#switch_mode()

"default mappings
"if exists('g:VimaxDefaultMappings')
  nmap <leader>va <Plug>VimaxList
  nmap <leader>vh <Plug>VimaxHistory
  nmap <leader>vs <Plug>VimaxMotion
  nmap <leader>vss <Plug>VimaxMotionCurrentLine
  xmap <leader>vs <Plug>VimaxMotion
  nmap <leader>vs. <Plug>VimaxMotionSendLastRegion

  nmap <leader>vbo <Plug>VimaxOpenScratch
  nmap <leader>vbc <Plug>VimaxCloseScratch
  nmap <leader>vt <Plug>Vimax#switch_mode
"endif

"Vimux plugin compatibility
function! VimuxRunCommand(command, ...)
  let address = vimax#util#get_address(g:vimax#none)
  vimax#RunCommand(a:command, address, get(a:, '1', 0))
endfunction

function! VimuxRunLastCommand()
  let address = vimax#util#get_address(g:vimax#none)
  vimax#RunCommand(a:command, address, get(a:, '1', 0))
endfunction
