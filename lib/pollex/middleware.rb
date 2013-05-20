module Pollex
  class Middleware
    attr_accessor :slug

    def initialize(path)
      @slug = File.basename(path)
    end

    def self.call(env)
      new(env['PATH_INFO']).serve
    end

    def serve(drop_class = Drop, thumb_class = Thumb)
      drop  = drop_class.new(slug)
      return not_found  unless drop.found?
      return icon(drop) unless image?(drop)

      thumb = thumb_class.new(drop.file, slug)
      return error unless thumb.success?

      response(thumb)
    end

    protected

    def response(thumb)
      [ 200, { 'Content-Length' => thumb.size.to_s }, thumb ]
    end

    def not_found
      [ 404, { 'Content-Type' => 'text/html' },
        File.open('public/not-found.html') ]
    end

    def error
      [ 500, { 'Content-Type' => 'text/html' },
        File.open('public/error.html') ]
    end

    def icon(drop)
      [ 307, { 'Location' => "/icons/#{drop_type(drop)}.png" }, [] ]
    end

    def image?(drop)
      drop_type(drop) == :image
    end

    def drop_type(drop)
      return :bookmark if drop.type == 'bookmark'

      extension = File.extname(drop.filename)
      return :image if image_extensions.include?(extension)

      icon_exists?(drop.type) ? drop.type : 'unknown'
    end

    def icon_exists?(type)
      File.exists?(File.join(Dir.pwd, 'public', 'icons', "#{ type }.png"))
    end

    def image_extensions
      %w( .bmp
          .gif
          .ico
          .jp2
          .jpe
          .jpeg
          .jpf
          .jpg
          .jpg2
          .jpgm
          .png )
    end
  end
end
