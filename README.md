# fluent-plugin-sentry [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-sentry.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-sentry)

## Overview

Fluentd output plugin to aggregate errors/exception to sentry which are a realtime event logging and aggregation platform.

## Installation

install with gem or fluent-gem command as:

`````
### native gem
gem install fluent-plugin-sentry

### td-agent gem
/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-sentry
`````

## Tutorial

## Parameters

* endpoint_url #required
* default_level
* defalut_logger
* hostname_command
* flush_interval

It also support rewriting Tag with SetTagKeyMixin.

* remove_tag_prefix
* remove_tag_suffix
* add_tag_prefix
* add_tag_suffix

## Blog Articles

## TODO

Pull requests are very welcome!!

## Copyright

Copyright © 2014- Kentaro Yoshida ([@yoshi_ken](https://twitter.com/yoshi_ken))

## License

Apache License, Version 2.0
