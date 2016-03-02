#Vimax

An ax for maximum tmux and vim control... or something

##Vimux Based Functionality

This plugin is largely based on [Vimux](https://github.com//benmills/vimux) and is enhanced to allow a finer grain of control
over sending commands and text to multiple tmux panes and windows. Primarily, all Vimux functions now accept
a count or argument to specify the target window and pane—a combination refered to as an address—with which we wish to interact.

##Installation

Installing Vimax is easy with any plugin manager. For instance, with Vundle, just put
```
Bundle 'low-ghost/vimax'
```
in your vimrc, run `:source ~/.vimrc` and run `:BundleInstall`. With vim-plug, just
```
Plug 'low-ghost/vimax'
```
and run `:PlugInstall`.

####Optional Dependencies

Vimax has a few commands and mappings which provide an interactive buffer to help navigate panes and select commands from history.
To get this full functionality, install either [fzf](https://github.com/junegunn/fzf) or [tlib](https://github.com/tomtom/tlib_vim).
Fzf is frankly a bit nicer, but it does have an external dependency while tlib can be installed easily with vim-plug or vundle etc
in exactly the same way as above. To install fzf, follow the instructions listed on the fzf github page by cloning and running the install script:
```
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```
Then either put this in your vimrc:
```
set rtp+=~/.fzf
```
Or, if you're using vim-plug:
```
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all'  }
```
And you're good to go (no [fzf.vim](https://github.com/junegunn/fzf.vim) required, though it might be up your ally)

##Usage

Vimax works by accepting an 'address' for functions which help to send commands to tmux.
An address is a combination of session, window, and pane, all of which are optional.
If no address is given, the last targeted address is used for that command, or, if
no previous address is given, a prompt will ask for a specified pane.
If just a pane is specified, then the current session and window are used, and so on.
This will be clearer with the examples given below, but it essentially allows
sending commands to tmux panes and windows with great ease.

####Mappings

Vimax provides easy mappings which accept up to three, one digit numbers to specify session, window and pane.
For instance, lets say VimaxPromptCommand is mapped to `<leader>vp`.
VimaxPromptCommand prompts for user input of any command and then executes it in the specified target address.
Pressing `2<leader>vp` will ask for a command that will be executed in pane 2
of the current window, and `132<leader>vp` will select session 1, window 3 and pane 2. Just `<leader>vp` will use the last targeted address.
Here is a full example mapping:

```
nmap <leader>vp <Plug>VimaxPromptCommand
nmap <leader>vl <Plug>VimaxRunLastCommand
nmap <leader>vi <Plug>VimaxInspectAddress
nmap <leader>vc <Plug>VimaxClearAddressHistory
nmap <leader>vx <Plug>VimaxInterruptAddress
nmap <leader>vz <Plug>VimaxZoomAddress
nmap <leader>vg <Plug>VimaxGoToAddress
nmap <leader>vk <Plug>VimaxScrollUpInspect
nmap <leader>vj <Plug>VimaxScrollDownInspect
nmap <leader>vq <Plug>VimaxCloseAddress
nmap <leader>vh <Plug>VimaxHistory
nmap <leader>va <Plug>VimaxList
```

The `<leader>va` might be a bit of a stretch, a for addresses

####Commands

Vimax commands accept an address in the format `session:window.pane`.
Commands are useful for specifying named windows, like `repl.1` to
select the 1 pane of a window named 'repl' in this session, or
a window/pane out of the single digits, like `0:12.1`. All vimax mappings
are provided as commands and look like this:
```
:VimaxGoToAddress repl.1
```
followed by the return key.
Commands which accept an argument take those arguments first and the address last. Like:
```
:VimaxRunCommand print("Hello, World") repl.1
```

####Functions

You can also call vimax functions directly with string values for addresses, like
```
:call vimax#GoToAddress('1.1')
```
This is useful if you want to hack something like support for your favorite test suite.

####Interactive Buffers

Vimax provides interactive buffers for listing windows and listing command line history.
The interactive elements rely on either [fzf](https://github.com/junegunn/fzf) or [tlib](https://github.com/tomtom/tlib_vim).

VimaxList will provide a buffer with the list of panes available and allow fuzzy searching to select an address
which will be used as the default in the next command. If mapped to `<leader>va`, then hit that key combo,
start typing a few letters of the process you are targeting or a few numbers of the address and hit enter.

VimaxHistory will provide a buffer of recent command line history and allow fuzzy searching to select a command
for execution. If mapped to `<leader>vh` then hit that combination, start typing something from the recent history,
say 'npm run' and hit enter. VimaxHistory accepts a count and will execute the selected command at that address,
so `2<leader>vh` followed by `npm run` and `enter` will run the most recent command containing `npm run` in pane 2
of the current window. VimaxHistory also adds functionality for changing target addresses and for executing a command at an
address while remaining in the gui menu. These are bound to ctrl-t and ctrl-e by default, but can be configured
via a global variable. More on that below in 'Configuration'.

Pressing ctrl-t will bring up VimaxList and allow selecting an address in which the command will be executed.
Here's an example: I press `2<leader>vh` assuming I want to execute something from the history in pane 2.
I then change my mind and want to execute in pane 3 instead, so I hit ctrl-t, select pane 3 from the gui list,
and hit enter to return to the history selection menu.

Pressing ctrl-e will execute the command under the cursor after pulling up the VimaxList gui to select an address
and return to the history menu after the command begins executing.

##Configuration

Besides allowing (well requiring) custom mappings, Vimax allows several points of configuration through global variables.
Here is a complete list and description of these variables:

<dl>
  <dt>g:VimaxFuzzyBuffer</dt>
  <dd><dl>
    <dt>description</dt>
    <dd>dependency for interactive buffer and is either 'fzf', 'tlib', or none. Should be set automatically,
  but you can switch back and forth with `let g:VimaxFuzzyBuffer='tlib'`</dd>
    <dt>default</dt>
    <dd>fzf if loaded, then tlib, then none</dd>
  </dl></dd>
</dl>


g:VimaxHistoryFile:
    description: location of shell history file. Should be accessable with $HISTFILE, but inconcistencies in tmux/bash
        environments make this dificult. Change to $HOME.'/.zsh_history' or $HOME.'./.zhistory' for zsh.
    default: $HOME.'/.bash_history'

g:VimaxLimitHistory:
    description: number of commands pulled from the history file. Can be pretty large with fzf without worry
    default: 25

g:VimaxPromptString:
    description: string presented when prompting for a command
    default: 'Command? '

g:VimaxResetSequence:
    description: sequence of keys sent to Tmux to exit copy-mode
    default: = 'q C-u'


g:VimaxLastCommandDict:
    description: command dictionary with Tmux addresses as keys, string commands as props. Available if you'd want
        to prefill values, but probably not that useful
    default: {}

g:VimaxOrientation:
    description: vimax#RunCommandInDir creates a new pane in either a vertical or horizontal split, specified
        by setting g:VimaxOrientation to 'v' or 'h'
    default: 'v'

g:VimaxHeight
    description: height of vimax#RunCommandInDir pane in lines
    default: 10


####Tmux Specific Config (Go Back to Vim and Pane Numbering)

Vimax adds functionality to return to the last vim address via a key combination.
Here's a sample mapping to <prefix><C-o>

```bash
bind C-o run "tmux showenv | grep VimaxLastVimAddress | sed -ne 's/VimaxLastVimAddress=\\([[:digit:]]\\).\\([[:digit:]]\\)/tmux select-window -t \\1; tmux select-pane -t \\2/p' | xargs -I % bash -c % bash"
```

There is probably a better way of doing all that (probably with grep -o and tmux execution of the final command).
Let me know if you discover something.

You may also want:

```bash
set -g base-index 1
set-window-option -g pane-base-index 1
```

So that all indexes start at 1 and the address of the base window/pane is 1.1. Helpful in that it prevents frequently having to reach for the 0.

Put these in your ~/.tmux.conf file and type
```
<prefix>: source-file ~/.tmux.conf
```
to enable. All examples will assume this configuration.

`<prefix>q` might also be useful, it shows the pane numbers in the current window

#TODO
- [x] pull up quicklist with history (limited to g:VimaxHistoryLimit) and allow selecting to send
- [x] list all addresses and allow selecting to set the last used address (next default)
- [ ] docs
- [ ] example gif
- [x] run in dir is actually useful. Recommend Dispatch to perform these kinds of actions
      but also give command which replicates pane creation in dir and sets to LastAddress
- [ ] finish and integrate sending keys by region/range
- [x] fzf and tlib support based on global variable
- [ ] potential: persistent last command dicts across tmux session
- [ ] potential: additional bindings for list and history.
      including
      * List
        * execute prompted command
        * execute history command
        * go to
        * zoom
        * run last
        * Tmux specific like rename window, bring pane into current window, break from current window, close pane (with prompt)
      * History
        * edit (via prompt and ctrl-f)
        * execute at address~~(done)
