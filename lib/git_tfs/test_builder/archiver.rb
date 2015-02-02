require "fileutils"

require "git_tfs/test_builder/changeset"

module GitTfs
  module TestBuilder
    class Archiver
      def initialize(options)
        @dir = options.fetch(:dir)
      end

      def each_changeset
        Dir[File.join(changeset_dir, "*.xml")].each do |changeset_path|
          yield Changeset.from_xml_string(File.read(changeset_path))
        end
      end

      def archive_changeset(changeset)
        changeset_path = File.join(changeset_dir, "#{changeset.number}.xml")
        $stderr.puts "Writing to #{changeset_path}:\n#{changeset.raw}" if ENV["DEBUG"] == "y"
        File.open(changeset_path, "w") do |f|
          f.write changeset.raw
        end
      end

      def has_change_item?(change)
        File.exist?(change_path(change))
      end

      def archive_change(change, content)
        if content
          File.open(change_path(change), "wb") do |f|
            f.write content
          end
        end
      end

      def archive_raw(name, data)
        File.open(raw_path(name), "wb") do |f|
          f.write data
        end
      end

      private

      def raw_path(name)
        File.join(@dir, name)
      end

      def change_path(change)
        File.join(change_dir, change.item_hex_hash)
      end

      def changeset_dir
        @changes_dir ||= ensure_subdir("changesets")
      end

      def change_dir
        @change_dir ||= ensure_subdir("content")
      end

      def ensure_subdir(name)
        File.join(@dir, name).tap do |path|
          FileUtils.mkdir_p path
        end
      end
    end
  end
end
