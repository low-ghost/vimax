#Vimax

An ax for maximum tmux and vim control... or something

##Vimux Based Functionality

This plugin is largely based on [Vimux](https://github.com//benmills/vimux) and is enhanced to allow a finer grain of control over sending commands and text to multiple tmux panes and windows. Primarily, all Vimux functions now accept a count or argument to specify the target window and pane—a combination refered to as an address—with which we wish to interact.

##Usage

Vimax works by accepting an 'address' to functions which help to send commands to tmux.
An address is a combination of session, window, and pane, all of which are optional.
If no address is given, the last targeted address is used for that command, or, if
no previous address is given, a prompt will ask for a specified pane.
If just a pane is specified, then the current session and window are used, and so on.

####Mappings

Vimax provides easy mapping to functions which accept up to three, one digit numbers to specify session, window and pane.
For instance, if VimaxPromptCommand is mapped to `<leader>vp` then pressing `2<leader>vp` will ask for a command that will be executed in pane 2
of the current window, and `132<leader>vp` will select session 1, window 3 and pane 2. Just `<leader>vp` will use the last targeted address.
Here is a full example mapping:

```
nmap ,vp <Plug>VimaxPromptCommand
nmap ,vl <Plug>VimaxRunLastCommand
nmap ,vi <Plug>VimaxInspectAddress
nmap ,vc <Plug>VimaxClearAddressHistory
nmap ,vx <Plug>VimaxInterruptAddress
nmap ,vz <Plug>VimaxZoomAddress
nmap ,vg <Plug>VimaxGoToAddress
nmap ,vk <Plug>VimaxScrollUpInspect
nmap ,vj <Plug>VimaxScrollDownInspect
nmap ,vq <Plug>VimaxCloseAddress
nmap ,vh <Plug>VimaxHistory
nmap ,va <Plug>VimaxList
```

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

##Tmux Specific Config

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

<prefix>q might also be useful, it shows the pane numbers in the current window

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
      including execute prompted command, execute history command, go to, zoom, and run last for list,
      and edit, and ~~execute at address~~(done) for history
