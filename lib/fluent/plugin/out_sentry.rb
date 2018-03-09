require 'fluent/output'
require 'time'
require 'raven'


module Fluent
  class Fluent::SentryOutput < BufferedOutput
    Fluent::Plugin.register_output('sentry', self)

    include Fluent::HandleTagNameMixin

    LOG_LEVEL = %w(fatal error warn warning info debug).to_set()
    EVENT_KEYS = %w(message msg timestamp level logger).to_set()
    DEFAULT_HOSTNAME_COMMAND = 'hostname'

    config_param :default_level, :string, :default => 'info'
    config_param :default_logger, :string, :default => 'fluentd'
    config_param :report_levels, :array, value_type: :string, :default => %w(fatal error warn warning)
    config_param :tags_key, :array, value_type: :string, :default => %w()
    config_param :userid_key, :array, value_type: :string, :default => %w()
    config_param :endpoint_url, :string
    config_param :flush_interval, :time, :default => 0
    config_param :hostname_command, :string, :default => 'hostname'
    config_param :stacktrace_expand_json_escaping, :bool, :default => true

    def configure(conf)
      super

      if @endpoint_url.nil?
        raise Fluent::ConfigError, "sentry: missing parameter for 'endpoint_url'"
      end

      unless LOG_LEVEL.include?(@default_level)
        raise Fluent::ConfigError, "sentry: unsupported default reporting log level for 'default_level'"
      end
 
      @report_levels = @report_levels.to_set()
      @report_levels.each do |report_level|
        unless LOG_LEVEL.include?(report_level)
          raise Fluent::ConfigError, "sentry: unsupported level in report_levels for 'report_level'"
        end
      end

      @tags_key = @tags_key.to_set()

      @userid_key_patterns = []
      @userid_key.each do |key_pattern|
        keys = key_pattern.split("/")
        @userid_key_patterns.push(keys)
      end

	  $log.info(@userid_key_patterns)

      hostname_command = @hostname_command || DEFAULT_HOSTNAME_COMMAND
      @hostname = `#{hostname_command}`.chomp

      @configuration = Raven::Configuration.new
      @configuration.server = @endpoint_url
      @configuration.server_name = @hostname
      @configuration.send_modules = false
      @configuration.release = nil
      @client = Raven::Client.new(@configuration)
      @context = Raven::Context.new
    end

    def start
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def shutdown
      super
    end

    def write(chunk)
      chunk.msgpack_each do |tag, time, record|
        begin
          notify_sentry(tag, time, record)
        rescue => e
          $log.error("Sentry Error:", :error_class => e.class, :error => e.message)
        end
      end
    end

    def notify_sentry(tag, time, record)
      level = (record['level'] || @default_level).downcase
      if not @report_levels.include?(level)
        return
      end

      record["fluentd_tag"] = tag

      event = Raven::Event.new(
        :configuration => @configuration, 
        :context => @context, 
        :timestamp => record['timestamp'] || Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S'),
        :level => level,
        :logger => record['logger'] || @default_logger,
        :message => record['message'] || record['msg'] || "",
      )

      stacktrace = record['stacktrace']
      if stacktrace
        if @stacktrace_expand_json_escaping
          stacktrace = stacktrace.gsub(/\\[nt]/, '\n' => "\n", '\t' => "\t")
          record['stacktrace'] = stacktrace
        end
        event.interface(:stacktrace) do |int|
          int.frames = event.stacktrace_interface_from(stacktrace)
        end
      end

      event.tags = event.tags.merge(extract_tags(record))
      event.extra = record.reject{ |key| EVENT_KEYS.include?(key) }

      user_id = extract_userid(record)
      if user_id != nil
        event.user = {"id": user_id}
      end

      @client.send_event(event)
    end

    def extract_tags(record, path=nil)
      r = {}
      record.each { |k, v| 
        kpath = path.nil? ? k : path + "." + k
        if v.is_a?(Hash)
          r.merge!(extract_tags(v, kpath))
        else
          if @tags_key.include?(kpath)
            r[kpath] = v
          end
        end
      }
      return r
    end

    def extract_userid(record)
      @userid_key_patterns.each do |pattern|
        values = pattern.each.map do |key| record[key] end
        if values.all?
          return values.join("/")
        end
      end
    end
  end
end
