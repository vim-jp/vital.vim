import sys, vim

print("%s %d" % (
    vim.eval('prefix'),
    # .major is not supported by 2.6 and older.
    sys.version_info[0],
))
