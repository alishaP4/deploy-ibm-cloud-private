#!/bin/bash

################################################################
# Module to deploy IBM Cloud Private
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

/usr/sbin/ufw disable
/usr/bin/apt update
/usr/bin/apt-get --assume-yes install haproxy

HAPROXY_DIR="/etc/haproxy/"
cd "HAPROXY_DIR"

# Remove the content of the haproxy.cfg file (this is w.r.to HDC environment only)
> ./haproxy.cfg

echo "
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
# Global settings
global
      # To view messages in the /var/log/haproxy.log you need to:
      #
      # 1) Configure syslog to accept network log events.  This is done
      #    by adding the '-r' option to the SYSLOGD_OPTIONS in
      #    /etc/sysconfig/syslog.
      #
      # 2) Configure local2 events to go to the /var/log/haproxy.log
      #   file. A line similar to the following can be added to
      #   /etc/sysconfig/syslog.
      #
      #    local2.*                       /var/log/haproxy.log
      #
      log         127.0.0.1 local2

      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     4000
      user        haproxy
      group       haproxy
      daemon

      # 3) Turn on stats unix socket
      stats socket /var/lib/haproxy/stats
# Common defaults that all the 'listen' and 'backend' sections
# use, if not designated in their block.
  defaults
      mode                    http
      log                     global
      option                  httplog
      option                  dontlognull
      option http-server-close
      option                  redispatch
      retries                 3
      timeout http-request    10s
      timeout queue           1m
      timeout connect         10s
      timeout client          1m
      timeout server          1m
      timeout http-keep-alive 10s
      timeout check           10s
      maxconn                 3000

  frontend k8s-api
      bind *:8001
      mode tcp
      option tcplog
      use_backend k8s-api

  backend k8s-api
      mode tcp
      balance roundrobin
      server server1 10.29.0.21:8001
      server server2 10.29.0.22:8001
      server server3 10.29.0.23:8001

  frontend dashboard
      bind *:8443
      mode tcp
      option tcplog
      use_backend dashboard

  backend dashboard
      mode tcp
      balance roundrobin
      server server1 10.29.0.21:8443
      server server2 10.29.0.22:8443
      server server3 10.29.0.23:8443

  frontend auth
      bind *:9443
      mode tcp
      option tcplog
      use_backend auth

  backend auth
      mode tcp
      balance roundrobin
      server server1 10.29.0.21:9443
      server server2 10.29.0.22:9443
      server server3 10.29.0.23:9443

  frontend registry
      bind *:8500
      mode tcp
      option tcplog
      use_backend registry

  frontend image-manager
      bind *:8600
      mode tcp
      option tcplog
      use_backend image-manager

  backend image-manager
      mode tcp
      balance roundrobin
      server server1 10.29.0.21:8600
      server server2 10.29.0.22:8600
      server server3 10.29.0.23:8600

  backend registry
      mode tcp
      balance roundrobin
      server server1 10.29.0.21:8500
      server server2 10.29.0.22:8500
      server server3 10.29.0.23:8500

  frontend proxy-http
      bind *:80
      mode tcp
      option tcplog
      use_backend proxy-http

  backend proxy-http
      mode tcp
      balance roundrobin
      server server1 10.29.0.41:80
      server server2 10.29.0.42:80

  frontend proxy-https
      bind *:443
      mode tcp
      option tcplog
      use_backend proxy-https

  backend proxy-https
      mode tcp
      balance roundrobin
      server server1 10.29.0.41:443
      server server2 10.29.0.42:443
" >> ./haproxy.cfg

exit 0
