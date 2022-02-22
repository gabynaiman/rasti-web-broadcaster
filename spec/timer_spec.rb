require 'minitest_helper'

describe Rasti::Web::Broadcaster::Timer do

  let(:timer) { Rasti::Web::Broadcaster::Timer }

  it 'Tick' do
    count = 0

    thread = timer.every(0.02) do
      count += 1
    end

    sleep 0.05
    thread.exit

    count.must_equal 3
  end

  it 'Error safe' do
    count = 0

    thread = timer.every(0.02) do
      count += 1
      raise 'ERROR: 2' if count == 2
    end

    sleep 0.05
    thread.exit

    count.must_equal 3
  end

  it 'Interval timeout' do
    count = 0

    thread = timer.every(0.02) do
      count += 1
      sleep 10 if count == 2
    end

    sleep 0.05
    thread.exit

    count.must_equal 3
  end

end