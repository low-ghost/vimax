import neovim
from subprocess import call

@neovim.plugin
class Main(object):
    def __init__(self, vim):
        self.vim = vim

    @neovim.function('VimaxSendKeysPy')
    def vimaxSendKeysPy(self, args):
        call('tmux send-keys -t {} {}'.format(args[0], args[1]), shell=True)

    @neovim.function('VimaxPromptCommandPy', sync=True)
    def vimaxPromptCommand(self, args):
      self.vim.command('let g:command = input(g:VimaxPromptString)')
      # self.vim.command('echo "{}"'.format(self.vim.vars['command']))
