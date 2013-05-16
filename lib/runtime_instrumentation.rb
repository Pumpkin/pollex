class RuntimeInstrumentation
  def initialize(options = {})
    @interval      = (options[:interval] || 1.0).to_f
    @metric_prefix = options[:metric_prefix] || "runtime"
  end

  def start
    eventmachine_delay
    ruby_delay
  end

  def eventmachine_delay
    return if @em_periodic_timer

    histogram = Metriks.histogram("#{@metric_prefix}.eventmachine.variance")
    em_interval = nil

    EM.next_tick do
      @em_periodic_timer = EM.add_periodic_timer(@interval) do
        histogram.update(em_interval.duration - @interval) if em_interval
        em_interval = Hitimes::Interval.now
      end
    end
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
