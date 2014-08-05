module Pollex
  class Middleware
    SLUG_MATCHER = %r{/(?:text|code|image)?/?(?<slug>\w+)}

    attr_accessor :slug

    def initialize(path)
      @slug = path.match(SLUG_MATCHER)[:slug]
    end

    def self.call(env)
      new(env['PATH_INFO']).serve
    end

    def serve(drop_class = Drop, thumb_class = Thumb)
      drop  = drop_class.new(slug)
      file = StoredFile.new("#{slug}.png")

      return not_found  unless drop.found?
      return icon(drop) unless image?(drop)

      return redirect(file.url) if file.exists?

      thumb = thumb_class.new(drop.file, slug)
      return error unless thumb.success?

      file.create!(thumb)

      return redirect(file.url) if file.exists?

      response(thumb)
    end

    protected

    def redirect(url)
      [ 302, {
        'Location'      => url,
        'Cache-Control' => 'public, max-age=86400',
        'Date'          => Time.now.httpdate
      }, [] ]
    end

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
      return :image    if image_extensions.include?(drop.extension.downcase)

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
