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

  def create_driver(conf=CONFIG,tag='test',use_v1=false)
    require 'fluent/version'
    if Gem::Version.new(Fluent::VERSION) < Gem::Version.new('0.12')
      Fluent::Test::OutputTestDriver.new(Fluent::SentryOutput, tag).configure(conf, use_v1)
    else
      Fluent::Test::BufferedOutputTestDriver.new(Fluent::SentryOutput, tag).configure(conf, use_v1)
    end
  end

  def stub_post(url="https://app.getsentry.com/api/12345/store/")
    parser = Yajl::Parser.new
    stub_request(:post, url).with do |req|
      @content_type = req.headers["Content-Type"]
      message = Zlib::Inflate.inflate(Base64.decode64(req.body))
      @body = parser.parse(message)
    end
  end

  def stub_response(url="https://app.getsentry.com/api/12345/store/")
    stub_request(:post, url).with do |req|
      @content_type = req.headers["Content-Type"]
      message = Zlib::Inflate.inflate(Base64.decode64(req.body))
      @body = {"eventID"=>"fe0263d6f55d014cade15a8681ae58ed", "tags"=>[["tag", "app1_error"], ["cool", "bar"], ["level", "warning"], ["logger", "zaphod"], ["server_name", "bc40a4be7b2d"], ["sentry:release", "wingnut"]], "nextEventID"=>nil, "dateCreated"=>"2015-10-30T08:25:48Z", "timeSpent"=>13, "user"=>nil, "entries"=>[], "previousEventID"=>nil, "message"=>"error has occoured.", "packages"=>{"fluentd"=>"0.12.16", "sentry-raven"=>"0.15.2", "cool.io"=>"1.4.1", "faraday"=>"0.9.2", "safe_yaml"=>"1.0.4", "msgpack"=>"0.5.12", "bundler"=>"1.10.6", "json"=>"1.8.3", "crack"=>"0.4.2", "tzinfo"=>"1.2.2", "thread_safe"=>"0.3.5", "tzinfo-data"=>"1.2015.7", "rake"=>"10.4.2", "yajl-ruby"=>"1.2.1", "hashdiff"=>"0.2.2", "sigdump"=>"0.2.3", "multipart-post"=>"2.0.0", "string-scrub"=>"0.0.5", "addressable"=>"2.3.8", "webmock"=>"1.22.2", "http_parser.rb"=>"0.6.0", "fluent-plugin-sentry"=>"0.0.1"}, "id"=>"127", "platform"=>"ruby", "context"=>{"something"=>{"foo"=>{"array"=>[1, 2, 3]}, "hash"=>{"nest"=>"data"}}}, "groupID"=>127}
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
    stub_post
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
    timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S')
    assert_equal 0, emits.length
    assert_equal 'application/octet-stream', @content_type
    assert_equal emit_message, @body['message']
    assert_equal timestamp, @body['timestamp']
    assert_equal emit_level, @body['level']
    assert_equal 'fluentd', @body['logger']
    assert_equal 'ruby', @body['platform']
    assert_equal 'app1_error', @body['tags']['tag']
    hostname = `#{d1.instance.config['hostname_command']}`.chomp
    assert_equal hostname, @body['server_name']
    extra_message = {'something' => emit_extra}
    assert_equal extra_message, @body['extra']
  end

  def test_emit_mock
    stub_response
    emit_level = 'warning'
    emit_message = 'error has occoured.'
    emit_timestamp = '2015-10-30T08:25:48Z'.force_encoding("UTF-8")
    emit_time_spent = '13'
    emit_logger = 'zaphod'
    emit_server_name = 'bc40a4be7b2d'
    emit_culprit = 'whodonit'
    emit_release = 'wingnut'
    emit_extra = {'foo' => {'array' => [1,2,3]}, 'hash' => {'nest' => 'data'}}
    d1 = create_driver(CONFIG, 'input.app1_error')
    d1.run do
      d1.emit({
        'level' => emit_level,
        'message' => emit_message,
        'something' => emit_extra,
        'tags' => {'cool' => 'bar'},
        'timestamp' => emit_timestamp,
        'logger' => emit_logger,
        'server_name' => emit_server_name,
        'release' => emit_release,
        'time_spent' => emit_time_spent,
        'culprit' => emit_culprit
      })
    end
    p @body
    emits = d1.emits
    extra_message = {'something' => emit_extra}
    assert_equal 0, emits.length
    assert_equal 'application/octet-stream', @content_type
    assert_equal extra_message, @body['context']
    assert_equal emit_timestamp, @body['dateCreated']
    assert_equal emit_message, @body['message']
    assert_equal emit_level, Hash[ @body['tags'] ]['level']
    assert_equal emit_logger, Hash[ @body['tags'] ]['logger']
    assert_equal emit_server_name, Hash[ @body['tags'] ]['server_name']
    assert_equal emit_release, Hash[ @body['tags'] ]['sentry:release']
    assert_equal 'bar', Hash[ @body['tags'] ]['cool']
    assert_equal 'app1_error', Hash[ @body['tags'] ]['tag']
    assert_equal 'ruby', @body['platform']
    assert_equal nil, @body['user']
    # these values seem to only be visible in the ui. need to find the api to grab them
    #assert_equal emit_culprit, @body['culprit']
    #assert_equal emit_time_spent, @body['timeSpent']
  end
end
