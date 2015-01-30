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

      def comment
        element.xpath("Comment").first.content
      end

      def date
        element["date"]
      end

      def changes
        @xml.xpath("//Changes/Change").map do |e|
          Change.new(e)
        end
      end

      def each_change(&block)
        changes.each(&block)
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
        item_attr "type"
      end

      def change_types
        change_element["type"].split(/ /)
      end

      def item_hash
        item_attr "hash"
      end

      # Convert something like "NurmtqRxc3Wk/xYod0TNHQ==" to something like "36eae6b6a4717375a4ff16287744cd1d"
      def item_hex_hash
        item_hash && item_hash.unpack("m").first.unpack("H*").first
      end

      def item_path
        item_attr "item"
      end

      def item_id
        item_attr "itemid"
      end

      def download_query
        item_attr "durl"
      end

      private

      def change_element
        @element
      end

      def item_element
        @element.xpath("./Item").first
      end

      def item_attr(name)
        item_element && item_element[name]
      end
    end
  end
end
