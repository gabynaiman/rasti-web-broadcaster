if RUBY_ENGINE == 'jruby'
  EventMachine.define_singleton_method :signal_loopbreak do 
    @em.signalLoopbreak if @em
  end
end