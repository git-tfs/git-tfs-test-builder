$: << File.expand_path("lib", File.dirname(__FILE__))

begin
  require "git-tfs/test-builder"
rescue LoadError
  require "bundler/setup"
  require "git-tfs/test-builder"
end

require "optparse"

options = {}
optparser = OptionParser.new do |opts|
end

optparser.parse!
if ARGV.size != 2 || options[:user].nil? || options[:password].nil?
  puts optparser
  exit 1
end
options[:url] = ARGV[0]
options[:path] = ARGV[1]

test_builder = GitTfs::TestBuilder.new(options)
test_builder.run
