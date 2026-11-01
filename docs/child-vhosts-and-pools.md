# Bringing your own vhost or php-fpm pool

A child image often serves its application from a vhost and a php-fpm pool of its own rather than
from the image's default ones. Part of what the image configures reaches them without any effort,
and part does not. This page lists both, for the nginx variants.

The short version: what the image sets at nginx's `http` level and in php-fpm's `[global]` section
applies to your vhost and your pool too. What it sets inside its **default server** and its **`[www]`
pool** does not, and you repeat it.

## Where the files go

They are rendered at every start, before Supervisor starts nginx and php-fpm:

| What | Template | Rendered to |
|------|----------|-------------|
| A vhost | `/opt/config/nginx/sites-enabled/<name>.conf.tmpl` | `/opt/etc/nginx/sites-enabled/<name>.conf` |
| `http`-level directives | `/opt/config/nginx/http.d/<name>.conf.tmpl` | `/opt/etc/nginx/http.d/<name>.conf` |
| A pool | `/opt/config/php/php-fpm.d/<name>.conf.tmpl` | `/opt/etc/php/php-fpm.d/<name>.conf` |

`http.d` is for what nginx only accepts in its `http` block and your vhosts use: a `map`, a
`limit_req_zone`, an `upstream`. It is included in the `http` block, before the vhosts. `conf.d`
belongs to the image: its files are rendered one by one, some only when a feature is on, and
included by name, so a template added there is not loaded.

A template sees the resolved environment, so it can reuse the image's own settings
(`{{ .Env.PHP_FPM_REQUEST_TERMINATE_TIMEOUT }}`) and follow them when an operator changes them. A
file rendered by your own code — one vhost per tenant, say — belongs in a boot hook
(`/opt/bin/container-entrypoint.d/boot.d/`), which also runs at every start. A late hook runs once
per `/app/var` volume, and the file would then be missing whenever `/opt/etc` does not survive the
restart.

### Mounting them from a ConfigMap

On Kubernetes and OpenShift, mount the file **as a template under `/opt/config`**, never into
`/opt/etc`. `/opt/etc` is the output of the rendering, and it is an `emptyDir` you start empty. To
mount a single file (`subPath`), the runtime first creates its missing parent directories, as root.
An arbitrary uid then cannot create the directories the entrypoint renders into next to them, and the
container refuses to start: `/opt/etc/nginx/conf.d is not writable`. `/opt/config` ships with the
image, so a mount there creates no parent.

A file without `{{ }}` is rendered unchanged, so a plain nginx file only needs the `.tmpl` suffix.
Files that only need to be read, such as snippets your vhost includes, can stay where they are
mounted. Mount the whole ConfigMap as a directory and include it from there:

```yaml
volumeMounts:
  - name: nginx-vhost
    mountPath: /opt/config/nginx/sites-enabled/myapp.conf.tmpl
    subPath: myapp.conf
  - name: nginx-http
    mountPath: /opt/config/nginx/http.d/myapp-limits.conf.tmpl
    subPath: myapp-limits.conf
  - name: nginx-snippets
    mountPath: /opt/config/nginx/snippets
```

```nginx
server {
    # ...
    include /opt/config/nginx/snippets/*.conf;
}
```

Only the first level of `/opt/config/nginx/`, `http.d/` and `sites-enabled/` is rendered, so a
template in a subdirectory of your own, such as `snippets/`, is not.

A rate limit of your own is a zone in `http.d` and a `limit_req` in your vhost. nginx answers 503
when it rejects a request unless the vhost sets `limit_req_status 429;`. The image's soft throttling
(`NGINX_SOFT_THROTTLE_*`, see below) may already cover the need.

## What applies to your vhost without effort

Set at nginx's `http` level, inherited by every server block unless it sets its own value:

- access log and its format (`NGINX_DEFAULT_ACCESS_LOG_*`), `server_tokens off`;
- real client IP (`NGINX_REAL_IP_*`), when enabled;
- request limits and buffers: `client_max_body_size`, `large_client_header_buffers`,
  `fastcgi_buffer_size`, `fastcgi_buffers`;
- timeouts: `fastcgi_read_timeout` (`65s`), `fastcgi_send_timeout`, `keepalive_timeout`,
  `send_timeout`, `client_*_timeout`;
- gzip, and the FastCGI cache zone (not its use: see below);
- the monitoring ACL's `$monitoring_forbidden` variable.

## What you repeat in your vhost

Set inside the image's default server, so absent from yours unless you write it:

- **Dotfiles.** `.env`, `.git` and editor backups under your root are served as plain files
  otherwise.
- **The PHP location.** The image's form guards the path-info attack (`/uploads/photo.jpg/x.php` is a
  404, not a JPEG run as PHP) and passes `PATH_INFO` to a front controller.
- **Soft throttling.** One `include` line, which does nothing while `NGINX_SOFT_THROTTLE_ENABLED` is
  off. See [Rate Limiting](../README.md#rate-limiting-soft-throttle).
- **The FastCGI cache**, if you want it: the `fastcgi_cache*` lines of the default server.

```nginx
server {
    listen {{ .Env.NGINX_LISTEN }};
    server_name myapp.example;

    root /app/src/myapp/public;
    index index.php;

    include /opt/etc/nginx/conf.d/throttling-server.conf;

    location ~ ^/\.well-known/ {
    }

    location ~ /\. {
        access_log off;
        return 404;
    }

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^(?<script_name>.+\.php)(?<path_info>/.*)?$ {
        try_files $script_name =404;

        fastcgi_param SCRIPT_FILENAME $document_root$script_name;
        fastcgi_param PATH_INFO $path_info;

        include fastcgi_params;

        fastcgi_pass unix:/app/var/run/php-fpm/myapp.sock;
    }
}
```

**Monitoring endpoints of your own** — an application metrics page, a status page — are open to any
network unless you guard them. Use the image's ACL, which follows `MONITORING_ALLOW`:

```nginx
location = /app-metrics {
    if ($monitoring_forbidden) { return 403; }
    # ...
}
```

## What applies to your pool without effort

Set in php-fpm's `[global]` section, shared by every pool:

- `process_control_timeout` (`15s`): on a graceful stop, a worker finishes the request in hand;
- the error log and its level.

## What you repeat in your pool

Everything in the image's `[www]` pool is per pool. The settings that matter most:

- **`request_terminate_timeout`** (`75s`). Without it a worker blocked on I/O is never released,
  since `max_execution_time` does not count I/O. It sits just above nginx's `65s`: raise both
  together.
- **The slow log** (`slowlog`, `request_slowlog_timeout`). Give each pool its own file, ending in
  `.log` under `/app/var/log` so that it is rotated.
- **Worker output and the access log**, with the client address.
- **`clear_env`.** At `no`, the image's default, workers see the container's environment after the
  entrypoint has cleaned it. If you pass variables with `env[]` instead, leave out the names listed in
  `CLEANUP_VAR_LIST`, or you hand back what the cleanup removed.

```ini
[myapp]
listen = /app/var/run/php-fpm/myapp.sock
listen.mode = {{ .Env.PHP_FPM_LISTEN_MODE }}

clear_env = {{ .Env.PHP_FPM_CLEAR_ENV }}
access.log = {{ .Env.PHP_FPM_ACCESS_LOG }}
access.format = "{{ .Env.PHP_FPM_ACCESS_FORMAT }}"
catch_workers_output = {{ .Env.PHP_FPM_CATCH_WORKERS_OUTPUT }}
decorate_workers_output = {{ .Env.PHP_FPM_DECORATE_WORKERS_OUTPUT }}

pm = {{ .Env.PHP_FPM_PM }}
pm.max_children = {{ .Env.PHP_FPM_PM_MAX_CHILDREN }}
pm.process_idle_timeout = {{ .Env.PHP_FPM_PM_PROCESS_IDLE_TIMEOUT }}
pm.max_requests = {{ .Env.PHP_FPM_PM_MAX_REQUESTS }}

request_terminate_timeout = {{ .Env.PHP_FPM_REQUEST_TERMINATE_TIMEOUT }}
request_terminate_timeout_track_finished = {{ .Env.PHP_FPM_REQUEST_TERMINATE_TIMEOUT_TRACK_FINISHED }}
slowlog = /app/var/log/php-fpm-myapp-slow.log
request_slowlog_timeout = {{ .Env.PHP_FPM_REQUEST_SLOWLOG_TIMEOUT }}
request_slowlog_trace_depth = {{ .Env.PHP_FPM_REQUEST_SLOWLOG_TRACE_DEPTH }}
```

**Sizing multiplies.** `pm.max_children` is per pool, and the image's `[www]` pool stays: a container
with your pool and the image's may start twice `PHP_FPM_PM_MAX_CHILDREN` workers, and N pools N+1
times as many, each bounded by `memory_limit`. Size the pools against the container's memory, not
one by one.
