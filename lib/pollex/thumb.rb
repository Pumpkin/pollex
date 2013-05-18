require 'open3'

module Pollex
  Thumb = Struct.new(:file, :slug) do
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
                -background red
                -gravity center
                -extent 200x150
                #{file.path}[0])
      args.unshift *%w(-resize 200x150^) if image_too_large?
      args
    end

    def image_too_large?
      identify_command = %w(identify -quiet -format %w\ %h)
      stdout, status   = Open3.capture2(*identify_command, file.path)
      width,  height   = stdout.chomp.split(' ').map(&:to_i)
      width > 200 && height > 150
    end
  end
end
