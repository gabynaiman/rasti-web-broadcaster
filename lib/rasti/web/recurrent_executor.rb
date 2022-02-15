class RecurrentExecutor
  def interval_loop(interval_seconds)
    raise ArgumentError.new("interval_seconds should be a Number") unless interval_seconds.kind_of?(Numeric)

    last_time = Time.now
    while true
      yield
      now = Time.now
      next_time = [last_time + interval_seconds, now].max
      sleep(next_time - now)
      last_time = next_time
    end
  end
end
