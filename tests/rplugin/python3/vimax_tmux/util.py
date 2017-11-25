import unittest
from unittest.mock import patch, Mock
from vimax_tmux.tmux_cmd import TmuxCmd

from vimax_tmux.util import (unpack, send_keys, copy_mode, scroll, send_text,
                             send_return, send_reset, split_address,
                             go_to_address_additional)

ADDRESS = '1:2.3'


class VimaxTmuxUtilUnpack(unittest.TestCase):
    def test_single_none(self):
        """should unpack a single None element from empty list"""
        self.assertEqual(unpack(1, []), [None])

    def test_multiple_none(self):
        """should unpack multiple None elements from empty list"""
        self.assertEqual(unpack(3, []), [None, None, None])

    def test_exact(self):
        """should unpack exact number of elements requested"""
        self.assertEqual(unpack(3, [1, 2, 3]), [1, 2, 3])

    def test_exact_multiple_extra(self):
        """should unpack all requested elements plus Nones for extras"""
        self.assertEqual(unpack(5, [1, 2, 3]), [1, 2, 3, None, None])


class VimaxTmuxUtilSendKeys(unittest.TestCase):
    @patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__', return_value=None)
    def test_send_keys_address(self, mock):
        """should send keys to a particular pane"""
        text = 'ls -a'
        self.assertIsInstance(send_keys(ADDRESS, text), TmuxCmd)

        mock.assert_called_once_with('send-keys -t {} {}'.format(
            ADDRESS, text))


class VimaxTmuxUtilSendText(unittest.TestCase):
    @patch('shlex.quote', return_value='quoted')
    @patch('vimax_tmux.util.send_keys', return_value=TmuxCmd(''))
    def test_send_keys_address(self, mock_send_keys, mock_quote):
        """should send text to a particular pane via send_keys & quote"""
        text = 'ls -a'
        self.assertIsInstance(send_text(ADDRESS, text), TmuxCmd)
        mock_quote.assert_called_once_with(text)
        mock_send_keys.assert_called_once_with(ADDRESS, 'quoted')


class VimaxTmuxUtilCopyMode(unittest.TestCase):
    @patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__', return_value=None)
    def test_copy_mode(self, mock):
        """should enter copy mode in a particular pane"""
        self.assertIsInstance(copy_mode(ADDRESS), TmuxCmd)

        mock.assert_called_once_with('copy-mode -t {}'.format(ADDRESS))


class VimaxTmuxUtilScroll(unittest.TestCase):
    def test_send_up(self):
        """should enter copy mode in a particular pane and send scroll up"""
        self.assertEqual(
            scroll(ADDRESS, 'up').text,
            'copy-mode -t {}\\; send-keys -t {} C-u'.format(ADDRESS, ADDRESS))

    def test_send_down(self):
        """should enter copy mode in a particular pane and send scroll down"""
        self.assertEqual(
            scroll(ADDRESS, 'down').text,
            'copy-mode -t {}\\; send-keys -t {} C-d'.format(ADDRESS, ADDRESS))


class VimaxTmuxUtilSendReturn(unittest.TestCase):
    @patch('vimax_tmux.util.send_keys', return_value=TmuxCmd(''))
    def test_send_return(self, mock_send_keys):
        """should send return to a particular pane via send_keys"""
        self.assertIsInstance(send_return(ADDRESS), TmuxCmd)
        mock_send_keys.assert_called_once_with(ADDRESS, 'Enter')


class VimaxTmuxUtilSendReset(unittest.TestCase):
    @patch('vimax_tmux.util.send_keys', return_value=TmuxCmd(''))
    def test_send_reset(self, mock_send_keys):
        """should send reset to a particular pane via send_keys"""
        self.assertIsInstance(send_reset(ADDRESS), TmuxCmd)
        mock_send_keys.assert_called_once_with(ADDRESS, 'q C-u')


class VimaxTmuxUtilSplitAddress(unittest.TestCase):
    def test_split_nothing(self):
        """should handle an empty address"""
        self.assertEqual(split_address(''), [''])

    def test_split_single(self):
        """should handle a single digit address"""
        self.assertEqual(split_address('1'), ['1'])

    def test_split_double(self):
        """should handle a double digit address"""
        self.assertEqual(split_address('1.2'), ['2', '1'])

    def test_split_triple(self):
        """should handle a triple digit address"""
        self.assertEqual(split_address('1:2.3'), ['3', '2', '1'])


class VimaxTmuxUtilGoToAddressAdditional(unittest.TestCase):
    @patch('vimax_tmux.util.save_vim_address')
    @patch('vimax_tmux.util.split_address', return_value=['1'])
    @patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__', return_value=None)
    def test_single_address(self, mock_tmux_cmd_init, mock_split_address,
                            mock_save_vim_address):
        """should go to single digit address, default .vimaxenv & add"""
        mock_tmux_cmd = Mock(spec=TmuxCmd)
        with patch(
                'vimax_tmux.tmux_cmd.TmuxCmd.chain',
                return_value=mock_tmux_cmd) as mock_tmux_cmd_chain:
            go_to_address_additional('1')
            mock_save_vim_address.assert_called_once_with('~/.vimaxenv')
            mock_split_address.assert_called_once_with('1')
            mock_tmux_cmd_init.assert_called_once_with(
                'select-pane -t {}'.format('1'))
            mock_tmux_cmd_chain.assert_called_once_with('')
            mock_tmux_cmd.prepend.assert_called_once_with(None)

    @patch('vimax_tmux.util.save_vim_address')
    @patch('vimax_tmux.util.split_address', return_value=['1'])
    @patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__', return_value=None)
    def test_additional(self, mock_tmux_cmd_init, mock_split_address,
                        mock_save_vim_address):
        """should use provided .vimaxenv and add parameter"""
        mock_tmux_cmd = Mock(spec=TmuxCmd)
        with patch(
                'vimax_tmux.tmux_cmd.TmuxCmd.chain',
                return_value=mock_tmux_cmd) as mock_tmux_cmd_chain:
            go_to_address_additional('1', 'additional', '~/.test')
            mock_save_vim_address.assert_called_once_with('~/.test')
            mock_tmux_cmd_chain.assert_called_once_with('additional')
            mock_tmux_cmd.prepend.assert_called_once_with(None)
