require 'open3'

module Pollex
  Thumb = Struct.new(:file, :slug) do
    def success?
      identify_image != :error
    end

    def size
      File.size(thumbnail.path)
    end

    def each
      File.open(thumbnail.path, "rb") do |thumbnail|
        while (part = thumbnail.read(8192))
          yield part
        end
      end
    end

    protected

    def thumbnail
      @thumbnail ||= Tempfile.open("#{slug}.png") do |thumbnail|
        system 'convert', *convert_arguments, thumbnail.path
        thumbnail
      end
    end

    def image_too_large?
      width, height = identify_image
      width > 200 && height > 150
    end

    def identify_image
      @identify_image ||= begin
        identify_command       = %w(identify -quiet -format %w\ %h)
        stdout, stderr, status = Open3.capture3(*identify_command, file.path)
        status.success? ? stdout.chomp.split(' ').map(&:to_i) : :error
      end
    end

    def convert_arguments
      args = %W(-gravity northwest
                -crop 200x150+0+0
                +repage
                -background transparent
                -gravity center
                -extent 200x150
                #{file.path}[0])
      args.unshift *%w(-resize 200x150^) if image_too_large?
      args
    end
  end
end
