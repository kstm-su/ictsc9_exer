#!/bin/sh
set -xue
/usr/sbin/sshd
rsyslogd -dn
