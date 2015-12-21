import sys, vim
print("%s %d" % (
    vim.eval('prefix'),
    sys.version_info.major,
))
