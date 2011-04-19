# String in Vim script -> [Name of modules]
# strategy: upper limit of all literally written keywords
def modules_used(code)
  lines = code.each_line.inject([]) {|memo, line|
    if /^\s*\\(.*)/ =~ line
      memo.last << $1
      memo
    else
      memo.push line
    end
  }.map {|line| line.sub(/"[^"]*$/, '') }
  ['Prelude'] + lines.join.scan(/[A-Z]\w+(?:\W[A-Z]\w+)*/).uniq
end

puts modules_used File.read ARGV.shift || abort('ERROR: Give me a file name')
