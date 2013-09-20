require 'test_helper'
require 'fluent/plugin/out_buffered_hipchat'
require 'time'

class BufferedHipchatOutputTest < Test::Unit::TestCase

  def setup
    super
    Fluent::Test.setup
  end

  CONFIG = %[
    type buffered_hipchat
    api_token testtoken
    default_room testroom
    default_from testuser
    default_color yellow
    default_format text
    buffer_type memory
    compress gz
    utc
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::BufferedHipchatOutput).configure(conf)
  end

  def test_format
    d = create_driver
    time = Time.parse("2013-09-12 05:00:00 UTC").to_i
    d.emit({message: 'sowawa'}, time)
    d.expect_format %[#{['test', time, {message: 'sowawa'}].to_json}\n]
    d.run
  end

  def test_write
    d = create_driver
    time = Time.parse("2013-09-12 05:00:00 UTC").to_i
    tag  = 'test'
    stub(d.instance.hipchat).rooms_message(
      'testroom',
      'testuser',
      "[#{Time.at(time)} #{tag}] sowawa1\n" +
        "[#{Time.at(time)} #{tag}] sowawa2\n",
      0,
      'yellow',
      'text')
    d.emit({message: 'sowawa1'}, time)
    d.emit({message: 'sowawa2'}, time)
    d.run
  end
end
