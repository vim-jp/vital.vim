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
pluginname = Pathname(yourdir).basename.to_s
sha1 = ARGV.shift

Dir.chdir vitaldir do
  sha1 ||= `git show`[/commit (......)/, 1]
  puts sha1
  Dir.glob("autoload/**/*") do |before|
    next if File.directory? before
    after =
      case before
      when 'autoload/vital/__latest__.vim'
        "#{yourdir}/autoload/vital/_#{sha1}.vim"
      when 'autoload/__plugin__/vital.vim'
        "#{yourdir}/autoload/#{pluginname}/vital.vim"
      else
        "#{yourdir}/#{before}"
      end
    FileUtils.mkdir_p(Pathname(after).dirname.to_s)
    x = File.read before
    x = x.gsub(/__latest__/, "_#{sha1}")
    x = x.gsub(/__plugin__/, "#{pluginname}")
    File.open(after, 'w') do |io|
      io.write x
    end
  end
end
