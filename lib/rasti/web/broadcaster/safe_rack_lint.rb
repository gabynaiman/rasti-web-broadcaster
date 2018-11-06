if defined?(Rack::Lint::HijackWrapper) && !Rack::Lint::HijackWrapper.instance_methods.include?(:to_int)
  class Rack::Lint::HijackWrapper
    def to_int
      @io.to_i
    end
  end
end