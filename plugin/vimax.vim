if exists('g:vimax_loaded') || &cp
  finish
endif

let g:vimax_loaded = 1

"fuzzy buffer preference. fzf and tlib are (will be) supported. if none,
"simple vim 'echo's are used
if !exists('g:VimaxFuzzyBuffer')
  if exists('g:loaded_tlib')
    let g:VimaxFuzzyBuffer = 'tlib'
  else
    let g:VimaxFuzzyBuffer = 'fzf'
  endif
endif

"limit the size of shell history loaded into list
if !exists('g:VimaxLimitHistory')
  let g:VimaxLimitHistory = 1000
endif

"location of shell history file
if !exists('g:VimaxHistoryFile')
  let g:VimaxHistoryFile = $HOME.'/.bash_history'
endif

"string presented when prompting for a command
if !exists('g:VimaxPromptString')
  let g:VimaxPromptString = 'Command? '
endif

if !exists('g:VimaxSplitOrJoinLines')
  let g:VimaxSplitOrJoinLines = 'split'
endif

"sequence of keys sent to Tmux to exit copy-mode
if !exists('g:VimaxResetSequence')
  let g:VimaxResetSequence = 'q C-u'
endif

"command dictionary with Tmux addresses as keys, string commands as props
if !exists('g:VimaxLastCommandDict')
  let g:VimaxLastCommandDict = {}
endif

if !exists('g:VimaxOrientation')
  let g:VimaxOrientation = 'v'
endif

if !exists('g:VimaxHeight')
  let g:VimaxHeight = 10
endif

"single characters to bind ctrl-<char> to action
"run_at_address and edit also have parallel alt bindings
if !exists('g:VimaxHistoryBindings')
  let g:VimaxHistoryBindings = {}
endif

let g:VimaxHistoryBindings = extend({
 \ 'change_target': 't',
 \ 'run_at_address': 'r',
 \ 'edit': 'e',
 \ 'help': 'h',
 \ }, copy(g:VimaxHistoryBindings))

if !exists('g:VimaxFzfLayout')
  let g:VimaxFzfLayout = exists('g:fzf_layout') ? g:fzf_layout : { 'down': '~40%' }
endif

"mappings which accept a count to specify the window and pane
"one digit is pane only e.g. 1<mapping> is an action for pane 1
"two digits is window, pane e.g. 12<mapping> is an action for window 1, pane 2
nnoremap <unique> <Plug>VimaxClearAddressHistory :<C-U>call vimax#ClearAddressHistory()<CR>
nnoremap <unique> <Plug>VimaxCloseAddress        :<C-U>call vimax#CloseAddress()<CR>
nnoremap <unique> <Plug>VimaxGoToAddress         :<C-U>call vimax#GoToAddress()<CR>
nnoremap <unique> <Plug>VimaxHistory             :<C-U>call vimax#History()<CR>
nnoremap <unique> <Plug>VimaxInspectAddress      :<C-U>call vimax#InspectAddress()<CR>
nnoremap <unique> <Plug>VimaxInterruptAddress    :<C-U>call vimax#InterruptAddress()<CR>
nnoremap <unique> <Plug>VimaxList                :call vimax#List()<CR>
nnoremap <unique> <Plug>VimaxPromptCommand       :<C-U>call vimax#PromptCommand()<CR>
nnoremap <unique> <Plug>VimaxRunLastCommand      :<C-U>call vimax#RunLastCommand()<CR>
nnoremap <unique> <Plug>VimaxRunCommandInDir     :<C-U>call vimax#RunCommandInDir()<CR>
nnoremap <unique> <Plug>VimaxRunCommandAtGitRoot :<C-U>call vimax#RunCommandAtGitRoot()<CR>
nnoremap <unique> <Plug>VimaxScrollDownInspect   :<C-U>call vimax#ScrollDownInspect()<CR>
nnoremap <unique> <Plug>VimaxScrollUpInspect     :<C-U>call vimax#ScrollUpInspect()<CR>
nnoremap <unique> <Plug>VimaxZoomAddress         :<C-U>call vimax#ZoomAddress()<CR>
nnoremap <unique> <Plug>VimaxExitInspect         :<C-U>call vimax#ExitInspect()<CR>
nnoremap <silent> <Plug>VimaxMotion              :<C-U>call vimax#util#action_setup()<CR>g@
xnoremap <silent> <Plug>VimaxMotion              :<C-U>call vimax#util#do_action(visualmode())<CR>
nnoremap <silent> <Plug>VimaxMotionCurrentLine   :<C-U>call vimax#util#do_action('current_line')<CR>g@

"commands which accept args
command -nargs=* VimaxClearAddressHistory call vimax#ClearAddressHistory(<f-args>)
command -nargs=* VimaxCloseAddress        call vimax#CloseAddress(<f-args>)
command -nargs=* VimaxGoToAddress         call vimax#GoToAddress(<f-args>)
command -nargs=* VimaxHistory             call vimax#History(<f-args>)
command -nargs=* VimaxInspectAddress      call vimax#InspectAddress(<f-args>)
command -nargs=* VimaxInterruptAddress    call vimax#InterruptAddress(<f-args>)
command -nargs=* VimaxPromptCommand       call vimax#PromptCommand(<f-args>)
command -nargs=* VimaxRunCommand          call vimax#RunCommand(<f-args>)
command -nargs=* VimaxRunCommandInDir     call vimax#RunCommandInDir(<f-args>)
command -nargs=* VimaxRunCommandAtGitRoot call vimax#RunCommandAtGitRoot(<f-args>)
command -nargs=* VimaxRunLastCommand      call vimax#RunLastCommand(<f-args>)
command -nargs=* VimaxScrollDownInspect   call vimax#ScrollDownInspect(<f-args>)
command -nargs=* VimaxScrollUpInspect     call vimax#ScrollUpInspect(<f-args>)
command -nargs=* VimaxZoomAddress         call vimax#ZoomAddress(<f-args>)
command -nargs=* VimaxExitInspect         call vimax#ExitInspect(<f-args>)
command VimaxList                         call vimax#List()

"default mappings
if exists('g:VimaxDefaultMappings')
  nmap <leader>va <Plug>VimaxList
  nmap <leader>vc <Plug>VimaxClearAddressHistory
  nmap <leader>vd <Plug>VimaxRunCommandInDir
  nmap <leader>vg <Plug>VimaxGoToAddress
  nmap <leader>vh <Plug>VimaxHistory
  nmap <leader>vi <Plug>VimaxInspectAddress
  nmap <leader>vj <Plug>VimaxScrollDownInspect
  nmap <leader>vk <Plug>VimaxScrollUpInspect
  nmap <leader>vl <Plug>VimaxRunLastCommand
  nmap <leader>vp <Plug>VimaxPromptCommand
  nmap <leader>vq <Plug>VimaxCloseAddress
  nmap <leader>vr <Plug>VimaxRunCommandAtGitRoot
  nmap <leader>vs <Plug>VimaxMotion
  nmap <leader>vss <Plug>VimaxMotionCurrentLine
  xmap <leader>vs <Plug>VimaxMotion
  nmap <leader>vx <Plug>VimaxInterruptAddress
  nmap <leader>vz <Plug>VimaxZoomAddress
endif
