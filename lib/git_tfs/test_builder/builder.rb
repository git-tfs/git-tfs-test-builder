require "git_tfs/test_builder/archiver"
require "git_tfs/test_builder/test_script_builder"

module GitTfs
  module TestBuilder
    class Builder
      def initialize(options)
        @dir = options.fetch(:dir)
        @name = options.fetch(:name) { File.basename(@dir) }
      end

      def run
        archiver.each_changeset do |changeset|
          test_script_builder << changeset
        end
        File.open(cs_file, "w") do |f|
          test_script_builder.write f
        end
      end

      private

      def cs_file
        File.join @dir, "#{@name}.cs"
      end

      def archiver
        @archiver ||= Archiver.new \
          :dir => @dir
      end

      def test_script_builder
        @test_script_builder ||= TestScriptBuilder.new \
          :name => @name
      end
    end
  end
end
