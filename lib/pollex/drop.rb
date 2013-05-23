require 'json'
require 'net/http'

module Pollex
  Drop = Struct.new(:slug) do

    # Allow brackets in URLs
    def self.uri_parser
      @uri_parser ||=
        URI::Parser.new(UNRESERVED: URI::REGEXP::PATTERN::UNRESERVED + "\\[\\]")
    end

    CLOUDAPP_DOMAIN = ENV.fetch('CLOUDAPP_DOMAIN', 'api.cld.me')
    API_URI         = uri_parser.parse("http://#{CLOUDAPP_DOMAIN}")

    def found?
      !fetch_api.nil?
    end

    # TODO: Set a timeout on the download
    def file
      Tempfile.open([ slug, extension ]) do |img|
        download_file(img)
        img
      end
    end

    def type
      fetch_api['item_type']
    end

    def extension
      File.extname(remote_url)
    end

    protected

    def remote_url
      fetch_api['remote_url']
    end

    def uri
      self.class.uri_parser.parse(remote_url)
    end

    def fetch_api
      @api_response ||= begin
        api = nil
        Net::HTTP.start(API_URI.host, API_URI.port) do |http|
          request = Net::HTTP::Get.new("/#{slug}")
          request['accept'] = 'application/json'

          http.request(request) do |response|
            api = JSON.parse(response.body) if Net::HTTPSuccess === response
          end
        end
        api
      end
    end

    def download_file(img)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          response.read_body do |chunk|
            img.write(chunk)
          end
        end
      end
    end
  end
end
