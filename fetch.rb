$: << File.expand_path("lib", File.dirname(__FILE__))

require "bundler/setup"
require "git_tfs/test_builder/fetcher"

require "optparse"

options = {}
optparser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby fetch.rb -o DIR -u USERNAME@DOMAIN -p PASSWORD http://server/tfs/collection project"

  opts.on("-u", "--username USERNAME") do |v|
    options[:username] = v
  end

  opts.on("-p", "--password PASSWORD") do |v|
    options[:password] = v
  end

  opts.on("-o", "--outdir DIR") do |v|
    options[:outdir] = v
  end

  opts.on("-r", "--root-branch RELATIVE/PATH") do |v|
    options[:root_branch] = v
  end

  opts.on("-h", "--help", "Show this text") do
    puts opts
    exit 0
  end
end

optparser.parse!
if ARGV.size != 2
  puts optparser
  exit 1
end
options[:url] = ARGV[0]
options[:path] = ARGV[1]

fetcher =
  begin
    GitTfs::TestBuilder::Fetcher.new(options)
  rescue KeyError => e
    puts e.message, optparser
    exit 1
  end
fetcher.run
