require 'fluent/plugin/hipchat_base'
module Fluent
  class BufferedHipchatOutput < Fluent::TimeSlicedOutput
    Fluent::Plugin.register_output('buffered_hipchat', self)
    include HipchatBase

    def format(tag, time, record)
      [tag, time, record].to_json + "\n"
    end

    def write(chunk)
      message = ''
      chunk.open {|io|
        io.each {|line|
          line_json = JSON.parse(line)
          tag    = line_json[0]
          time   = line_json[1]
          record = line_json[2]
          message << "[#{Time.at(time)} #{tag}] #{record['message']}\n"
        }
      }
      message.scan(/.{1,10000}/m).each {|chunked_message|
        @hipchat.rooms_message(@default_room, @default_from, chunked_message, @default_notify, @default_color, @default_format)
      }
    rescue => e
      $log.error("HipChat Error: #{e} / #{e.message}")
    end
  end
end
