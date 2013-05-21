require 'open3'

module Pollex
  Thumb = Struct.new(:file, :slug) do
    def success?
      dimensions != :error
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
        generate_thumbnail(thumbnail.path)
        thumbnail
      end
    end

    def generate_thumbnail(output_path)
      system 'convert', *convert_arguments, output_path
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

    def dimensions
      identify_command       = %w(identify -quiet -format %w\ %h)
      stdout, stderr, status = Open3.capture3(*identify_command, file.path)
      return :error unless status.success?
      stdout.chomp.split(' ').map(&:to_i)
    end

    def image_too_large?
      width, height = dimensions
      width > 200 && height > 150
    end
  end
end
