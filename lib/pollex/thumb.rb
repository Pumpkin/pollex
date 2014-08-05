require 'posix/spawn'
require 'open3'

module Pollex
  Thumb = Struct.new(:file, :slug) do
    TIMEOUT = ENV.fetch('THUMBNAIL_TIMEOUT', 15)

    def success?
      thumbnail != :error
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

    def path
      thumbnail.path
    end

    protected

    def thumbnail
      @thumbnail ||= identify_image == :error ?
        :error :
        Tempfile.open("#{slug}.png") {|file| generate(file) }
    end

    def identify_image
      @identify_image ||= execute_identify
    end

    def execute_identify
      identify_command = %w(identify -quiet -format %w\ %h)
      child = POSIX::Spawn::Child.new(*identify_command, file.path,
                                      timeout: TIMEOUT)
      raise ArgumentError, child.err unless child.success?
      child.out.chomp.split(' ').map(&:to_i)
    rescue POSIX::Spawn::TimeoutExceeded
      :error
    end

    def generate(thumbnail)
      child = POSIX::Spawn::Child.new('convert', *convert_arguments,
                                      thumbnail.path,
                                      timeout: TIMEOUT)
      raise ArgumentError, child.err unless child.success?
      thumbnail
    rescue POSIX::Spawn::TimeoutExceeded
      :error
    end

    def image_too_large?
      width, height = identify_image
      width > 200 && height > 150
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
