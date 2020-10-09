import os
import sys
import vim

sys.path.insert(0, os.path.abspath(vim.eval("s:script_folder_path")))
import fuzzycomt

sys.path.pop(0)


def ctrlp_cmatcher_match():
    lines = vim.eval("a:lines")
    searchinp = vim.eval("a:input")
    limit = int(vim.eval("a:limit"))
    mmode = vim.eval("a:mmode")
    ispath = int(vim.eval("a:ispath"))
    crfile = vim.eval("a:crfile")

    if ispath and crfile:
        try:
            lines.remove(crfile)
        except ValueError:
            pass

    try:
        # TODO we should support smartcase. Needs some fixing on matching side
        matchlist = fuzzycomt.sorted_match_list(lines, searchinp.lower(), limit, mmode)
    except:
        matchlist = []

    return matchlist
