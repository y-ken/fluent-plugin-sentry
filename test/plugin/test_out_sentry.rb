require 'helper'
require 'webmock/test_unit'
require 'yajl'

WebMock.disable_net_connect!

class SentryOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type sentry
    endpoint_url      https://user:password@app.getsentry.com/12345
    hostname_command  hostname -s
    remove_tag_prefix input.
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::SentryOutput, tag).configure(conf)
  end

  def stub_endpoint(url="https://app.getsentry.com/api/12345/store/")
    parser = Yajl::Parser.new
    stub_request(:post, url).with do |req|
      @content_type = req.headers["Content-Type"]
      @body = parser.parse(req.body)
    end
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver(CONFIG)
    assert_equal 'https://user:password@app.getsentry.com/12345', d.instance.config['endpoint_url']
  end

  def test_emit
    stub_endpoint
    d1 = create_driver(CONFIG, 'input.app1_error')
    emit_level = 'warning'
    emit_message = 'error has occoured.'
    emit_extra = {'foo' => {'array' => [1,2,3]}, 'hash' => {'nest' => 'data'}}
    d1.run do
      d1.emit({
        'level' => emit_level,
        'message' => emit_message,
        'something' => emit_extra
      })
    end
    p @body
    emits = d1.emits
    assert_equal 0, emits.length
    assert_equal 'application/json', @content_type
    assert_equal emit_message, @body['message']
    timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S')
    assert_equal timestamp, @body['timestamp']
    assert_equal emit_level, @body['level']
    assert_equal '12345', @body['project']
    assert_equal 'fluentd', @body['logger']
    assert_equal 'ruby', @body['platform']
    assert_equal 'app1_error', @body['tags'][':tag']
    hostname = `#{d1.instance.config['hostname_command']}`.chomp
    assert_equal hostname, @body['server_name']
    extra_message = {'something' => emit_extra}
    assert_equal extra_message, @body['extra']
  end
end
