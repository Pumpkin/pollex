require 'time'

module Pollex
  class Homepage
    attr_accessor :app

    def initialize(app)
      @app = app
    end

    def call(env)
      return redirect if home_page?(env)
      app.call(env)
    end

    protected

    def redirect
      [ 301,
        { 'Location'      => 'http://getcloudapp.com',
          'Cache-Control' => 'public, max-age=86400',
          'Date'          => Time.now.httpdate },
        [] ]
    end

    def home_page?(env)
      env['PATH_INFO'] == '/'
    end
  end
end
