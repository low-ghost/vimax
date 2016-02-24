#VimuxPlex

Enhanced control over tmux and vim

##Vimux Based Functionality

This plugin is largely based on [Vimux](https://github.com//benmills/vimux) and is enhanced to allow a finer grain of control over sending commands and text to multiple tmux panes and windows. Primarily, all Vimux functions now accept a count or argument to specify the target window and pane—a combination refered to as an address—with which we wish to interact.

##Tmux Specific Config

VimuxPlex adds functionality to return to the last vim address via a key combination.
Here's a sample mapping to <prefix><C-o>

```bash
bind C-o run "tmux showenv | grep VimuxPlexLastVimAddress | sed -ne 's/VimuxPlexLastVimAddress=\\([[:digit:]]\\).\\([[:digit:]]\\)/tmux select-window -t \\1; tmux select-pane -t \\2/p' | xargs -I % bash -c % bash"
```

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
to enable. All examples will assume this configuration

#TODO
- [ ] persistant last command dicts across tmux session
- [ ] pull up quicklist with history (limited to g:VimuxPlexHistoryLimit) and allow selecting to send
- [ ] list all addresses and allow selecting to set the last used address (next default)
- [ ] docs
- [x] ~~run in dir is actually useful. means pane/window global pref~~ recommend Dispatch to perform these kinds of actions
