require 'pathname'
require 'fileutils'
require 'optparse'

def sh(o)
  puts o
  system o or abort
end

def writefile(fname, content)
  File.open(fname, 'w') {|io| io.write content }
end

pluginname = nil
opts = OptionParser.new
opts.on("-p", "--plugin-name NAME"){|name| pluginname = name}
opts.parse!(ARGV)

if ARGV.size < 2
  warn "usage: ruby vitalize.rb {vital.vim dir} {your project dir} [{sha1}] [-p pluginname]"
  warn "example: ruby vitalize.rb ~/git/vital.vim ~/.vim/bundle/unite.vim 1896f2"
  abort
end

vitaldir = File.expand_path ARGV.shift
yourdir = File.expand_path ARGV.shift
pluginname ||= Pathname(yourdir).basename.to_s.sub(/\.vim$/, '').gsub(/\W/, '_')
sha1 = ARGV.shift

placeholders = lambda do |x|
  x.gsub(/__latest__/, "_#{sha1}").
    gsub(/__plugin__/, "#{pluginname}")
end

FileUtils.rm_rf "#{yourdir}/autoload/vital"

Dir.chdir vitaldir do
  sha1 ||= `git show`[/commit (......)/, 1]
  puts sha1
  Dir.glob("autoload/**/*.vim") do |before|
    after = "#{yourdir}/#{placeholders.call(before)}"
    FileUtils.mkdir_p(Pathname(after).dirname.to_s)
    writefile(after, File.read(before))
  end
  writefile("#{yourdir}/autoload/vital/#{pluginname}.vital", sha1)
end
