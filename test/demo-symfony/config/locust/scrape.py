#!/usr/bin/env python3
"""Discover GET-able URLs on the demo-symfony site and write them to urls.json.

Runs containerized on the `demo` network and crawls THROUGH Traefik: it hits
TARGET_HOST (http://traefik) with a `Host: SITE_HOST` header (demo.localhost) so
Traefik routes to the symfony vhost, exactly like real edge traffic. Pure stdlib
(urllib + html.parser) so it needs no image with extra packages.

The output feeds locustfile.py, which replays these URLs under load.
"""
import html.parser
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

TARGET_HOST = os.environ.get("TARGET_HOST", "http://traefik").rstrip("/")
SITE_HOST = os.environ.get("SITE_HOST", "demo.localhost")
OUT = os.environ.get("OUT", "/data/urls.json")
MAX_URLS = int(os.environ.get("MAX_URLS", "80"))
MAX_DEPTH = int(os.environ.get("MAX_DEPTH", "3"))
# The demo app is fully localized and every page carries a 28-language switcher.
# Pin the crawl to ONE locale, otherwise the locale cross-product explodes the
# breadth and MAX_URLS is spent before any /blog/posts/ link is reached.
LOCALE = os.environ.get("LOCALE", "fr")
SEEDS = os.environ.get("SEEDS", f"/{LOCALE}/blog/").split(",")
TIMEOUT = float(os.environ.get("TIMEOUT", "10"))

# Never crawl/replay these: auth flip-flops, admin, or mutating (POST) endpoints.
SKIP_SUBSTR = ("/logout", "/admin", "/comment", "/new", "/edit", "/delete")
# Only these query params are meaningful for GET replay (pagination + search).
KEEP_QUERY = ("page", "q")


class LinkParser(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            for k, v in attrs:
                if k == "href" and v:
                    self.hrefs.append(v)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    # Do NOT follow redirects: a redirect would drop our Host header (the new
    # request would target `traefik` and 404). We enqueue the Location instead.
    def redirect_request(self, *args, **kwargs):
        return None


opener = urllib.request.build_opener(NoRedirect)


def fetch(path):
    """Return (status, location, body) for a GET on TARGET_HOST+path (Host spoofed)."""
    req = urllib.request.Request(TARGET_HOST + path, headers={"Host": SITE_HOST})
    try:
        resp = opener.open(req, timeout=TIMEOUT)
        status = resp.getcode()
        if 300 <= status < 400:
            return status, resp.headers.get("Location"), ""
        ctype = resp.headers.get("Content-Type", "")
        body = resp.read().decode("utf-8", "replace") if "html" in ctype else ""
        return status, None, body
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get("Location"), ""
    except (urllib.error.URLError, OSError) as e:
        print(f"  ! {path}: {e}", file=sys.stderr)
        return 0, None, ""


def normalize(href, base_path):
    """Resolve href to a same-site '/path[?keep-query]' or return None."""
    if href.startswith(("mailto:", "tel:", "javascript:", "#")):
        return None
    abs_url = urllib.parse.urljoin(f"http://{SITE_HOST}{base_path}", href)
    parts = urllib.parse.urlsplit(abs_url)
    if parts.netloc and parts.netloc != SITE_HOST:
        return None
    if not parts.path.startswith("/"):
        return None
    # Stay within the pinned locale (skip the language-switcher's other locales).
    if not parts.path.startswith(f"/{LOCALE}/"):
        return None
    kept = [(k, v) for k, v in urllib.parse.parse_qsl(parts.query) if k in KEEP_QUERY]
    path = parts.path
    if kept:
        path += "?" + urllib.parse.urlencode(kept)
    if any(s in path for s in SKIP_SUBSTR):
        return None
    return path


def categorize(path):
    if "rss.xml" in path:
        return "other"
    if "/blog/posts/" in path:
        return "posts"
    if "/blog/search" in path:
        return "search"
    if "/login" in path:
        return "other"
    if "/blog/" in path or path.rstrip("/").endswith("/blog"):
        return "listing"
    return "other"


def main():
    seen = set()
    queue = [(s.strip(), 0) for s in SEEDS if s.strip()]
    collected = set()

    while queue and len(collected) < MAX_URLS:
        path, depth = queue.pop(0)
        if path in seen:
            continue
        seen.add(path)

        status, location, body = fetch(path)
        if 300 <= status < 400 and location:
            loc = normalize(location, path)
            if loc and loc not in seen:
                queue.append((loc, depth))
            continue
        if status != 200:
            continue

        collected.add(path)
        if depth >= MAX_DEPTH:
            continue

        parser = LinkParser()
        parser.feed(body)
        for href in parser.hrefs:
            nxt = normalize(href, path)
            if nxt and nxt not in seen:
                queue.append((nxt, depth + 1))

    # Bucket by kind; always seed a couple of search queries (search is a GET form,
    # so its result URLs are rarely present as plain <a> links to discover).
    buckets = {"listing": [], "posts": [], "search": [], "other": []}
    for p in sorted(collected):
        buckets[categorize(p)].append(p)
    for q in ("lorem", "sit", "aut"):
        buckets["search"].append(f"/{LOCALE}/blog/search?q={q}")
    buckets["search"] = sorted(set(buckets["search"]))

    os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(buckets, fh, indent=2, ensure_ascii=False)

    total = sum(len(v) for v in buckets.values())
    print(f"✅ scraped {total} URLs → {OUT}")
    for k, v in buckets.items():
        print(f"   {k:8} {len(v)}")
    # A totally empty crawl means the site was unreachable — fail loudly.
    if total == 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
