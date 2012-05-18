require 'em-synchrony'
require 'em-synchrony/em-http'

require 'mini_magick'
require 'tempfile'
require_relative 'thumbnail_reporter'

# Thumbnail
# ---------
#
# **Thumbnail** accepts a **Drop** as JSON and generates a thumbnail if it's
# an image. For all other file type, `NotImage` is raised.
class Thumbnail < Struct.new(:drop)

  # Raised when the drop being thumbaniled is not an image.
  class NotImage < StandardError; end
  class Error    < StandardError; end

  def file
    raise NotImage.new unless drop.image?

    @file ||= begin
                reporter = ThumbnailReporter.start(type:   type,
                                                   height: height,
                                                   width:  width)
                image.format('png')
                resize_image(reporter)
                image.
                  write(tempfile).
                  flush
              end
  end

  # Returns the remote file's filename.
  def filename
    File.basename remote_url
  end

  # Returns the remote file's extension.
  def type
    File.extname remote_url
  end
  alias_method :extname, :type

protected

  # The URL of the **Drop's** remote file.
  def remote_url
    drop.remote_url
  end

  # Return the **MiniMagick::Image** for the **Drop**.
  def image
    @image ||= MiniMagick::Image.read(data, extname)
  end

  # Download and return the **Drop's** remote file.
  def data
    EM::HttpRequest.new(remote_url).get.response
  end

  # Resize `image` preserving aspect ratio and crop to fit within 250x150.
  # Images smaller are not altered.
  def resize_image(reporter)
    image.combine_options do |c|
      c.resize  '200x150^' if image_too_large?
      c.gravity 'northwest'
      c.crop    '200x150+0+0'
      c.repage.+
      c.background 'transparent'
      c.gravity 'center'
      c.extent '200x150'
    end
    reporter.complete
  rescue MiniMagick::Error
    reporter.killed
    raise Error
  end

  def height() @height ||= image[:height] end
  def width()  @width  ||= image[:width]  end

  # Checks the image and returns true if both of its dimensions exceed 250x150.
  def image_too_large?
    width > 200 && height > 150
  end

  # The temporary file used to hold the thumbnailed **Drop**.
  def tempfile
    @tempfile ||= Tempfile.new(File.basename(remote_url))
  end
end

require 'ostruct'
MiniMagick.timeout = 15
MiniMagick.system_method = ->(command, timeout) do
  f = Fiber.current
  timer = nil

  pid = EM.system command do |output, status|
    timer.cancel if timer
    f.resume [ output, status ]
  end

  timer = EM::Timer.new(timeout) do
    Process.kill('TERM', pid) rescue nil
  end

  output, status = Fiber.yield
  OpenStruct.new output: output, exitstatus: status.exitstatus
end
