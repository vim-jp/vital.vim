require 'pathname'

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
  sh "git checkout #{sha1} -- ."
  Dir.mkdir "#{yourdir}/autoload/vital" unless Dir.exist? File.expand_path "#{yourdir}/autoload/vital"
  File.rename 'autoload/vital/__latest__.vim', "autoload/vital/_#{sha1}.vim"
  Dir.mkdir "#{yourdir}/autoload/#{pluginname}" unless Dir.exist? File.expand_path "#{yourdir}/autoload/#{pluginname}"
  File.rename 'autoload/__plugin__', "autoload/#{pluginname}"
  Dir.glob("autoload/**/*") do |f|
    next if File.directory? f
    a = File.read f
    b = a.gsub(/__latest__/, "_#{sha1}")
    b = b.gsub(/__plugin__/, "#{pluginname}")
    if a != b
      File.open(f, 'w') do |io|
        io.write b
      end
    end
    File.copy_stream f, "#{yourdir}/#{f}"
  end
end
