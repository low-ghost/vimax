if exists('g:vimax_loaded') || &cp
  finish
endif

"fuzzy buffer preference. fzf and tlib are (will be) supported. if none,
"simple vim 'echo's are used
if !exists('g:loaded_tlib') || g:loaded_tlib < 11
  runtime plugin/02tlib.vim
  let g:VimaxFuzzyBuffer = (!exists('g:loaded_tlib') || g:loaded_tlib < 11) ? 'none' : 'tlib'
else
  let g:VimaxFuzzyBuffer = 'tlib'
endif

let g:vimax_loaded = 1

"limit the size of shell history loaded into list
if !exists('g:VimaxLimitHistory')
  let g:VimaxLimitHistory = 25
endif

"location of shell history file
if !exists('g:VimaxHistoryFile')
  let g:VimaxHistoryFile = $HOME.'/.bash_history'
endif

"string presented when prompting for a command
if !exists('g:VimaxPromptString')
  let g:VimaxPromptString = 'Command? '
endif

"sequence of keys sent to Tmux to exit copy-mode
if !exists('g:VimaxResetSequence')
  let g:VimaxResetSequence = 'q C-u'
endif

"command dictionary with Tmux addresses as keys, string commands as props
if !exists('g:VimaxLastCommandDict')
  let g:VimaxLastCommandDict = {}
endif

"mappings which accept a count to specify the window and pane
"one digit is pane only e.g. 1<mapping> is an action for pane 1
"two digits is window, pane e.g. 12<mapping> is an action for window 1, pane 2
nnoremap <unique> <Plug>VimaxPromptCommand :<C-U>call vimax#PromptCommand()<CR>
nnoremap <unique> <Plug>VimaxRunLastCommand :<C-U>call vimax#RunLastCommand()<CR>
nnoremap <unique> <Plug>VimaxInspectAddress :<C-U>call vimax#InspectAddress()<CR>
nnoremap <unique> <Plug>VimaxClearAddressHistory :<C-U>call vimax#ClearAddressHistory()<CR>
nnoremap <unique> <Plug>VimaxInterruptAddress :<C-U>call vimax#InterruptAddress()<CR>
nnoremap <unique> <Plug>VimaxZoomAddress :<C-U>call vimax#ZoomAddress()<CR>
nnoremap <unique> <Plug>VimaxGoToAddress :<C-U>call vimax#GoToAddress()<CR>
nnoremap <unique> <Plug>VimaxScrollUpInspect :<C-U>call vimax#ScrollUpInspect()<CR>
nnoremap <unique> <Plug>VimaxScrollDownInspect :<C-U>call vimax#ScrollDownInspect()<CR>
nnoremap <unique> <Plug>VimaxCloseAddress :<C-U>call vimax#CloseAddress()<CR>
nnoremap <unique> <Plug>VimaxHistory :<C-U>call vimax#History()<CR>
nnoremap <unique> <Plug>VimaxList :call vimax#List()<CR>

"commands which accept args
command -nargs=* VimaxPromptCommand call vimax#PromptCommand(<f-args>)
command -nargs=* VimaxRunLastCommand call vimax#RunLastCommand(<f-args>)
command -nargs=* VimaxInspectAddress call vimax#InspectAddress(<f-args>)
command -nargs=* VimaxClearAddressHistory call vimax#ClearAddressHistory(<f-args>)
command -nargs=* VimaxInterruptAddress call vimax#InterruptAddress(<f-args>)
command -nargs=* VimaxZoomAddress call vimax#ZoomAddress(<f-args>)
command -nargs=* VimaxGoToAddress call vimax#GoToAddress(<f-args>)
command -nargs=* VimaxScrollUpInspect call vimax#ScrollUpInspect(<f-args>)
command -nargs=* VimaxScrollDownInspect call vimax#ScrollDownInspect(<f-args>)
command -nargs=* VimaxCloseAddress call vimax#CloseAddress(<f-args>)
command -nargs=* VimaxHistory call vimax#History(<f-args>)
command VimaxList call vimax#List()

"example mappings
"nmap ,vp <Plug>VimaxPromptCommand
"nmap ,vl <Plug>VimaxRunLastCommand
"nmap ,vi <Plug>VimaxInspectAddress
"nmap ,vc <Plug>VimaxClearAddressHistory
"nmap ,vx <Plug>VimaxInterruptAddress
"nmap ,vz <Plug>VimaxZoomAddress
"nmap ,vg <Plug>VimaxGoToAddress
"nmap ,vk <Plug>VimaxScrollUpInspect
"nmap ,vj <Plug>VimaxScrollDownInspect
"nmap ,vq <Plug>VimaxCloseAddress
