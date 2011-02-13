require 'pathname'
require 'fileutils'

def sh(o)
  puts o
  system o or abort
end

if ARGV.size < 2
  warn "usage: ruby tmp__update.rb {vital.vim dir} {your project dir} [{sha1}]"
  warn "example: ruby tmp__update.rb ~/git/vital.vim ~/.vim/bundle/unite.vim 1896f2"
  abort
end

vitaldir = File.expand_path ARGV.shift
yourdir = File.expand_path ARGV.shift
pluginname = Pathname(yourdir).basename.to_s.sub(/\.vim$/, '').gsub(/\W/, '_')
sha1 = ARGV.shift

Dir.glob("autoload/vital/**/*.vim").each do |script|
  namespace = script[/^autoload\/vital\/(.*)\.vim$/, 1].
    gsub('/', '#')
  functions = File.read(script).scan(/\s*function!?\s+(vital##{namespace}#[\w#]*)/).map(&:first)
  target = script.sub("vital/__latest__", "__plugin__/vital")
  FileUtils.mkdir_p(Pathname(target).dirname.to_s)
  File.open(target, 'w') do |io|
    functions.each {|f|
      g = f.sub(/^vital#__latest__#/, "#{pluginname}#vital#")
      io.puts "function! #{g}(...)"
      io.puts "  return call('#{f}', a:000)"
      io.puts "endfunction"
    }
  end
end

placeholders = lambda do |x|
  x.gsub(/__latest__/, "_#{sha1}").
    gsub(/__plugin__/, "#{pluginname}")
end

Dir.chdir vitaldir do
  sha1 ||= `git show`[/commit (......)/, 1]
  puts sha1
  Dir.glob("autoload/**/*.vim") do |before|
    after = "#{yourdir}/#{placeholders.(before)}"
    FileUtils.mkdir_p(Pathname(after).dirname.to_s)
    x = placeholders.(File.read before)
    File.open(after, 'w') do |io|
      io.write x
    end
  end
end
