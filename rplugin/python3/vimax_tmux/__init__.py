import neovim
import re
from vimax_tmux.tmux_cmd import TmuxCmd
from vimax_tmux.util import (unpack, send_keys, send_reset, send_return,
                             send_text, scroll, go_to_address_additional,
                             run_in_dir)

# TODO:
# vimax#util#escape as python util

fzf_regex = re.compile(r'(\w+):.*-(\w+).(\w+)')


@neovim.plugin
class Vimax(object):

    def __init__(self, vim):
        self.vim = vim

    @neovim.function('_vimax_tmux_format_address_from_vcount', sync=True)
    def _vimax_tmux_format_address_from_vcount(self, args):
        [count] = unpack(1, args)
        count_str = str(args[0])
        len_count = len(count_str)
        if len_count < 3:
            return '.'.join(count_str)
        formatted_add = '{add[0]}:{add[1]}.{add[2]}'.format(add=count_str)
        return formatted_add

    @neovim.function('_vimax_tmux_format_address_from_arg', sync=True)
    def _vimax_tmux_format_address_from_arg(self, args):
        [address] = unpack(1, args)
        return str(address)

    @neovim.function('_vimax_tmux_format_address_from_fzf_item', sync=True)
    def _vimax_tmux_format_from_fzf_item(self, args):
        [item] = unpack(1, args)
        m = re.search(fzf_regex, item)
        formatted_add = '{}:{}.{}'.format(m.group(1), m.group(2), m.group(3))
        return formatted_add

    @neovim.function('_vimax_tmux_scroll_down')
    def _vimax_tmux_scroll_down(self, args):
        [address] = unpack(1, args)
        return scroll(address, 'down').run()

    @neovim.function('_vimax_tmux_scroll_up')
    def _vimax_tmux_scroll_up(self, args):
        [address] = unpack(1, args)
        return scroll(address, 'up').run()

    @neovim.function('_vimax_tmux_close')
    def _vimax_tmux_close(self, args):
        [address] = unpack(1, args)
        return TmuxCmd('kill-pane -t {}'.format(address)).run()

    @neovim.function('_vimax_tmux_interrupt')
    def _vimax_tmux_interrupt(self, args):
        [address] = unpack(1, args)
        # Needed for tmux <= 2.2?
        # send_keys(address, '^C') + send_keys(address, '-X cancel')
        return (send_keys(address, '^C')).run()

    @neovim.function('_vimax_tmux_clear_history')
    def _vimax_tmux_clear_history(self, args):
        [address] = unpack(1, args)
        return (TmuxCmd('clear-history -t {}'.format(address))
                + send_keys(address, 'clear')
                + send_return(address)).run()

    @neovim.function('_vimax_tmux_inspect')
    def _vimax_tmux_inspect(self, args):
        [address] = unpack(1, args)
        return go_to_address_additional(address, 'copy-mode').run()

    @neovim.function('_vimax_tmux_send_reset')
    def _vimax_tmux_send_reset(self, args):
        [address] = unpack(1, args)
        return send_reset(address).run()

    @neovim.function('_vimax_tmux_send_return')
    def _vimax_tmux_send_return(self, args):
        [address] = unpack(1, args)
        return send_return(address).run()

    @neovim.function('_vimax_tmux_send_text')
    def _vimax_tmux_send_text(self, args):
        [address, text] = unpack(2, args)
        return send_text(address, text).run()

    @neovim.function('_vimax_tmux_send_keys')
    def _vimax_tmux_send_keys(self, args):
        [address, text] = unpack(2, args)
        return send_keys(address, text).run()

    @neovim.function('_vimax_tmux_send_command')
    def _vimax_tmux_send_command(self, args):
        address, command, send_direct_text = args
        send_main = send_text(address, command)
        # reset might fail silently depending on mode, thus make it separate
        if not send_direct_text:
            send_reset(address).run()
        final = (send_main if send_direct_text
                 else send_main + send_return(address))
        self.vim.vars['last_tmux_command'] = final.text
        return final.run()

    @neovim.function('_vimax_tmux_zoom')
    def _vimax_tmux_zoom(self, args):
        [address] = unpack(1, args)
        return go_to_address_additional(address,
                                        'resize-pane -Z -t {}'.format(address)
                                        ).run()

    @neovim.function('_vimax_tmux_go_to')
    def _vimax_tmux_go_to(self, args):
        [address] = unpack(1, args)
        return go_to_address_additional(address).run()

    @neovim.function('_vimax_tmux_run_in_dir')
    def _vimax_tmux_run_in_dir(self, args):
        path, command = unpack(2, args)
        orientation = self.vim.vars['vimax_orientation']
        size = self.vim.vars['vimax_size']
        address = run_in_dir(path, command, orientation, size)
        # Call vimax#set_last_address for tmux to preserve async yet correctly
        # 'return' the new address
        self.vim.eval("vimax#set_last_address('tmux', '{}')".format(address))
        TmuxCmd('last-pane').run()
        return address
