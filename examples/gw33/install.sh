#!/bin/sh
# install.sh -- put ghostlights.theater on gw33's nginx: files, the port-80 block, the certificate
# (certbot by webroot), then the TLS block. Backs out on any nginx -t failure, putting the previous
# site file back; never deletes another site. Safe to run again. Run as the gw33 account on gw33.
# Copyright 2026 INPUTLOOP; GPL-3.0-or-later OR LGPL-3.0-or-later.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
N=/etc/nginx; SITE=$N/sites-available/ghostlights.theater; WWW=/var/www/ghostlights.theater
LE=/etc/letsencrypt/live/ghostlights.theater
swap() {  # swap CONF: install it as the site; on nginx -t failure put the previous file back
  prev=$(mktemp); had=0; if sudo test -f "$SITE"; then sudo cp "$SITE" "$prev"; had=1; fi
  sudo install -m 644 "$here/$1" "$SITE"; sudo ln -sf "$SITE" "$N/sites-enabled/ghostlights.theater"
  if sudo nginx -t 2>&1; then sudo systemctl reload nginx; sleep 2; echo "installed $1; nginx reloaded"; rm -f "$prev"
  else if [ $had = 1 ]; then sudo install -m 644 "$prev" "$SITE"; else sudo rm -f "$N/sites-enabled/ghostlights.theater"; fi
       rm -f "$prev"; echo "nginx -t failed with $1: the previous site file is back" >&2; exit 1; fi
}
# The site's own request and error logs (logreq A+agent, 2026-11-04): their folder must exist before nginx -t,
# and their rotation file sits beside the stock one.
sudo install -d -m 0755 -o root -g adm /var/log/nginx/ghostlights.theater
sudo install -m 644 "$here/logrotate-ghostlights.theater" /etc/logrotate.d/nginx-ghostlights.theater
sudo mkdir -p "$WWW"
if sudo test -d "$WWW/public"; then sudo cp -a "$WWW/public" "$WWW/public.before-$(date -u +%Y%m%d-%H%M%S)"; fi
sudo rsync -a --delete "$here/../public/" "$WWW/public/"
if sudo test -s "$LE/fullchain.pem"; then swap nginx-ghostlights.theater.conf
else
  swap ghostlights.theater.interim.conf
  sudo certbot certonly --webroot -w "$WWW/public" -d ghostlights.theater -d www.ghostlights.theater \
    --non-interactive --agree-tos --keep-until-expiring
  sudo test -s "$LE/fullchain.pem" || { echo "no certificate yet: the port-80 site stays; run again later" >&2; exit 1; }
  swap nginx-ghostlights.theater.conf
fi
curl -s -o /dev/null -w 'https front page: %{http_code}\n' --resolve ghostlights.theater:443:127.0.0.1 https://ghostlights.theater/
curl -s -o /dev/null -w 'https book: %{http_code}\n' --resolve ghostlights.theater:443:127.0.0.1 https://ghostlights.theater/build-a-ghostwheel/
curl -s -o /dev/null -w 'http redirects: %{http_code}\n' -H 'Host: ghostlights.theater' http://127.0.0.1/
