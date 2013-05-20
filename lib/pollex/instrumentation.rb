require 'metriks'
require 'metriks/middleware'
require 'pollex/runtime_instrumentation'

module Pollex
  module Instrumentation
    def self.setup(app)
      report
      insert_middleware(app)
      RuntimeInstrumentation.new.start
    end

    def self.insert_middleware(app)
      app.use Metriks::Middleware
    end

    def self.report(user  = ENV['LIBRATO_METRICS_USER'],
                    token = ENV['LIBRATO_METRICS_TOKEN'])
      unless user && token
        require 'metriks/reporter/logger'
        Metriks::Reporter::Logger.new(logger:   Logger.new($stdout),
                                      interval: 5).start
        return
      end

      require 'metriks/reporter/librato_metrics'

      prefix = ENV.fetch('LIBRATO_METRICS_PREFIX') do
        ENV['RACK_ENV'] unless ENV['RACK_ENV'] == 'production'
      end

      app_name = ENV.fetch('PS') do
        # Fall back to hostname if PS isn't set.
        require 'socket'
        Socket.gethostname
      end

      source   = [ app_name, Process.pid ].join(':')
      on_error = ->(e) do STDOUT.puts("LibratoMetrics: #{ e.message }") end
      opts     = { on_error: on_error, source: source }
      opts[:prefix] = prefix if prefix && !prefix.empty?

      Metriks::Reporter::LibratoMetrics.new(user, token, opts).start
    end
  end
end