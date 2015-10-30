# fluent-plugin-sentry [![Build Status](https://travis-ci.org/y-ken/fluent-plugin-sentry.png?branch=master)](https://travis-ci.org/y-ken/fluent-plugin-sentry)

## Overview

fluent-plugin-sentry is a fluentd output plugin that sends aggregated errors/exception events to Sentry. Sentry is a event logging and aggregation platform.<br>

Sentry alone does not buffer incoming requests, so if your Sentry instance is under load, Sentry can respond with a 503 Service Unavailable.<br>

fluent-plugin-sentry extends fluent buffered output and enables a fluend user to buffer and flush messages to Sentry with reliable delivery.

* [Sentry Official web](https://getsentry.com/welcome/)
* [Sentry Documents](http://sentry.readthedocs.org/en/latest/) [Screenshots](https://github.com/getsentry/sentry#screenshots)

> ![http://blog.getsentry.com/images/hero.png](https://cloud.githubusercontent.com/assets/1734549/5498750/2b471a6c-8767-11e4-8634-961c99e635ed.png)
(quoted from http://blog.getsentry.com/)


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
  endpoint_url       https://API_KEY:API_PASSWORD@app.getsentry.com/PROJECT_ID

  # Set default events value of 'server_name'
  # To set short hostname, set like below.
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
[default] hostname
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
