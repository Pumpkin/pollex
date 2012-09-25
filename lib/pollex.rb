require 'eventmachine'
require 'sinatra/base'

require_relative 'drop'
require_relative 'thumbnail'

# Pollex
# ------
#
# **Pollex** is at its core a Sinatra app to facilitate the generation of
# thumbnails of CloudApp Drops.

# App
# ------
#
# **App** is a simple Sinatra app that generates and returns thumbnails of
# CloudApp Drops. Images are pulled from their remote location and thumbnailed
# using **MiniMagick**. Any non-image Drop returns an icon representing its
# type.
class Pollex < Sinatra::Base
  # Log to STDOUT
  STDOUT.sync = true

  require_relative 'metriks_reporter'
  MetriksReporter.setup self

  # Load New Relic RPM and Airbrake in the production and staging environments.
  configure(:production, :staging) do
    require 'newrelic_rpm'
    require_relative 'newrelic_instrumentation'

    # Add your Airbrake API key to the environment variable `AIRBRAKE_API_KEY`
    # to use Airbrake to catalog your exceptions.
    if ENV['AIRBRAKE_API_KEY']
      require 'active_support'
      require 'active_support/core_ext/object/blank'
      require 'airbrake'

      Airbrake.configure do |config|
        config.api_key = ENV['AIRBRAKE_API_KEY']
      end

      use Airbrake::Rack
      enable :raise_errors
    end
  end

  # Use a fiber pool to serve **Pollex** outside of the test environment.
  configure do
    unless test?
      require 'rack/fiber_pool'
      use Rack::FiberPool
    end
  end

  # Serve static assets from `/public`
  set :public_folder, 'public'

  # The home page. Nothing to see here. Redirect to the CloudApp product page.
  # Response is cached for one year.
  get '/' do
    cache_control :public, :max_age => 31557600
    redirect 'http://getcloudapp.com'
  end

  # Generate and render a thumbnail for an image `Drop` given its slug or
  # render a file type icon. Thumbnails of images are cached privately for 1
  # day and generic file type icons are cached publicly for one year.
  get %r{^                         #
         (?:/(text|code|image))?   # Optional drop type
         /([^/?#]+)                # Item slug
         $}x do |type, slug|
    begin
      thumbnail = Thumbnail.new find_drop(slug)

      if thumbnail.drop.image?
        cache_control :private, :max_age => 86400
        render_thumbnail thumbnail
      else
        cache_control :public, :max_age => 31557600
        render_drop_icon thumbnail
      end
    rescue => e
      env['async.callback'].call [ 500, {}, error_content_for(:error) ]
      Airbrake.notify_or_ignore e if defined? Airbrake
    end
  end

  # Don't need to return anything special for a 404.
  not_found do
    not_found error_content_for(:not_found)
  end

protected

  # Find and return a **Drop** with the given `slug`. Handle `Drop::NotFound`
  # errors and render the not found response.
  def find_drop(slug)
    Drop.find slug
  rescue Drop::NotFound
    not_found
  end

  # Render the thumbnailed image if the **Drop** is an image. Response is
  # cached for 15 minutes.
  def render_thumbnail(thumbnail)
    send_file thumbnail.file, :disposition => 'inline',
                              :type        => thumbnail.type
  rescue Thumbnail::Error => e
    Airbrake.notify_or_ignore e if defined? Airbrake
    render_drop_icon thumbnail
  end

  # For non-images, redirect to a file type icon. Response is cached for one
  # year.
  def render_drop_icon(thumbnail)
    icon = icon_exists?(thumbnail.drop.item_type) ?
             thumbnail.drop.item_type :
             'unknown'

    redirect "/icons/#{ icon }.png"
  end

  # Returns true if the icon for the given `type` exists.
  def icon_exists?(type)
    File.exists? File.join(settings.public_folder, 'icons', "#{ type }.png")
  end

  def error_content_for(type)
    type = type.to_s.gsub /_/, '-'
    File.read File.join(settings.public_folder, "#{ type }.html")
  end

end
