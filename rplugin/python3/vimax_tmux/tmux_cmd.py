from subprocess import run


class TmuxCmd():

    def __init__(self, text=''):
        self.text = text

    def __add__(self, other):
        if self.text and other.text:
            self.text = '{}\; {}'.format(self.text, other.text)
        elif other.text:
            self.text = other.text
        return self

    def chain(self, text):
        self.__add__(TmuxCmd(text))
        return self

    def prepend(self, text):
        if (text):
            self.text = '{}\; {}'.format(text, self.text)
        return self

    def format(self, **to_format):
        self.text.format(**to_format)
        return self

    def run(self, **opts):
        return run('tmux {}'.format(self.text), shell=True, **opts)
