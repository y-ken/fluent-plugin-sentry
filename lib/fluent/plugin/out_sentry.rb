class Fluent::SentryOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('sentry', self)

  include Fluent::HandleTagNameMixin

  LOG_LEVEL = %w(fatal error warning info debug)
  EVENT_KEYS = %w(message timestamp time_spent level logger culprit server_name release tags)
  DEFAULT_HOSTNAME_COMMAND = 'hostname'

  config_param :default_level, :string, :default => 'error'
  config_param :default_logger, :string, :default => 'fluentd'
  config_param :endpoint_url, :string
  config_param :flush_interval, :time, :default => 0
  config_param :hostname_command, :string, :default => 'hostname'

  def initialize
    require 'time'
    require 'raven'

    super
  end

  def configure(conf)
    super

    if @endpoint_url.nil?
      raise Fluent::ConfigError, "sentry: missing parameter for 'endpoint_url'"
    end

    unless LOG_LEVEL.include?(@default_level)
      raise Fluent::ConfigError, "sentry: unsupported default reporting log level for 'default_level'"
    end

    hostname_command = @hostname_command || DEFAULT_HOSTNAME_COMMAND
    @hostname = `#{hostname_command}`.chomp

    @configuration = Raven::Configuration.new
    @configuration.server = @endpoint_url
    @configuration.server_name = @hostname
    @client = Raven::Client.new(@configuration)
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
    event = Raven::Event.new(
      :configuration => @configuration, 
      :context => Raven::Context.new, 
      :message => record['message']
    )
    event.timestamp = record['timestamp'] || Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S')
    event.time_spent = record['time_spent'] || nil
    event.level = record['level'] || @default_level
    event.logger = record['logger'] || @default_logger
    event.culprit = record['culprit'] || nil
    event.server_name = record['server_name'] || @hostname
    event.release = record['release'] if record['release']
    event.tags = event.tags.merge({ :tag => tag }.merge(record['tags'] || {}))
    event.extra = record.reject{ |key| EVENT_KEYS.include?(key) }
    @client.send_event(event)
  end
end
