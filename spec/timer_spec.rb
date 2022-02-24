require 'minitest_helper'

describe Rasti::Web::Broadcaster::Timer do

  let(:timer) { Rasti::Web::Broadcaster::Timer }

  it 'Tick' do
    count = 0

    thread = timer.every(0.02) do
      count += 1
    end

    sleep 0.07
    thread.exit

    count.must_equal 4
  end

  it 'Interval exceded' do
    count = 0

    thread = timer.every(0.02) do
      sleep 0.04 if count == 1
      count += 1
    end

    sleep 0.07
    thread.exit

    count.must_equal 3
  end

  it 'Error safe' do
    count = 0

    thread = timer.every(0.02) do
      count += 1
      raise 'Unexpected error' if count == 2
    end

    sleep 0.05
    thread.exit

    count.must_equal 3
  end

end