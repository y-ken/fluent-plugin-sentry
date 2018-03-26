# fluent-plugin-sentry [![Build Status](https://travis-ci.org/rubrikinc/fluent-plugin-sentry.png?branch=master)](https://travis-ci.org/rubrikinc/fluent-plugin-sentry)

## Overview

fluent-plugin-sentry is a fluentd output plugin that sends aggregated errors/exception events to Sentry. Sentry is a event logging and aggregation platform.<br>

Sentry alone does not buffer incoming requests, so if your Sentry instance is under load, Sentry can respond with a 503 Service Unavailable.<br>

fluent-plugin-sentry extends fluent buffered output and enables a fluend user to buffer and flush messages to Sentry with reliable delivery.

* [Sentry Official web](https://getsentry.com/welcome/)
* [Sentry Documents](http://sentry.readthedocs.org/en/latest/) [Screenshots](https://github.com/getsentry/sentry#screenshots)

> ![http://blog.getsentry.com/images/hero.png](https://cloud.githubusercontent.com/assets/1734549/5498750/2b471a6c-8767-11e4-8634-961c99e635ed.png)
(quoted from http://blog.getsentry.com/)


## Installation

install with `gem` or td-agent provided command as:

```bash
# for fluentd
$ gem install fluent-plugin-sentry-rubrik

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-sentry-rubrik

# for td-agent2
$ sudo td-agent-gem install fluent-plugin-sentry-rubrik
```

## Preparation

create sentry dashboard first. It could start with cost free!!

* Create an account at https://getsentry.com/pricing/

OR

* Launch Sentry at the self manager server with https://github.com/getsentry/sentry

## Usage

```xml
<source>
 @type forward
</source>

<match notify.**>
  @type sentry

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
Set to the sentry DSN, as found in the Sentry dashboard.

* default_level<br>
[default] info

If a `level` is not present in the log, `default_level` is assumed.

* default_logger<br>
[default] fluentd

If a `logger` is not present in the log, `default_logger` is assumed.

* hostname_command<br>
[default] hostname
The name of the server reporting the error.

* flush_interval<br>
[default] 0sec

* report_levels
[default] fatal error warning

Only report to Sentry logs with `report_levels`.

Note that the default ignores `info` and `debug` logs. And `default_level`
defaults to `info`. This might ignore more logs than you anticipated.

* tags_key
[default] "" (empty array)

Report those items with the given key as tags to Sentry. This makes it possible
to correlate events via tags. Access to structured tag is supported, for
example, given the following log:

```
"{ msg: foo k8s: { app: myapp, container: mycontainer } }
``` 
The tag key `k8s.app` will add the tag `k8s.app: myapp` to the Sentry event.

* stacktrace_expand_json_escaping
[default] true

When going trough some JSON formatter stacktraces `\n` and `\t` characters are
often escaped. Meaning you will see `\n` instead of a visible line return for
example and `\t` instead of a visual tabulation.

When true (the default) this option will expand the escaped character into the
original control code. This important for successfully parsing stacktraces.

* userid_key
[default] "" (empty array)

List of keys to use as for the Sentry user id. Keys are looked up in order a
log event, first match wins.

Example with `userid_key account, user` and the log
`{ "msg": "foo", "account": "foo", "user": "babar" }` the Sentry user id will
be set to "foo".

Composed IDs are supported. Example with
`userid_key account/user, account, user` and the log as above, the Sentry user
id will be set to "foo/babar".

Forward slash is used to identify the different keys.

* environment
[default] "default"

Can be default, production or development. Used to set the environment tag in
Sentry.

### Tag rewriting

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
