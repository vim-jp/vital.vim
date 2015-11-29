ChangesPath = ARGV[0] || 'Changes'
raise "#{ChangesPath} does not exist" unless File.exists? ChangesPath

def git_hash?(hash)
  system "git rev-parse --quiet --verify #{hash} > /dev/null"
end

def check(change)
  success = true
  git_hash, *description = change

  unless git_hash?(git_hash)
    STDERR.puts "Commit '#{git_hash}' does not exist in this repository."
    success = false
  end

  case
  when description.empty?
    STDERR.puts "No description for commit '#{git_hash}'"
    success = false
  when description.first !~ /^\tModules:\s+/
    STDERR.puts "Description must start with 'Modules:': #{description.first}"
    success = false
  end

  description.each do |line|
    unless line =~ /^\t/
      STDERR.puts "All lines of description must start with \\t: #{line}"
      success = false
    end
  end

  success
end

success = File.foreach(ChangesPath)
  .slice_before{|l| l =~ /^\h+$/ }
  .map{|b| b.map(&:chop!)}
  .map{|c| check c}
  .all?

exit(success ? 0 : 1)
