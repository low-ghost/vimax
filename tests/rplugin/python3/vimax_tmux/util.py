import unittest
from unittest.mock import (patch, Mock)
from vimax_tmux.tmux_cmd import TmuxCmd

from vimax_tmux.util import (unpack, send_keys, copy_mode, scroll, send_text,
                             send_return, send_reset)


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
    def test_send_keys_address(self):
        """should send keys to a particular pane"""
        with patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__',
                   Mock(return_value=None)) as mock:
            text = 'ls -a'
            self.assertIsInstance(send_keys(ADDRESS, text), TmuxCmd)

            mock.assert_called_once_with(
                         'send-keys -t {} {}'.format(ADDRESS, text))


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
    def test_copy_mode(self):
        """should enter copy mode in a particular pane"""
        with patch('vimax_tmux.tmux_cmd.TmuxCmd.__init__',
                   Mock(return_value=None)) as mock:
            self.assertIsInstance(copy_mode(ADDRESS), TmuxCmd)

            mock.assert_called_once_with('copy-mode -t {}'.format(ADDRESS))


class VimaxTmuxUtilScroll(unittest.TestCase):
    def test_send_up(self):
        """should enter copy mode in a particular pane and send scroll up"""
        self.assertEqual(scroll(ADDRESS, 'up').text,
                         'copy-mode -t {}\\; send-keys -t {} C-u'
                         .format(ADDRESS, ADDRESS))

    def test_send_down(self):
        """should enter copy mode in a particular pane and send scroll down"""
        self.assertEqual(scroll(ADDRESS, 'down').text,
                         'copy-mode -t {}\\; send-keys -t {} C-d'
                         .format(ADDRESS, ADDRESS))


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
