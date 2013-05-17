require 'cgi'
require 'json'
require 'net/http'
require 'open3'
require 'tempfile'
require 'uri'

class Thumb
  API_DOMAIN = URI.parse("http://#{ENV.fetch('CLOUDAPP_DOMAIN')}")

  attr_accessor :slug, :remote_url

  def self.call(env)
    path = env['PATH_INFO']
    return [404, {}, []] if path == '/favicon.ico'

    new(path).call
  end

  def initialize(path)
    @slug = File.basename(path)
  end

  def call
    fetch_api
    download
    thumbnail
    serve
  end

  def fetch_api
    Net::HTTP.start(API_DOMAIN.host, API_DOMAIN.port) do |http|
      request = Net::HTTP::Get.new("/#{slug}")
      request['accept'] = 'application/json'

      http.request(request) do |response|
        response.error! unless Net::HTTPSuccess === response
        @remote_url = JSON.parse(response.body)['remote_url']
      end
    end
  end

  def filename
    File.basename(remote_url)
  end

  def uri
    @uri ||= URI.parse(remote_url)
  end

  def img
    @img ||= Tempfile.open(filename)
  end

  def output_img
    @output_img ||= Tempfile.open("#{slug}.png")
  end

  def download
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request) do |response|
        begin
          response.read_body do |chunk|
            img.write(chunk)
          end
        ensure
          img.close
        end
      end
    end
  end

  # identify -ping /mini_magick20130516-96543-xa2m5b.png
  # mogrify -format png /mini_magick20130516-96543-xa2m5b.png
  # identify -ping -quiet -format "%w\\n" "/mini_magick20130516-96543-xa2m5b.png"
  # identify -ping -quiet -format "%h\\n" "/mini_magick20130516-96543-xa2m5b.png"
  # mogrify -resize "200x150^" -gravity "northwest" -crop "200x150+0+0" +repage -background "transparent" -gravity "center" -extent "200x150" /mini_magick20130516-96543-xa2m5b.png
  def thumbnail
    system 'convert', *convert_arguments
  end

  def convert_arguments
    args = %W(-gravity northwest
              -crop 200x150+0+0
              +repage
              -background red
              -gravity center
              -extent 200x150
              #{img.path}[0]
              #{output_img.path})
    args.unshift *%w(-resize 200x150^) if image_too_large?
    args
  end

  def image_too_large?
    identify_command = %w(identify -quiet -format %w\ %h)
    stdout, status   = Open3.capture2(*identify_command, img.path)
    width,  height   = stdout.chomp.split(' ').map(&:to_i)
    width > 200 && height > 150
  end

  def serve
    [ 200, { 'Content-Length' => File.size(output_img.path).to_s }, self ]
  end

  def each
    File.open(output_img.path, "rb") do |file|
      while (part = file.read(8192))
        yield part
      end
    end
  end
end

run Thumb
