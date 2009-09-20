#!/bin/sh
LD_PRELOAD=/usr/lib/libv4l/v4l1compat.so vgrabbj -o jpeg -f /var/grab/at/latest.jpg -d /dev/video0 -l 60  -z 5 -n -A "/var/grab/at/%Y%m%d%H%M%s.jpg" -E 1 -M 32000 -R # -D 7 -X
