if exists('g:vimax_loaded') || &compatible
  finish
endif
let g:vimax_loaded = 1

""
" Vimax leader sequence applied if g:vimax_default_mappings is set to 1.
" E.g. adding this to a .vimrc or init.vim:
" >
"   let g:vimax_default_mappings = 1
" <
" without setting g:vimax_leader will mean <leader>vp will trigger Vimax#prompt
" @default vimax_leader='<leader>v'
let g:vimax_leader = get(g:, 'vimax_leader', '<leader>v')

""
" Fuzzy buffer preference. At the moment, fzf only supported. If set to v:null,
" simple vim echo's are used
" @default vimax_fuzzy_buffer='fzf'
let g:vimax_fuzzy_buffer = get(g:, 'vimax_fuzzy_buffer', 'fzf')

""
" Limit the size of shell history loaded into list
" @default vimax_limit_history=5000
let g:vimax_limit_history = get(g:, 'vimax_limit_history', 5000)

""
" Location of shell history file
" @default vimax_history_file=$HOME . '/.bash_history'
let g:vimax_history_file = get(g:, 'vimax_history_file',
                               \ $HOME . '/.bash_history')

""
" String presented when prompting for a command
" @default vimax_prompt_string='Command? '
let g:vimax_prompt_string = get(g:, 'vimax_prompt_string', 'Command? ')

""
" Split or join lines when sending them to address
" @default vimax_split_or_join_lines='split'
let g:vimax_split_or_join_lines = get(g:, 'vimax_split_or_join_lines', 'split')

""
" Command dictionary with Tmux addresses as keys, string commands as props
" @default vimax_last_command_dict={}
let g:vimax_last_command_dict = get(g:, 'vimax_last_command_dict', {})

""
" Orientation preference for new targets. Horizontal by default. 'h' or 'v'
" @default vimax_orientation='h'
let g:vimax_orientation = get(g:, 'vimax_orientation', 'h')

""
" Size preference for new targets. Defaults to 10, which will likely be too
" small if choosing
" >
"   let g:vimax_orientation='v'
" <
" @default vimax_size=10
let g:vimax_size = get(g:, 'vimax_size', 10)

" Always escape these characters. Can be changed at runtime. For instance, to
" always change 'ls; ls -a' to 'ls\; ls \-a' for some reason, type
" >
"   :let VimaxEscapeChars = ';-'
" <
" @default vimax_escape_chars=''
let g:vimax_escape_chars = get(g:, 'vimax_escape_chars', '')

""
" Array of arrays containing [ pattern-to-find, replacement ]. For instance
" >
"   :let g:VimaxReplace = [ [ 'es.', 'hat' ] ];
"   :VimaxPrompt test
" <
" will result in passing 'that' to the target rather than 'test'
" @default vimax_replace=[]
let g:vimax_replace = get(g:, 'vimax_replace', [])

""
" @dict VimaxHistoryBindings
"   * change_target 'ctrl-t'
"   * run_at_address 'ctrl-r'
"   * alt_run_at_address 'alt-r'
"   * edit 'ctrl-e'
"   * alt_edit 'alt-e'
"   * help 'alt-h'

""
" Single characters to bind ctrl-<char> to action
" run_at_address and edit also have parallel alt bindings
" @default vimax_history_bindings=@dict(VimaxHistoryBindings)
let g:vimax_history_bindings = extend({
 \ 'change_target': 'ctrl-t',
 \ 'run_at_address': 'ctrl-r',
 \ 'alt_run_at_address': 'alt-r',
 \ 'edit': 'ctrl-e',
 \ 'alt_edit': 'alt-e',
 \ 'help': 'alt-h',
 \ }, copy(get(g:, 'vimax_history_bindings', {})))

""
" @dict VimaxListBindings
"  * help 'alt-h'
"  * go_to 'ctrl-g'
"  * zoom 'ctrl-z'
"  * inspect 'ctrl-i'
"  * close 'ctrl-q'
"  * prompt 'ctrl-p'
"  * last 'ctrl-l'

""
" Single characters to bind ctrl-<char> to action
" @default vimax_list_bindings=@dict(VimaxListBindings)
let g:vimax_list_bindings = extend({
 \ 'help': 'alt-h',
 \ 'go_to': 'ctrl-g',
 \ 'zoom': 'ctrl-z',
 \ 'inspect': 'ctrl-i',
 \ 'close': 'ctrl-q',
 \ 'prompt': 'ctrl-p',
 \ 'last': 'ctrl-l',
 \ }, copy(get(g:, 'vimax_list_bindings', {})))

""
" Fzf layout options
" @default vimax_fzf_layout=g:fzf_layout || {'down': '~40%'}
let g:vimax_fzf_layout = get(g:, 'vimax_fzf_layout',
                             \ get(g:, 'fzf_layout', {'down': '~40%'}))

""
" TODO: extension
let g:vimax_all_modes = get(g:, 'vimax_all_modes', [])

""
" Currently active vimax mode, dictating how all functions are handled.
" Built in modes are 'tmux' and 'nvim', but more modes may be added via plugins
" @default vimax_mode='tmux'
let g:vimax_mode = get(g:, 'vimax_mode', 'tmux')

""
" Dictionary containing {[mode: str]: str}, or one address per used mode
" @default vimax_last_address={}
let g:vimax_last_address = get(g:, 'vimax_last_address', {})

""
" Dictionary containing {[mode: str]: {[address: any]: str}, or an address
" to last command sub dictionary per mode
" @default vimax_last_command_dict={}
let g:vimax_last_command_dict = get(g:, 'vimax_last_command_dict', {})

function s:build_mode_vars()
  for l:mode in g:vimax_all_modes
    let g:vimax_last_command_dict[l:mode] = {}
  endfor
endfunction
call s:build_mode_vars()

""
" @section Mappings, mappings
" All mappings accept a count to specify a target to act upon. Each mode will
" have a different strategy for using count as a target. If in tmux mode,
" one digit is pane only e.g. 1<mapping> is an action for pane 1
" two digits is window, pane e.g. 12<mapping> is an action for window 1, pane 2
" and a 3rd digit represents session. In nvim mode, count maps directly to
" the numerical index of nvim terminals.

""
" @backmatter mappings
" ------------------------------------------------------------------------------
" | Mode | Def. Map | Plug                       | Command                     |

""
" Get a list of all available targets. Provides interactivity via fuzzy buffer
" and key bindings to for actions like 'go to'. See @dict(VimaxListBindings)
" Uses current @setting(g:vimax_mode).
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>List
" Call mode specific variant of List command, e.g. VimaxTmuxList
command -nargs=* VimaxList call vimax#list(v:null, <f-args>)
call vimax#init#register_method('list', 't')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>t   | Vimax#list                 | VimaxList                   |
" | n    |          | Vimax#<mode>#list          | Vimax<Mode>List             |

""
" Open scratch buffer. Nothing fancy, just a non-persisted buffer for quickly
" editing commands
command VimaxOpenScratch call vimax#scratch#open_scratch()
nnoremap <unique> <Plug>Vimax#scratch#open :<C-U>call vimax#scratch#open()<CR>
if get(g:, 'vimax_default_mappings') == 1
  execute 'nmap <silent> ' . g:vimax_leader . 'bo <Plug>Vimax#scratch#open'
endif
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>bo  | Vimax#scratch#open         | VimaxOpenScratch            |

""
" Close scratch buffer. Can close via simple :bd or :q, but a command/binding
" might be fun
command VimaxCloseScratch call vimax#scratch#close_scratch()
nnoremap <unique> <Plug>Vimax#scratch#close :<C-U>call vimax#scratch#close()<CR>
if get(g:, 'vimax_default_mappings') == 1
  execute 'nmap <silent> ' . g:vimax_leader . 'bc <Plug>Vimax#scratch#close'
endif
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>bc  | Vimax#scratch#close        | VimaxCloseScratch           |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>ClearHistory
" Call mode specific variant of ClearHistory command, e.g. VimaxTmuxClearHistory
command -nargs=* VimaxClearHistory call vimax#clear_history(v:null, <f-args>)
call vimax#init#register_method('clear_history', 'c')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>c   | Vimax#clear_history        | VimaxClearHistory           |
" | n    |          | Vimax#<mode>#clear_history | Vimax<Mode>ClearHistory     |


""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>RunInDir
" Call mode specific variant of RunInDir command, e.g. VimaxTmuxRunInDir
command -nargs=* VimaxRunInDir call vimax#run_in_dir(v:null, <f-args>)
call vimax#init#register_method('run_in_dir', 'd')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>d   | Vimax#run_in_dir           | VimaxRunInDir               |
" | n    |          | Vimax#<mode>#run_in_dir    | Vimax<Mode>RunInDir         |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>GoTo
" Call mode specific variant of GoTo command, e.g. VimaxTmuxGoTo
command -nargs=* VimaxGoTo call vimax#go_to(v:null, <f-args>)
call vimax#init#register_method('go_to', 'g')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>g   | Vimax#go_to                | VimaxGoTo                   |
" | n    |          | Vimax#<mode>#go_to         | Vimax<Mode>GoTo             |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>History
" Call mode specific variant of History command, e.g. VimaxTmuxHistory
command -nargs=* VimaxHistory call vimax#history(v:null, <f-args>)
call vimax#init#register_method('history', 'h')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>h   | Vimax#history              | VimaxHistory                |
" | n    |          | Vimax#<mode>#history       | Vimax<Mode>History          |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>Inspect
" Call mode specific variant of Inspect command, e.g. VimaxTmuxInspect
command -nargs=* VimaxInspect call vimax#inspect(v:null, <f-args>)
call vimax#init#register_method('inspect', 'i')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>i   | Vimax#inspect              | VimaxInspect                |
" | n    |          | Vimax#<mode>#inspect       | Vimax<Mode>Inspect          |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>ScrollDown
" Call mode specific variant of ScrollDown command, e.g. VimaxTmuxScrollDown
command -nargs=* VimaxScrollDown call vimax#scroll_down(v:null, <f-args>)
call vimax#init#register_method('scroll_down', 'j')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>j   | Vimax#scroll_down          | VimaxScrollDown             |
" | n    |          | Vimax#<mode>#scroll_down   | Vimax<Mode>ScrollDown       |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>ScrollUp
" Call mode specific variant of ScrollUp command, e.g. VimaxTmuxScrollUp
command -nargs=* VimaxScrollUp call vimax#scroll_up(v:null, <f-args>)
call vimax#init#register_method('scroll_up', 'k')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>k   | Vimax#scroll_up            | VimaxScrollUp               |
" | n    |          | Vimax#<mode>#scroll_up     | Vimax<Mode>ScrollUp         |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>RunLastCommand
" Call mode specific variant of RunLastCommand command,
" e.g. VimaxTmuxRunLastCommand
command -nargs=* VimaxRunLastCommand call
  \ vimax#run_last_command(v:null, <f-args>)
call vimax#init#register_method('run_last_command', 'l')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>l   | Vimax#run_last_command     | VimaxRunLastCommand         |
" | n    |          | Vimax#<mode>               | Vimax<Mode>RunLastCommand   |
" |      |          |      #run_last_command     |                             |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>PromptCommand
" Call mode specific variant of PromptCommand command,
" e.g. VimaxTmuxPromptCommand
command -nargs=* VimaxPromptCommand call vimax#prompt_command(v:null, <f-args>)
call vimax#init#register_method('prompt_command', 'p')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>d   | Vimax#prompt_command       | VimaxPromptCommand          |
" | n    |          | Vimax#<mode>               | Vimax<Mode>PromptCommand    |
" |      |          |      #prompt_command       |                             |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>Close
" Call mode specific variant of Close command, e.g. VimaxTmuxClose
command -nargs=* VimaxClose call vimax#close(v:null, <f-args>)
call vimax#init#register_method('close', 'q')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>q   | Vimax#close                | VimaxClose                  |
" | n    |          | Vimax#<mode>#close         | Vimax<Mode>Close            |

""
" Sends return key, useful at times
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>SendReturn
" Call mode specific variant of Close command, e.g. VimaxTmuxClose
command -nargs=* VimaxSendReturn call vimax#send_return(v:null, <f-args>)
call vimax#init#register_method('send_return', '<CR>')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l><CR>| Vimax#send_return          | VimaxSendReturn             |
" | n    |          | Vimax#<mode>#send_return   | Vimax<Mode>SendReturn       |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>RunAtGitRoot
" Call mode specific variant of RunAtGitRoot command, e.g. VimaxTmuxRunAtGitRoot
command -nargs=* VimaxRunAtGitRoot call vimax#run_at_git_root(v:null, <f-args>)
call vimax#init#register_method('run_at_git_root', 'r')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>r   | Vimax#run_at_git_root      | VimaxRunAtGitRoot           |
" | n    |          | Vimax#<mode>               | Vimax<Mode>RunAtGitRoot     |
" |      |          |      #run_at_git_root      |                             |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>SendLastRegion
" Call mode specific variant of SendLastRegion command,
" e.g. VimaxTmuxSendLastRegion
command VimaxSendLastRegion call vimax#motion#send_last_region(v:null)

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>SendCurrentLine
" Call mode specific variant of SendCurrentLine command,
" e.g. VimaxTmuxSendCurrentLine
command VimaxSendCurrentLine call vimax#motion#do_action('current_line', v:null)

""
" The Vimax#motion plugs are defined in autoload/init.vim
if get(g:, 'vimax_default_mappings') == 1
  execute 'nmap <silent> ' . g:vimax_leader . 's <Plug>Vimax#motion'
  execute 'xmap <silent> ' . g:vimax_leader . 's <Plug>Vimax#motion'
  execute 'nmap <silent> ' . g:vimax_leader .
    \ 'ss <Plug>Vimax#motion#current_line'
  execute 'nmap <silent> ' . g:vimax_leader .
    \ 's. <Plug>Vimax#motion#last_region'
endif
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>s   | Vimax#motion               |                             |
" | n    |          | Vimax#<mode>#motion        |                             |
" |------|----------|----------------------------|-----------------------------|
" | x    | <v-l>s   | Vimax#motion               |                             |
" | x    |          | Vimax#<mode>#motion        |                             |
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>ss  | Vimax#motion#current_line  | VimaxSendCurrentLine        |
" | n    |          | Vimax#<mode>#motion        | Vimax<Mode>SendCurrentLine  |
" |      |          |      #current_line         |                             |
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>s.  | Vimax#motion#last_region   | VimaxSendLastRegion         |
" | n    |          | Vimax#<mode>#motion        | Vimax<Mode>SendLastRegion   |
" |      |          |      #last_region          |                             |

""
" Switch mode via incrementing g:vimax_all_modes
command VimaxAlternateMode call vimax#altrnate_mode()
nnoremap <unique> <Plug>Vimax#alternate_mode :<C-U>call vimax#alternate_mode()<CR>
if get(g:, 'vimax_default_mappings') == 1
  execute 'nmap <silent> ' . g:vimax_leader . 'a <Plug>Vimax#alternate_mode'
endif
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>a   | Vimax#alternate_mode       | VimaxAlternateMode          |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>Interrupt
" Call mode specific variant of Interrupt command, e.g. VimaxTmuxInterrupt
"
" Send an interrupt sequence to target (possibly with exit-inspect sequence)
command -nargs=* VimaxInterrupt call vimax#interrupt(v:null, <f-args>)
call vimax#init#register_method('interrupt', 'x')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>x   | Vimax#interrupt            | VimaxInterrupt              |
" | n    |          | Vimax#<mode>#interrupt     | Vimax<Mode>Interrupt        |

""
" Uses current @setting(g:vimax_mode)
" @command <>
" @command Vimax<capitalized |g:vimax_mode|>Zoom
" Call mode specific variant of Zoom command, e.g. VimaxTmuxZoom
"
" Toggle zoom for target and go to that target
command -nargs=* VimaxZoom call vimax#zoom(v:null, <f-args>)
call vimax#init#register_method('zoom', 'z')
""
" @backmatter mappings
" |------|----------|----------------------------|-----------------------------|
" | n    | <v-l>z   | Vimax#zoom                 | VimaxZoom                   |
" | n    |          | Vimax#<mode>#zoom          | Vimax<Mode>Zoom             |
" ------------------------------------------------------------------------------

""
" Register all motion commands and plugs
call vimax#init#register_motions()

"Vimux plugin compatibility
"function! VimuxRunCommand(command, ...)
  "let address = vimax#util#get_address(g:vimax#none)
  "vimax#RunCommand(a:command, address, get(a:, '1', 0))
"endfunction

"function! VimuxRunLastCommand()
  "let address = vimax#util#get_address(g:vimax#none)
  "vimax#RunCommand(a:command, address, get(a:, '1', 0))
"endfunction
