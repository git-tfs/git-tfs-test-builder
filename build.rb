$: << File.expand_path("lib", File.dirname(__FILE__))

require "bundler/setup"
require "git_tfs/test_builder/builder.rb"

require "optparse"

options = {}
optparser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby build.rb DIR"

  opts.on("-h", "--help", "Show this text") do
    puts opts
    exit 0
  end
end

optparser.parse!
if ARGV.size == 1
  options[:dir] = ARGV[0]
else
  puts optparser
  exit 1
end

builder =
  begin
    GitTfs::TestBuilder::Builder.new(options)
  rescue KeyError => e
    puts e.message, optparser
    exit 1
  end
builder.run
