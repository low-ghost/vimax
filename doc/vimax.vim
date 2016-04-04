*vimax.txt* An ax for maximum tmux and vim control... or something
 _          _        _         _   _         _           _      _      ~
/\ \    _ / /\      /\ \      /\_\/\_\ _    / /\       /_/\    /\ \    ~
\ \ \  /_/ / /      \ \ \    / / / / //\_\ / /  \      \ \ \   \ \_\   ~
 \ \ \ \___\/       /\ \_\  /\ \/ \ \/ / // / /\ \      \ \ \__/ / /   ~
 / / /  \ \ \      / /\/_/ /  \____\__/ // / /\ \ \      \ \__ \/_/    ~
 \ \ \   \_\ \    / / /   / /\/________// / /  \ \ \      \/_/\__/\    ~
  \ \ \  / / /   / / /   / / /\/_// / // / /___/ /\ \      _/\/__\ \   ~
   \ \ \/ / /   / / /   / / /    / / // / /_____/ /\ \    / _/_/\ \ \  ~
    \ \ \/ /___/ / /__ / / /    / / // /_________/\ \ \  / / /   \ \ \ ~
     \ \  //\__\/_/___\\/_/    / / // / /_       __\ \_\/ / /    /_/ / ~
      \_\/ \/_________/        \/_/ \_\___\     /____/_/\/_/     \_\/  ~
                                                                       ~
========================================================================
CONTENTS                                                 *VimaxContents*
1. Introduction...................|VimaxIntroduction|
2. Installation...................|VimaxInstallation|
3. Usage..........................|VimaxUsage|
  3.1 Mappings....................|VimaxMappings|
  3.2 Commands....................|VimaxCommands|
  3.3 Functions...................|VimaxFunctions|
  3.4 Interactive Buffers.........|VimaxInteractiveBuffers|
    3.4.1 History Buffer..........|VimaxHistory|
    3.5.2 List Buffer.............|VimaxList|
4.0 Configuration.................|VimaxConfiguration|
5.0 Tmux Configuration............|VimaxTmuxConfiguration|

========================================================================
1. Introduction                                      *VimaxIntroduction*

This plugin is largely based on Vimux and is enhanced to allow a finer
grain of control over sending commands and text to multiple tmux panes
and windows. Primarily, all functions and commands now accept a count
or argument to specify a target tmux pane, placing an entire tmux
session (or sessions) at your fingertips. Vimax also provides a GUI for
listing and executing historical commands and listing available panes
to help navigate.

========================================================================
