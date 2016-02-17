#VimuxPlex

God-like control over tmux and vim

##Tmux Specific Config

VimuxPlex adds functionality to return to the last vim address via a key combination.
Here's a sample mapping to <prefix><C-o>

```bash
bind C-o run "tmux showenv | grep VimuxPlexLastVimAddress | sed -ne 's/VimuxPlexLastVimAddress=\\([[:digit:]]\\).\\([[:digit:]]\\)/tmux select-window -t \\1; tmux select-pane -t \\2/p' | xargs -I % bash -c % bash"
```

Put this in your ~/.tmux.conf file to enable
