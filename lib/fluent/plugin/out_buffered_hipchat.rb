module Fluent
  class BufferedHipchatOutput < Fluent::TimeSlicedOutput
    Fluent::Plugin.register_output('buffered_hipchat', self)
    config_param :api_token, :string
    config_param :default_room, :string, :default => nil
    config_param :default_color, :string, :default => nil
    config_param :default_from, :string, :default => nil
    config_param :default_notify, :bool, :default => nil
    config_param :default_format, :string, :default => nil
    config_param :http_proxy_host, :string, :default => nil
    config_param :http_proxy_port, :integer, :default => nil
    config_param :http_proxy_user, :string, :default => nil
    config_param :http_proxy_pass, :string, :default => nil

    attr_reader :hipchat

    def format(tag, time, record)
      [tag, time, record].to_json + "\n"
    end

    def write(chunk)
      messages = {}
      chunk.open {|io|
        io.each {|line|
          line_json = JSON.parse(line)
          tag    = line_json[0]
          time   = line_json[1]
          record = line_json[2]
          messages[tag] = '' unless messages[tag]
          messages[tag] << "[#{Time.at(time)}] #{record['message']}\n"
        }
      }
      # hoge = "ajshdfjalksfjlkasdjf\nlaksjfdl\naksfksadflka;"
      # hoge.scan(/.{1,24}\Z|.{1,24}\n/m)
      messages.each do |tag, message|
        message.scan(/.{1,9500}/m).each {|chunked_message|
          @hipchat.rooms_message(@default_room, @default_from, "#{tag} >>\n" + chunked_message, @default_notify, @default_color, @default_format)
        }
      end
    rescue => e
      $log.error("HipChat Error: #{e} / #{e.message}")
    end

    def initialize
      super
      require 'hipchat-api'
    end

    def configure(conf)
      super

      @hipchat = HipChat::API.new(conf['api_token'])
      @default_room = conf['default_room']
      @default_from = conf['default_from'] || 'fluentd'
      @default_notify = conf['default_notify'] || 0
      @default_color = conf['default_color'] || 'yellow'
      @default_format = conf['default_format'] || 'html'
      if conf['http_proxy_host']
        HipChat::API.http_proxy(
          conf['http_proxy_host'],
          conf['http_proxy_port'],
          conf['http_proxy_user'],
          conf['http_proxy_pass'])
      end
    end

  end
end
