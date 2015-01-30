module GitTfs
  module TestBuilder
    class TfsReader
      def initialize(options)
        @username = options.fetch(:username)
        @password = options.fetch(:password)
        @url = options.fetch(:url)
        @path = options.fetch(:path)
      end

      def each_changeset(options)
      end
    end
  end
end
