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

  CONFIG_FOR_PROXY = %[
    http_proxy_host localhost
    http_proxy_port 8080
    http_proxy_user user
    http_proxy_pass password
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
    d.tag  = 'test'
    stub(d.instance.hipchat).rooms_message(
      'testroom',
      'testuser',
      "#{d.tag} >>\n" +
        "[#{Time.at(time)}] sowawa1\n" +
        "[#{Time.at(time)}] sowawa2\n",
      0,
      'yellow',
      'text')
    d.emit({message: 'sowawa1'}, time)
    d.emit({message: 'sowawa2'}, time)
    d.run
  end

  def test_http_proxy
    create_driver(CONFIG + CONFIG_FOR_PROXY)
    assert_equal 'localhost', HipChat::API.default_options[:http_proxyaddr]
    assert_equal '8080', HipChat::API.default_options[:http_proxyport]
    assert_equal 'user', HipChat::API.default_options[:http_proxyuser]
    assert_equal 'password', HipChat::API.default_options[:http_proxypass]
  end
end
