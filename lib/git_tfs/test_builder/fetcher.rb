require "git_tfs/test_builder/archiver"
require "git_tfs/test_builder/tfs_reader"

module GitTfs
  module TestBuilder
    class Fetcher
      def initialize(options)
        @username = options.fetch(:username)
        @password = options.fetch(:password)
        @url = options.fetch(:url)
        @path = options.fetch(:path)
        @outdir = options.fetch(:outdir)
        @root_branch = options.fetch(:root_branch) { nil }
      end

      def run
        max_changeset = 0
        archiver.each_changeset do |changeset|
          max_changeset = changeset.number if changeset.number > max_changeset
          archive_files changeset
        end
        start_changeset = max_changeset + 1
        tfs_reader.each_changeset(:start => start_changeset) do |changeset|
          archiver.archive_changeset changeset
          archive_files changeset
        end
        if @root_branch
          archiver.archive_raw "branchinfo.xml", tfs_reader.read_branch_info(@root_branch)
        end
      end

      def archive_files(changeset)
        changeset.each_change do |change|
          if change.downloadable? && !archiver.has_change_item?(change)
            archiver.archive_change change, tfs_reader.download_item(change)
          end
        end
      end

      private

      def tfs_reader 
        @tfs_reader ||= TfsReader.new \
          :username => @username,
          :password => @password,
          :url => @url,
          :path => @path
      end

      def archiver
        @archiver ||= Archiver.new \
          :dir => @outdir
      end
    end
  end
end
