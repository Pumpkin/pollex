require 'airbrake'

module Pollex
  module ExceptionTracking
    def self.setup(app, api_key = ENV['AIRBRAKE_API_KEY'])
      return unless api_key

      Airbrake.configure do |config|
        config.api_key = api_key
      end

      app.use Airbrake::Rack
    end
  end
end
