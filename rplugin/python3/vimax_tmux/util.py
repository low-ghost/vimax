import shlex
from subprocess import run, PIPE
from vimax_tmux.tmux_cmd import TmuxCmd


def unpack(len_expected, seq):
    """Handle too few or to many elements in a sequence for unpacking"""
    len_seq = len(seq)
    missing = len_expected - len_seq
    return seq + missing * [None] if missing > -1 else seq[0:len_expected]


def send_keys(address, text):
    return TmuxCmd('send-keys -t {} {}'.format(address, text))


def send_text(address, text):
    # TODO: Vimax replace and escape
    return send_keys(address, shlex.quote(text))


def copy_mode(address):
    return TmuxCmd('copy-mode -t {}'.format(address))


def scroll(address, direction):
    short_direction = 'u' if direction == 'up' else 'd'
    # + send_keys(address, '-X -N 5 scroll-{}'.format(direction)))
    return (copy_mode(address)
            + send_keys(address, 'C-{}'.format(short_direction)))


def send_return(address):
    return send_keys(address, 'Enter')


def send_reset(address):
    return send_keys(address, 'q C-u')


def split_address(address):
    first_split = str(address).split('.')
    return (first_split if len(first_split) == 1
            else first_split[0].split(':') + [first_split[1]])[::-1]


def save_vim_address(file_path):
    """Save original vim address to file"""
    run(("touch {} && echo `tmux display-message -p '#S:#I.#P'`"
        + ' > {}').format(file_path, file_path), shell=True)


def go_to_address_additional(address, add='', vimax_env_file_path='~/.vimaxenv'):
    save_vim_address(vimax_env_file_path)
    address_parts = split_address(address)
    len_address = len(address_parts)
    cmd = TmuxCmd('select-pane -t {}'.format(address)).chain(add)
    # "Go to a different window
    cmd = (TmuxCmd('select-win -t {}'.format(address)) + cmd
           if len_address > 1 else cmd)
    # Go to different session
    client = address_parts[2] if len_address == 3 else None
    cmd = (cmd.chain('switch-client -t {}'.format(client))
           if client else cmd)
    return cmd


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
