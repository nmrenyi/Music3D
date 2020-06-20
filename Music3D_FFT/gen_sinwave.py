from math import sin
from math import pi
def f(x):
    return sin(2 * pi * 2000 * x)
def conv(s):
    if len(s) == 1:
        return "00000000"
    elif s[0] == '-':
        s = '0' + s[1:]
        r = ''
        for i in s:
            if i == '0':
                r += '1'
            else:
                r += '0'
        return r
    else:
        return '0' + s



Fs = 8000
T = 1 / Fs
L = 8
for i in range(L):
    binary = format(int((2 ** 7 - 1) * f(i * T)), 'b')
    print(conv(binary))
