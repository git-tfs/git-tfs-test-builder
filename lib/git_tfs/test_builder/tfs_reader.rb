require "builder"
require "nokogiri"
require "typhoeus"
require "uri"

require "git_tfs/test_builder/changeset"

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
        start = options.fetch(:start) { 1 }
        querying = true
        while querying do
          res = soap_request :repository, "QueryHistory", :tfs_path => tfs_path, :start => start
          raise RequestError.new(res) unless res.response_code == 200
          xml = Nokogiri::XML(res.body)
          querying = false
          xml.xpath("//*[local-name() = 'Changeset']").each do |e|
            # Extract the changeset into an independent XML doc.
            cs = Changeset.from_xml_string(e.to_s)
            yield cs
            start = cs.number + 1
            querying = true
          end
        end
      end

      def download_item(change)
        res = Typhoeus.get download_url(change), default_request_options
        raise RequestError.new(res) unless res.response_code == 200
        res.body
      end

      def read_branch_info(root_branch)
        res = soap_request :repository_v3, "QueryBranchObjects", :path => File.join(tfs_path, root_branch)
        raise RequestError.new(res) unless res.response_code == 200
        xml = Nokogiri::XML(res.body)
        return xml.xpath("//*[local-name() = 'QueryBranchObjectsResult']").first.to_s
      end

      private

      def soap_request(service_id, action, req_options = {})
        service = Services.fetch(service_id)
        request_options = default_request_options.merge \
          :body => build_request_body(service, action, req_options),
          :headers => build_request_headers(service, action)
        Typhoeus.post endpoint_url(service), request_options
      end

      def default_request_options
        {
          :verbose => ENV["DEBUG"] == "y",
          :httpauth => :ntlm,
          :username => @username,
          :password => @password,
        }
      end

      Services = {
        :repository => {
          :path => "VersionControl/v1.0/repository.asmx",
          :xmlns => "http://schemas.microsoft.com/TeamFoundation/2005/06/VersionControl/ClientServices/03",
          :req_body => {
            "QueryHistory" => lambda do |req, options|
              tfs_path = options.fetch(:tfs_path)
              start = options.fetch(:start)
              max_count = options.fetch(:max_count, 256)

              req.itemSpec :item => tfs_path, :recurse => 'Full', :did => '0'
              req.versionItem 'xsi:type' => 'LatestVersionSpec'
              req.versionFrom 'xsi:type' => 'ChangesetVersionSpec', :cs => start
              req.maxCount max_count
              req.includeFiles true
              req.generateDownloadUrls true
              req.slotMode true # http://blogs.msdn.com/b/mitrik/archive/2009/05/28/changing-to-slot-mode-in-tfs-2010-version-control.aspx
              req.sortAscending true # require TFS 2010 or newer http://msdn.microsoft.com/en-us/library/microsoft.teamfoundation.versioncontrol.client.queryhistoryparameters.sortascending.aspx
            end,
          },
        },
        :download => {
          :path => "VersionControl/v1.0/item.ashx",
        },
        :repository_v3 => {
          :path => "VersionControl/v3.0/repository.asmx",
          :xmlns => "http://schemas.microsoft.com/TeamFoundation/2005/06/VersionControl/ClientServices/03",
          :req_body => {
            "QueryBranchObjects" => lambda do |req, options|
              if path = options[:path]
                req.item :it => path, :ctype => 4096-1 do
                  req.Version "xsi:type" => "LatestVersionSpec"
                end
              end
              req.recursion(options[:recursion_type] || "Full")
            end,
          },
        },
      }

      def endpoint_url(service)
        path = service.fetch(:path)
        @url.end_with?("/") ? "#{@url}#{path}" : "#{@url}/#{path}"
      end

      def download_url(change)
        "#{endpoint_url(Services.fetch(:download))}?#{change.download_query}"
      end

      def build_request_body(service, action, req_options)
        xml = ''
        builder = Builder::XmlMarkup.new :target => xml
        builder.instruct!
        builder.soap :Envelope, 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/', 'xmlns' => service.fetch(:xmlns) do
          builder.soap :Body do
            builder.tag! action do
              if block = service[:req_body][action]
                block.call(builder, req_options)
              end
            end
          end
        end
        xml
      end

      def build_request_headers(service, action)
        {
          'SOAPAction'   => "\"#{soap_action(service, action)}\"",
          'Content-Type' => 'text/xml; charset=UTF-8',
        }
      end

      def soap_action(service, action)
        request_namespace = service.fetch(:xmlns)
        request_namespace + (request_namespace.end_with?('/') ? '' : '/') + action
      end

      # A path that starts with "$/"
      def tfs_path
        case @path[0]
        when "$"
          @path
        when "/"
          "$#{@path}"
        else
          "$/#{@path}"
        end
      end
    end
  end
end
