module Pollex
  class RuntimeInstrumentation
    def initialize(options = {})
      @interval      = (options[:interval] || 1.0).to_f
      @metric_prefix = options[:metric_prefix] || 'runtime'
    end

    def start
      ruby_delay
    end

    def ruby_delay
      return if @ruby_thread && @ruby_thread.alive?

      @ruby_thread = Thread.new do
        histogram = Metriks.histogram("#{@metric_prefix}.ruby.variance")

        while true
          ruby_interval = Hitimes::Interval.now
          sleep @interval
          histogram.update(ruby_interval.duration - @interval)
        end
      end
    end
  end
end
