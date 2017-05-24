import neovim
import re
import socket
import os
import sys
from threading import Thread
from subprocess import run, PIPE
from shlex import quote
from .tmux_cmd import TmuxCmd


# TODO:
# vimax#util#escape as python util

fzf_regex = re.compile(r'(\w+):.*-(\w+).(\w+)')


def unpack(len_expected, seq):
    """Handle too few or to many elements in a sequence for unpacking"""
    len_seq = len(seq)
    missing = len_expected - len_seq
    return seq + missing * [None] if missing > -1 else seq[0:len_expected]


def send_keys(address, text):
    return TmuxCmd('send-keys -t {} {}'.format(address, text))


def send_text(address, text):
    # TODO: Vimax replace and escape
    return send_keys(address, quote(text))


def send_reset(address):
    return send_keys(address, '-X cancel')


def copy_mode(address):
    return TmuxCmd('copy-mode -t {}'.format(address))


def scroll(address, direction):
    short_direction = 'u' if direction == 'up' else 'd'
    # + send_keys(address, '-X -N 5 scroll-{}'.format(direction)))
    return (copy_mode(address)
            + send_keys(address, 'C-{}'.format(short_direction)))


def send_return(address):
    return send_keys(address, 'Enter')


def go_to_address_additional(address, add=''):
    # Save original vim address to file
    run("touch ~/.vimaxenv && echo `tmux display-message -p '#S:#I.#P'`"
        + ' > ~/.vimaxenv', shell=True)
    first_split = str(address).split('.')
    address_parts = (first_split if len(first_split) == 1
                     else first_split[1].split(':') + [first_split[0]])[::-1]
    len_address = len(address_parts)
    pane_add = TmuxCmd('select-pane -t {}'.format(address)).chain(add)
    # "Go to a different window
    win_pane_add = (TmuxCmd('select-win -t {}'.format(address)) + pane_add
                    if len_address > 1 else pane_add)
    # Go to different session
    client = address_parts[2] if len_address == 3 else None
    client_win_pane_add = (win_pane_add
                           .chain('switch-client -t {}'.format(client))
                           if client else win_pane_add)
    return client_win_pane_add


def run_in_dir(path, command, orientation, size):
    is_command = bool(command)
    send_instructions = (TmuxCmd("send-keys \"{}\" 'Enter'".format(command))
                         if is_command else TmuxCmd())
    orient = 'v' if orientation == 'h' else 'h'
    split = TmuxCmd('split-window -{} -l {} -c {}'.format(orient, size, path))
    full_cmd = (split + send_instructions
                .chain('display-message -p \'#S:#I.#P\''))
    address = full_cmd.run(stdout=PIPE).stdout.decode().replace('\n', '')
    return address


def scroll_up(vim, address):
    vim.eval('vimax#scroll_up("tmux", {})'.format(address))


funs = {
    'scroll_up': scroll_up,
}


def client_thread(conn, client, vim):
    while True:
        msg = conn.recv(2048)
        if msg:
            decoded = msg.decode('utf-8').strip()
            if decoded == 'exit':
                client.close()
                sys.exit('closing vimax')
            elif decoded in funs:
                vim.async_call(funs[decoded], vim, 2)


def connect(socket_path):
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection_result = client.connect_ex(socket_path)
    return client, connection_result


def client_start(vim):
    socket_path = '/tmp/vimax-tmux.sock'
    client, connection_result = connect(socket_path)
    # connect to the unix local socket with a stream type
    if connection_result != 0:
        try:
            os.remove(socket_path)
        except OSError:
            pass
        client.bind(socket_path)
        client.listen(5)
        while True:
            conn, addr = client.accept()
            Thread(target=client_thread, args=(conn, client, vim)).start()
    client.close()


@neovim.plugin
class Vimax(object):

    def __init__(self, vim):
        self.vim = vim
        Thread(target=client_start, args=(self.vim)).start()

    @neovim.function('_vimax_tmux_format_address_from_vcount', sync=True)
    def _vimax_tmux_format_address_from_vcount(self, args):
        [count] = unpack(1, args)
        count_str = str(args[0])
        len_count = len(count_str)
        if len_count < 3:
            return '.'.join(count_str)
        formatted_add = '{add[2]}:{add[1]}.{add[0]}'.format(add=count_str)
        return formatted_add

    @neovim.function('_vimax_tmux_format_address_from_arg', sync=True)
    def _vimax_tmux_format_address_from_arg(self, args):
        [address] = unpack(1, args)
        return str(address)

    @neovim.function('_vimax_tmux_format_address_from_fzf_item', sync=True)
    def _vimax_tmux_format_form_fzf_item(self, args):
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
        if command:
            TmuxCmd('last-pane').run()
        return address

    @neovim.function('_vimax_tmux_exit', sync=True)
    def _vimax_tmux_exit(self, args):
        socket_path = '/tmp/vimax-tmux.sock'
        client, connection_result = connect(socket_path)
        # TODO: not working
        client.send(b'exit')
        client.close()
        sys.exit('closing vimax')
        return 'exiting'
