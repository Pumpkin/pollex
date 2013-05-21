module Pollex
  class HandleExceptions
    attr_accessor :app

    def initialize(app)
      @app = app
    end

    def call(env)
      app.call(env)
    rescue
      error
    end

    protected

    def error
      [ 500, { 'Content-Type' => 'text/html' },
        File.open('public/error.html') ]
    end
  end
end
