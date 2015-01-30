require "git_tfs/test_builder/changeset"

module GitTfs
  module TestBuilder
    class Archiver
      def initialize(options)
        @dir = options.fetch(:dir)
      end

      def each_changeset
        Dir[File.join(changeset_dir, "*.xml")].each do |changeset_path|
          yield Changeset.from_xml(File.read(changeset_path))
        end
      end

      private

      def changeset_dir
        File.join(@dir, "changesets")
      end
    end
  end
end
