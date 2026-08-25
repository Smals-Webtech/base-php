"""Locust load profile for demo-symfony.

Replays the URLs discovered by scrape.py (urls.json) through Traefik, spoofing the
`Host: demo.localhost` header so Traefik routes to the symfony vhost. The generated
traffic flows through nginx + php-fpm, whose logfmt access logs the sidecar Alloy
ships to Loki — so a run lights up `{job="symfony"}` with correlated nginx/php-fpm
lines (shared request id).

Driven by env (set by the Makefile / compose):
  LOCUST_HOST         base URL (http://traefik)
  SITE_HOST           Host header to route through Traefik (default demo.localhost)
  URLS_FILE           discovered URLs (default /mnt/locust/urls.json)
"""
import json
import os
import random

from locust import HttpUser, between, task

SITE_HOST = os.environ.get("SITE_HOST", "demo.localhost")
URLS_FILE = os.environ.get("URLS_FILE", "/mnt/locust/urls.json")

# Fallback seed so a run never hard-fails if scrape.py has not run yet.
_FALLBACK = {
    "listing": ["/fr/blog/"],
    "posts": [],
    "search": ["/fr/blog/search?q=lorem"],
    "other": ["/fr/login"],
}


def _load_urls():
    try:
        with open(URLS_FILE, encoding="utf-8") as fh:
            data = json.load(fh)
        if any(data.get(k) for k in ("listing", "posts", "search", "other")):
            return data
    except (OSError, ValueError):
        pass
    return _FALLBACK


URLS = _load_urls()


def _pick(bucket, fallback):
    choices = URLS.get(bucket) or [fallback]
    return random.choice(choices)


class DemoUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        # Persistent Host header → Traefik routes every request to the symfony vhost.
        self.client.headers.update({"Host": SITE_HOST})

    @task(8)
    def post(self):
        self.client.get(_pick("posts", "/fr/blog/"), name="/blog/posts/[slug]")

    @task(5)
    def listing(self):
        self.client.get(_pick("listing", "/fr/blog/"), name="/blog/[listing]")

    @task(3)
    def search(self):
        self.client.get(_pick("search", "/fr/blog/search?q=lorem"), name="/blog/search")

    @task(1)
    def rss(self):
        self.client.get("/fr/blog/rss.xml", name="/blog/rss.xml")

    @task(1)
    def login(self):
        self.client.get("/fr/login", name="/login")
