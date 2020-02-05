#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
from re import compile as rcompile
from re import match as rmatch
from re import split as rsplit
from re import sub as rsub
from sys import platform
from subprocess import Popen
from subprocess import PIPE
from subprocess import STDOUT
from datetime import datetime
import itertools
from timeit import default_timer as timer

bg_color_1 = 33

black = 16
white_high = 15

fg_color_1a = 250
fg_color_1b = 16

sep_right_char    = bytes([0xEE, 0x82, 0xB0]).decode("utf-8") # \uE0B0 
sep_left_char     = bytes([0xEE, 0x82, 0xB2]).decode("utf-8") # \uE0B2 
suspension_char   = bytes([0xE2, 0x8B, 0xAF]).decode("utf-8") # \u22EF ⋯
line_char         = bytes([0xE2, 0x94, 0x80]).decode("utf-8") # \u2500 ─
upper_left_char   = bytes([0xE2, 0x95, 0xAD]).decode("utf-8") # \u256D ╭
lower_left_char   = bytes([0xE2, 0x95, 0xB0]).decode("utf-8") # \u2570 ╰
less_than_char    = bytes([0xE2, 0x9D, 0xAE]).decode("utf-8") # \u276E ❮
greater_than_char = bytes([0xE2, 0x9D, 0xAF]).decode("utf-8") # \u276F ❯
arrow_char        = bytes([0xE2, 0x96, 0xB7]).decode("utf-8") # \u25B7 ▷
home_char         = bytes([0xEF, 0x9F, 0x9B]).decode("utf-8") # \uF7DB 
user_char         = bytes([0xEF, 0x80, 0x87]).decode("utf-8") # \uF007 
host_char         = bytes([0xEE, 0x82, 0xA2]).decode("utf-8") # \uE0A2 
dir_char          = bytes([0xEE, 0x97, 0xBF]).decode("utf-8") # \uEE97 
file_char         = bytes([0xEF, 0x85, 0x9B]).decode("utf-8") # \uF15B 
floppy_char       = bytes([0xEF, 0x83, 0x87]).decode("utf-8") # \uF0C7 
visible_char      = bytes([0xEF, 0x81, 0xAE]).decode("utf-8") # \uF06E 
invisible_char    = bytes([0xEF, 0x81, 0xB0]).decode("utf-8") # \uF070 
clock_char        = bytes([0xEF, 0x80, 0x97]).decode("utf-8") # \uF017 

fg_escape = "\033[38;5;"
bg_escape = "\033[48;5;"
rs_escape = "\033[m"
end = "m"

hex_prefix, hex_hash = '0x', '#'
strip_regex = r'(..)(..)(..)'

lo_8_colors = [
    '000000', '800000', '008000', '808000',
    '000080', '800080', '008080', 'c0c0c0'
]

hi_8_colors = [
    '808080', 'ff0000', '00ff00', 'ffff00',
    '0000ff', 'ff00ff', '00ffff', 'ffffff'
]

basic_16 = lo_8_colors + hi_8_colors

increments = (0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff)
color_matrix_increments = range(95, 256, 40)


class SExec:

    def __init__(self, _command):

        _process = Popen(
            _command,
            shell=True,
            stdout=PIPE,
            stderr=STDOUT,
            close_fds=True
        )

        if _process.stderr is None:
            self.stdout = (_process.stdout.read()).decode("utf-8")
            self.return_code = _process.returncode

        else:
            self.stdout = None
            self.stderr = _process.stderr.decode("utf-8")


def reset(): return "%s" % rs_escape


def pfs( s ): print( s, end='' )


def nl(): print( reset() )


def fgs( ansi_color ): return "%s%s%s" % (fg_escape, ansi_color, end)


def bgs( ansi_color ): return "%s%s%s" % (bg_escape, ansi_color, end)


def power_of_byte():

    p = []
    prefix = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    size = [1 << 10 * i for i in range(len(prefix))]
    [p.append([prefix[i], size[i]]) for i in range(len(prefix))]
    return p


def humanize_bytes( _bytes ):

    pob = power_of_byte()

    if _bytes == 0:
        return str(_bytes) + " Bytes"

    for i in range(len(pob)):
        if pob[i - 1][1] <= _bytes < pob[i][1]:
            s = "%.2f %s" % (float(_bytes) / pob[i - 1][1], pob[i - 1][0])
            if int(s.split(".")[0]) == 1:
                return s
            else:
                return s + "s"


def color_cube_matrix():

    hex_list = ["00"]
    for value in color_matrix_increments:
        hex_list.append(hex(value).lstrip(hex_prefix))
    rgb_hex_lists = [hex_list] * 3

    return list(itertools.product(*rgb_hex_lists))


def string_color_cube_matrix():

    color_cube_values = list()
    color_cube = color_cube_matrix()
    for entry in color_cube:
        color_cube_values.append(''.join([hex_value for hex_value in entry]))

    return color_cube_values


def ansi_16_dict():

    ansi_16_colors = dict()
    for index_value in range(16):
        ansi_16_colors.update({str(index_value): basic_16[index_value]})

    return ansi_16_colors


def ansi_216_dict():

    ansi_216_colors = dict()
    basic_216 = string_color_cube_matrix()
    for index_value in range(216):
        ansi_216_colors.update({str(index_value + 16): basic_216[index_value]})

    return ansi_216_colors


def grayscale_dict():

    gs_colors = dict()
    gsk = [k for k in range(232, 256)]
    gsv = [hex(v).lstrip('0x').zfill(2)*3 for v in range(8, 239, 10)]
    for i in range(0, len(gsk)):
        gs_colors.update({str(gsk[i]): gsv[i]})

    return gs_colors


def ansi_256_dict( prompt ):
    basic_216 = {**ansi_16_dict(), **ansi_216_dict()}
    prompt['ansi256_dict'] = {**basic_216, **grayscale_dict()}


def terminal_size( prompt ):

    term_size = SExec('stty size').stdout

    prompt['rows'] = int(term_size.split(' ')[0])
    prompt['cols'] = int(term_size.split(' ')[1])
    prompt['remaining'] = prompt['cols']


def currentShell( prompt ):

    shell = SExec("ps -p $$ | tail -n 1 | grep -oE '[^ ]+$'").stdout.replace('\n', '')

    prompt['shell'] = shell
    prompt['shell_size'] = len(shell)


def hostname( prompt ):

    host = SExec('hostname').stdout.replace('\n', '')

    if '.' in host:
        host = host.split('.')[0]

    prompt['hostname'] = host
    prompt['hostname_size'] = len(host)


def username( prompt ):

    user = SExec('whoami').stdout.replace('\n', '')

    prompt['username'] = user
    prompt['username_size'] = len(user)


def shorten_path( length, prompt ):

    home_folder = "/home/{0}".format(prompt['username'])
    path = SExec('pwd').stdout.replace("\n", "").replace(home_folder, home_char)

    while len(path) > length:
        dirs = path.split("/")
        max_index  = -1
        max_length = 3

        for i in range(len(dirs) - 1):
            if len(dirs[i]) > max_length:
                max_index  = i
                max_length = len(dirs[i])

        if max_index >= 0:
            dirs[max_index] = dirs[max_index][:max_length-3] + "…"
            path = "/".join(dirs)

        else:
            break

    prompt['path'] = path
    prompt['path_size'] = len(path)


def dir_info( prompt ):

    system = platform

    dir_regex = rcompile('^d')
    dot_regex = rcompile('^\.')
    spl_regex = rcompile(' +')

    total = 0

    total_files = 0
    total_dirs = 0

    visible_files = 0
    hidden_files = 0

    visible_dirs = 0
    hidden_dirs = 0

    total_bytes = 0

    dir_info = SExec('ls -lA').stdout

    for line in dir_info.split('\n')[1:]:

        elements = rsplit(spl_regex, line.replace('\n', ''))

        try:

            if len(elements) == 9:

                size = int(elements[4])
                name = elements[8]
                total += size

                if rmatch(dir_regex, line):
                    try:
                        if rmatch(dot_regex, name):
                            hidden_dirs += 1
                        else:
                            visible_dirs += 1
                    except IndexError:
                        pass
                else:
                    try:
                        if rmatch(dot_regex, name):
                            hidden_files += 1
                        else:
                            visible_files += 1
                    except IndexError:
                        pass

        except ValueError:
            pass

    total_files = visible_files + hidden_files
    total_dirs = visible_dirs + hidden_dirs
    total_bytes = humanize_bytes(total)

    prompt['total_files'] = total_files
    prompt['total_dirs'] = total_dirs
    prompt['visible_files'] = visible_files
    prompt['hidden_files'] = hidden_files
    prompt['visible_dirs'] = visible_dirs
    prompt['hidden_dirs'] = hidden_dirs
    prompt['total_bytes'] = total_bytes

    prompt['total_files_size'] = len(str(total_files))
    prompt['total_dirs_size'] = len(str(total_dirs))
    prompt['visible_files_size'] = len(str(visible_files))
    prompt['hidden_files_size'] = len(str(hidden_files))
    prompt['visible_dirs_size'] = len(str(visible_dirs))
    prompt['hidden_dirs_size'] = len(str(hidden_dirs))
    prompt['total_bytes_size'] = len(str(total_bytes))


def color_sample( prompt, out=False ):

    if out == True: print()

    column = 1
    fg_1, fg_2 = 0, 255
    basic_16_colors = [c for c in range(1, 17)]
    gray_shades = [g for g in range(232, 251)]
    basic = basic_16_colors + gray_shades
    basic_index = 0

    fg_brightness = dict()

    for ansi in range(16, 232):
        if (column - 1) % 18 == 0:
            fg_1, fg_2 = fg_2, fg_1
        if out == True: pfs( bgs(ansi) + fgs(fg_1) + "%4d" % ansi + reset() )
        fg_brightness.update({ansi: fg_1})
        if column % 6 == 0:
            for index in range(5, -2, -1):
                if index > -1:
                    fg_color = ansi - index
                    if out == True: pfs( fgs(fg_color) + "%4d" % fg_color + reset() )
                else:
                    if basic_index < len(basic):
                        fg_color = basic[basic_index]
                        if out == True: pfs( fgs(fg_color) + "%4d" % fg_color + reset() )
                        basic_index += 1
            if out == True: print("\n", end='')
        column += 1
    column = 1
    fg_1, fg_2 = 0, 255
    for ansi in [g for g in range(232, 256)]:
        if (column - 1) % 18 == 0:
            fg_1, fg_2 = fg_2, fg_1
        if out == True: pfs( bgs(ansi) + fgs(fg_1) + "%s" % "    " + reset() )
        if column % 6 == 0:
            for index in range(5, -2, -1):
                if index > -1:
                    fg_color = ansi - index
                    if out == True: pfs( fgs(fg_color) + "%4d" % fg_color + reset() )
            if out == True: print("\n", end='')
        column += 1

    if out == True: print()

    prompt['fg_brightness'] = fg_brightness


def draw_first_char( bg_color, prompt ):

    char = dict()
    char['string'] = bgs(0)
    char['string'] += fgs(15) + upper_left_char
    char['string'] += fgs(bg_color) + sep_left_char
    char['size'] = 2
    prompt['fstc'] = char


def draw_user(prompt, bg_color, fg_color1, fg_color2, next_color):
    user_dict = dict()
    user_dict['string'] = bgs(bg_color) + fgs(fg_color1)
    user_dict['string'] += " {}".format(user_char) # 2 chars
    user_dict['string'] += fgs(fg_color2)
    user_dict['string'] += " {} ".format(prompt['username']) # +2 chars
    user_dict['string'] += bgs(next_color) + fgs(bg_color)
    user_dict['string'] += "{}".format(sep_right_char) # +1 char
    user_dict['size'] = prompt['username_size'] + 5

    prompt['user'] = user_dict


def draw_host(prompt, bg_color, fg_color1, fg_color2, next_color):
    host_dict = dict()
    host_dict['string'] = bgs(bg_color) + fgs(fg_color1)
    host_dict['string'] += " {}".format(host_char) # 2 chars
    host_dict['string'] += fgs(fg_color2)
    host_dict['string'] += " {} ".format(prompt['hostname']) # +2 chars
    host_dict['string'] += bgs(next_color) + fgs(bg_color)
    host_dict['string'] += "{}".format(sep_right_char) # +1 char
    host_dict['size'] = prompt['hostname_size'] + 5

    prompt['host'] = host_dict


def draw_diri(prompt, bg_color, fg_color1, fg_color2, fg_color3, fg_color4, next_color, left=False):

    dir_dict = dict()
    dir_dict['string'] = bgs(bg_color) + fgs(fg_color4)
    dir_dict['string'] += " {}".format(dir_char) # 2 chars
    dir_dict['string'] += fgs(fg_color1)
    dir_dict['string'] += " {}".format(prompt['total_dirs']) # +1 char
    dir_dict['size'] = prompt['total_dirs_size'] + 3

    if int(prompt['hidden_dirs']) > 0:
        dir_dict['string'] += fgs(fg_color2)
        dir_dict['string'] += "{}{}".format(visible_char, prompt['visible_dirs']) # +1 char
        dir_dict['string'] += fgs(fg_color3)
        dir_dict['string'] += "{}{} ".format(invisible_char, prompt['hidden_dirs']) # +2 chars
        dir_dict['size'] += prompt['visible_dirs_size'] + prompt['hidden_dirs_size'] + 3
    else:
        dir_dict['string'] += " "
        dir_dict['size'] += 1

    if left:
        dir_dict['string'] += bgs(0) + fgs(bg_color)
        dir_dict['string'] += "{}".format(sep_right_char) # +1 char
        dir_dict['string'] += fgs(next_color) + sep_left_char
        dir_dict['size'] += 3
    else:
        dir_dict['string'] += bgs(next_color) + fgs(bg_color)
        dir_dict['string'] += "{}".format(sep_right_char) # +1 char
        dir_dict['size'] += 1

    prompt['diri'] = dir_dict


def draw_fili(prompt, bg_color, fg_color1, fg_color2, fg_color3, fg_color4, next_color):

    file_dict = dict()
    file_dict['string'] = bgs(bg_color) + fgs(fg_color4)
    file_dict['string'] += " {}".format(file_char) # 2 chars
    file_dict['string'] += fgs(fg_color1)
    file_dict['string'] += " {}".format(prompt['total_files']) # +1 char
    file_dict['size'] = prompt['total_files_size'] + 3

    if int(prompt['hidden_files']) > 0:
        file_dict['string'] += fgs(fg_color2)
        file_dict['string'] += "{}{}".format(visible_char, prompt['visible_files']) # +1 char
        file_dict['string'] += fgs(fg_color3)
        file_dict['string'] += "{}{} ".format(invisible_char, prompt['hidden_files']) # +2 chars
        file_dict['size'] += prompt['visible_files_size'] + prompt['hidden_files_size'] + 3
    else:
        file_dict['string'] += " "
        file_dict['size'] += 1

    file_dict['string'] += bgs(next_color) + fgs(bg_color)
    file_dict['string'] += "{}".format(sep_right_char) # +1 char
    file_dict['size'] += 1

    prompt['fili'] = file_dict


def draw_total_size(prompt, bg_color, fg_color1, fg_color2, next_color):

    size_dict = dict()
    size_dict['string'] = bgs(bg_color) + fgs(fg_color1)
    size_dict['string'] += " {} ".format(floppy_char) # 3 chars
    size_dict['string'] += fgs(fg_color2)
    size_dict['string'] += "{} ".format(prompt['total_bytes']) # +1 char
    size_dict['string'] += bgs(next_color) + fgs(bg_color)
    size_dict['string'] += "{}".format(sep_right_char) # +1 char
    size_dict['size'] = prompt['total_bytes_size'] + 5

    prompt['size'] = size_dict


def draw_path(prompt, bg_color, fg_color1, next_color):

    path_dict = dict()
    empty = prompt['remaining'] - prompt['path_size']
    path_dict['string'] = bgs(bg_color) + fgs(fg_color1)
    path_dict['string'] += " {} ".format(prompt['path']) # path_size + 2 chars
    if empty > 0:
        path_dict['string'] += " " * empty
    path_dict['string'] += bgs(next_color) + fgs(bg_color)
    path_dict['string'] += "{}".format(sep_right_char) # +1 char
    path_dict['size'] = prompt['path_size'] + 3
    if empty > 0:
        path_dict['size'] += empty

    prompt['pwd'] = path_dict


def draw_clock(prompt, bg_color, fg_color1, fg_color2, fg_color3, next_color):

    now = datetime.now()
    clock_dict = dict()
    clock_dict['string'] = bgs(bg_color) + fgs(fg_color1)
    clock_dict['string'] += " {} ".format(clock_char) # 3 chars
    clock_dict['string'] += fgs(fg_color2)
    clock_dict['string'] += now.strftime("%H") # 2 chars
    clock_dict['string'] += fgs(fg_color3)
    clock_dict['string'] += ":" # 1 char
    clock_dict['string'] += fgs(fg_color2)
    clock_dict['string'] += now.strftime("%M") # 2 chars
    clock_dict['string'] += fgs(fg_color3)
    clock_dict['string'] += ":" # 1 char
    clock_dict['string'] += fgs(fg_color2)
    clock_dict['string'] += now.strftime("%S") + " " # 3 chars
    clock_dict['string'] += bgs(next_color) + fgs(bg_color)
    clock_dict['string'] += "{}".format(sep_right_char) # 1 chars
    clock_dict['size'] = 13

    prompt['clock'] = clock_dict


def draw_prompt(prompt):
    
    prompt['string'] = ""

    white = 15
    black = 16

    light_gray = 247
    dark_gray = 235

    cyan = 39
    blue = 33
    orange = 202

    user_bg_color = 39
    host_bg_color = 33

    path_bg_color = 235

    dirs_bg_color = 237
    files_bg_color = 239
    size_bg_color = 241


    clock_bg_color = 202

    draw_first_char(user_bg_color, prompt)

    draw_user(prompt, user_bg_color, white, black, host_bg_color)
    draw_host(prompt, host_bg_color, white, black, path_bg_color)

    draw_diri(prompt, dirs_bg_color, white, light_gray, dark_gray, cyan, files_bg_color)
    draw_fili(prompt, files_bg_color, white, light_gray, dark_gray, blue, size_bg_color)
    draw_total_size(prompt, size_bg_color, cyan, white, clock_bg_color)

    draw_clock(prompt, clock_bg_color, white, black, dark_gray, 0)

    prompt['remaining'] -= (
        prompt['fstc']['size'] + \
        prompt['user']['size'] + \
        prompt['host']['size'] + \
        prompt['diri']['size'] + \
        prompt['fili']['size'] + \
        prompt['size']['size'] + \
        prompt['clock']['size'] + 3
    )

    shorten_path(prompt['remaining'], prompt)
    draw_path(prompt, path_bg_color, white, dirs_bg_color)

    prompt['string']  = prompt['fstc']['string']
    prompt['string'] += prompt['user']['string']
    prompt['string'] += prompt['host']['string']

    prompt['string'] += prompt['pwd']['string']

    prompt['string'] += prompt['diri']['string']
    prompt['string'] += prompt['fili']['string']
    prompt['string'] += prompt['size']['string']

    prompt['string'] += prompt['clock']['string']
    prompt['string'] += rs_escape + "\n"

    prompt['string'] += lower_left_char + line_char + arrow_char # greater_than_char
    prompt['string'] +=  "{} ".format(rs_escape)

    pfs(prompt['string'])


if __name__ == "__main__":

    start = timer()

    prompt = dict()

    length = 25

    ansi_256_dict(prompt)
    terminal_size(prompt)
    hostname(prompt)
    username(prompt)
    dir_info(prompt)
    color_sample(prompt, False)

    draw_prompt(prompt)

    end = timer()
    exec_time = ( end - start ) * 1000