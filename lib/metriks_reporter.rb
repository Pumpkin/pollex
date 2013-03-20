require 'metriks/middleware'

class MetriksReporter
  def initialize(app)
    @app = app
  end

  def self.setup(app)
    reporter = new app
    reporter.insert_middleware
    reporter.report_metrics
  end

  def insert_middleware
    @app.use Metriks::Middleware
  end

  def report_metrics
    if user && token
      require 'metriks/reporter/librato_metrics'
      require 'socket'

      source   = Socket.gethostname
      on_error = ->(e) do STDOUT.puts("LibratoMetrics: #{ e.message }") end
      Metriks::Reporter::LibratoMetrics.new(user, token,
                                            prefix:   prefix,
                                            on_error: on_error,
                                            source:   source).start
    end
  end

  def user
    ENV['LIBRATO_METRICS_USER']
  end

  def token
    ENV['LIBRATO_METRICS_TOKEN']
  end

  def prefix
    ENV['LIBRATO_METRICS_PREFIX']
  end
end
