
module Fluent
  module HipchatBase

    def self.included(base)
      base.class_eval do
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
      end
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
