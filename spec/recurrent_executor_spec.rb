require 'json'
require_relative 'minitest_helper'

describe RecurrentExecutor do
  let(:executor) { RecurrentExecutor.new }

  describe '#interval_loop' do

    it 'Should validate params' do
      assert_raises(ArgumentError) { executor.interval_loop(nil) }
      assert_raises(ArgumentError) { executor.interval_loop({}) }
      assert_raises(ArgumentError) { executor.interval_loop.new('15') }
      executor.interval_loop(0.1) { break }
      executor.interval_loop(1) { break }
    end

    it 'Should execute the given block only once if interval is too large' do
      n_of_executions = 0
      Thread.new do
        executor.interval_loop(interval_seconds=10000) { n_of_executions += 1 }
      end

      sleep(0.1)

      assert_equal(1, n_of_executions)
    end

    it 'Should execute the given block a great number of times if interval is too small' do
      n_of_executions = 0
      Thread.new do
        executor.interval_loop(interval_seconds=0) { n_of_executions += 1 }
      end

      sleep(0.1)

      # 100 is an arbitrary number, but if interval_seconds=0, we can expect the block to be called hundreds of times
      assert(n_of_executions > 100)
    end
  end
end
