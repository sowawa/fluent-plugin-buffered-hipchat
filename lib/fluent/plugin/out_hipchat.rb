require 'fluent/plugin/hipchat_base'
module Fluent
  class HipchatOutput < Output
    COLORS = %w(yellow red green purple gray random)
    FORMAT = %w(html text)
    Fluent::Plugin.register_output('hipchat', self)
    include Fluent::HipchatBase

    def emit(tag, es, chain)
      es.each {|time, record|
        begin
          send_message(record)
        rescue => e
          $log.error("HipChat Error: #{e} / #{e.message}")
        end
      }
    end

    def send_message(record)
      room = record['room'] || @default_room
      from = record['from'] || @default_from
      message = record['message'] || ''
      if record['notify'].nil?
        notify = @default_notify
      else
        notify = record['notify'] ? 1 : 0
      end
      color = COLORS.include?(record['color']) ? record['color'] : @default_color
      message_format = FORMAT.include?(record['format']) ? record['format'] : @default_format
      @hipchat.rooms_message(room, from, message, notify, color, message_format)
    end
  end
end
