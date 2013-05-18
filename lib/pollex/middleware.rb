module Pollex
  class Middleware
    attr_accessor :slug

    def initialize(path)
      @slug = File.basename(path)
    end

    def self.call(env)
      new(env['PATH_INFO']).serve
    end

    def serve(downloader = Drop, thumber = Thumb)
      file  = downloader.download(slug)
      thumb = thumber.new(file, slug)
      response(thumb)
    end

    def response(thumb)
      [ 200, { 'Content-Length' => thumb.size.to_s }, thumb ]
    end
  end
end
