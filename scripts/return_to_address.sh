address=`head ~/.vimaxenv`
tmux select-window -t $address\; select-pane -t $address\; switch-client -t $address
