require "nokogiri"

module GitTfs
  module TestBuilder
    class Changeset
      def self.from_xml_string(s)
        new Nokogiri::XML(s)
      end

      def initialize(xml)
        @xml = xml
      end

      def number
        element["cset"].to_i
      end

      def each_change
        @xml.xpath("//Changes/Change").each do |e|
          yield Change.new(e)
        end
      end

      def raw
        @xml.to_s
      end

      private

      def element
        @xml.root
      end
    end

    class Change
      def initialize(element)
        @element = element
      end

      def downloadable?
        item_type == "File" && !change_types.include?("Delete") && item_hash && download_query
      end

      def item_type
        item_element && item_element["type"]
      end

      def change_types
        change_element["type"].split(/ /)
      end

      def item_hash
        item_element && item_element["hash"]
      end

      def download_query
        item_element && item_element["durl"]
      end

      private

      def change_element
        @element
      end

      def item_element
        @element.xpath("./Item").first
      end
    end
  end
end
