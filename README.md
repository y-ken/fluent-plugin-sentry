# fluent-plugin-sentry [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-sentry.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-sentry)

## Overview

Fluentd output plugin to send aggregated errors/exception events to Sentry which are a realtime event logging and aggregation platform.<br>

If you have sent events to Sentry directory from front webpage without aggregation, you may got down response time and performance problem (e.g. PHP).<br>
To use Sentry and Fluentd together, it will got best perfomance because Fluentd acts messege queue for Sentry.

* [Sentry Official web](https://getsentry.com/welcome/)
* [Sentry Documents](http://sentry.readthedocs.org/en/latest/) [Screenshots](https://github.com/getsentry/sentry#screenshots)

## Installation

install with `gem` or `fluent-gem` command as:

```bash
# for fluentd
$ gem install fluent-plugin-sentry

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-sentry
```

## Preparation

create sentry dashboard first. It could start with cost free!!

* Create an account at https://getsentry.com/pricing/

OR

* Launch Sentry at the self manager server with https://github.com/getsentry/sentry

## Usage

```xml
<source>
 type forward
</source>

<match notify.**>
  type sentry

  # Set endpoint API URL
  endpoint_url       https://${api_key}:${api_password}@app.getsentry.com/${project_id}

  # Set default events value of 'server_name'
  hostname_command   hostname -s

  # rewrite shown tag name for Sentry dashboard
  remove_tag_prefix  notify.
</match>
```

## Parameters

* endpoint_url (Required)<br>
Set endpoint API URL which shows at Sentry dashboard. (it is not sentry account information)

* default_level<br>
[default] error

* defalut_logger<br>
[default] flunetd

* hostname_command<br>
Set default frontend value of 'server_name'

* flush_interval<br>
[default] 0sec

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
