require 'json'
require 'net/http'

module Pollex
  Drop = Struct.new(:slug) do
    API_DOMAIN = URI.parse("http://#{ENV.fetch('CLOUDAPP_DOMAIN')}")

    def self.download(slug)
      new(slug).file
    end

    def file
      Tempfile.open(filename) do |img|
        download_file(img)
        img
      end
    end

    protected

    def remote_url
      @remote_url ||= fetch_api['remote_url']
    end

    def filename
      File.basename(remote_url)
    end

    def uri
      @uri ||= URI.parse(remote_url)
    end

    def fetch_api
      api = nil
      Net::HTTP.start(API_DOMAIN.host, API_DOMAIN.port) do |http|
        request = Net::HTTP::Get.new("/#{slug}")
        request['accept'] = 'application/json'

        http.request(request) do |response|
          response.error! unless Net::HTTPSuccess === response
          api = JSON.parse(response.body)
        end
      end
      api
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
