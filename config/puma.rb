#!/usr/bin/env puma

#path='/home/miguel/webapps/mileage'
#directory path
environment 'production'
#daemonize true

#pidfile "#{path}/tmp/mileage.pid"
bind 'tcp://0.0.0.0:9000'
