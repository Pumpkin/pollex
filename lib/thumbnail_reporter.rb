require 'hitimes'

class ThumbnailReporter
  def initialize(attributes)
    @attributes = attributes
  end

  def self.start(attributes)
    new(attributes).start
  end

  def start
    @interval = Hitimes::Interval.now
    self
  end

  def stop
    @interval.stop
  end

  def complete
    stop
    report 'complete'
  end

  def killed
    stop
    report 'killed'
  end

protected

  def report(status)
    $stdout.puts "#{ status }: { #{ formatted_attributes } }"
  end

  def formatted_attributes
    duration = @interval.duration
    type     = @attributes[:type].sub(/^\./, '').inspect
    height   = @attributes[:height]
    width    = @attributes[:width]

    { duration: duration,
      type: type,
      height: height,
      width: width }.
    map {|key, value| "#{ key.to_s.inspect }: #{ value }" }.
    join(', ')
  end
end
