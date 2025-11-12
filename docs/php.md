# PHP Configuration

## core php.ini directives

### Language Options

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `short_open_tag` | PHP_SHORT_OPEN_TAG | "Off" | [Link](https://www.php.net/manual/en/ini.core.php#ini.short-open-tag) |
| `precision` | PHP_PRECISION | "14" | [Link](https://www.php.net/manual/en/ini.core.php#ini.precision) |
| `serialize_precision` | PHP_SERIALIZE_PRECISION | "-1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.serialize-precision) |
| `disable_functions` | PHP_DISABLE_FUNCTIONS | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.disable-functions) |
| `disable_classes` | PHP_DISABLE_CLASSES | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.disable-classes) |
| `exit_on_timeout` | PHP_EXIT_ON_TIMEOUT | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.exit-on-timeout) |
| `expose_php` | PHP_EXPOSE_PHP | "false" | [Link](https://www.php.net/manual/en/ini.core.php#ini.expose-php) |
| `hard_timeout` | PHP_HARD_TIMEOUT | "2" | [Link](https://www.php.net/manual/en/ini.core.php#ini.hard-timeout) |
| `zend.exception_ignore_args` | PHP_ZEND_EXCEPTION_IGNORE_ARGS | "On" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.exception-ignore-args) | <- dev/prod !? >
| `zend.multibyte` | PHP_ZEND_MULTIBYTE | "Off" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.multibyte) |
| `zend.script_encoding` | PHP_ZEND_SCRIPT_ENCODING | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.script-encoding) |
| `zend.detect_unicode` | PHP_ZEND_DETECT_UNICODE | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.detect-unicode) |
| `zend.signal_check` | PHP_ZEND_SIGNAL_CHECK | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.signal-check) |
| `zend.assertions` | PHP_ZEND_ASSERTIONS | "-1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.assertions) | <- dev/prod !? >
| `zend.exception_string_param_max_len` | PHP_ZEND_EXCEPTION_STRING_PARAM_MAX_LEN | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.exception-string-param-max-len) | <- dev/prod !? >

### Resource Limits

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `memory_limit` | PHP_MEMORY_LIMIT | "128M" | [Link](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) |

### Performance Tuning

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `realpath_cache_size` | PHP_REALPATH_CACHE_SIZE | "4M" | [Link](https://www.php.net/manual/en/ini.core.php#ini.realpath-cache-size) |
| `realpath_cache_ttl` | PHP_REALPATH_CACHE_TTL | "120" | [Link](https://www.php.net/manual/en/ini.core.php#ini.realpath-cache-ttl) |

### Data Handling

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `arg_separator.output` | PHP_ARG_SEPARATOR_OUTPUT | "&" | [Link](https://www.php.net/manual/en/ini.core.php#ini.arg-separator.output) |
| `arg_separator.input` | PHP_ARG_SEPARATOR_INPUT | "&" | [Link](https://www.php.net/manual/en/ini.core.php#ini.arg-separator.input) |
| `variables_order` | PHP_VARIABLES_ORDER | "EGPCS" | [Link](https://www.php.net/manual/en/ini.core.php#ini.variables-order) |
| `request_order` | PHP_REQUEST_ORDER | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.request-order) |
| `auto_globals_jit` | PHP_AUTO_GLOBALS_JIT | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.auto-globals-jit) |
| `register_argc_argv` | PHP_REGISTER_ARGC_ARGV | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.register-argc-argv) |
| `enable_post_data_reading` | PHP_ENABLE_POST_DATA_READING | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.enable-post-data-reading) |
| `post_max_size` | PHP_POST_MAX_SIZE | "8M" | [Link](https://www.php.net/manual/en/ini.core.php#ini.post-max-size) |
| `auto_prepend_file` | PHP_AUTO_PREPEND_FILE | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.auto-prepend-file) |
| `auto_append_file` | PHP_AUTO_APPEND_FILE | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.auto-append-file) |
| `default_mimetype` | PHP_DEFAULT_MIMETYPE | "text/html" | [Link](https://www.php.net/manual/en/ini.core.php#ini.default-mimetype) |
| `default_charset` | PHP_DEFAULT_CHARSET | "UTF-8" | [Link](https://www.php.net/manual/en/ini.core.php#ini.default-charset) |
| `input_encoding` | PHP_INPUT_ENCODING | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.input-encoding) |
| `output_encoding` | PHP_OUTPUT_ENCODING | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.output-encoding) |
| `internal_encoding` | PHP_INTERNAL_ENCODING | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.internal-encoding) |

### Paths and Directories

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `include_path` | PHP_INCLUDE_PATH | ".:/usr/local/lib/php" | [Link](https://www.php.net/manual/en/ini.core.php#ini.include-path) |
| `open_basedir` | PHP_OPEN_BASEDIR | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.open-basedir) |
| `doc_root` | PHP_DOC_ROOT | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.doc-root) |
| `user_dir` | PHP_USER_DIR | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.user-dir) |
| `user_ini.cache_ttl` | PHP_USER_INI_CACHE_TTL | "300" | [Link](https://www.php.net/manual/en/ini.core.php#ini.user-ini.cache-ttl) |
| `user_ini.filename` | PHP_USER_INI_FILENAME | ".user.ini" | [Link](https://www.php.net/manual/en/ini.core.php#ini.user-ini.filename) |
| `extension_dir` | PHP_EXTENSION_DIR | "/opt/etc/php/extensions" | [Link](https://www.php.net/manual/en/ini.core.php#ini.extension-dir) |
| `extension` | PHP_EXTENSION | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.extension) |
| `zend_extension` | PHP_ZEND_EXTENSION | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend-extension) |
| `cgi.check_shebang_line` | PHP_CGI_CHECK_SHEBANG_LINE | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.check-shebang-line) |
| `cgi.discard_path` | PHP_CGI_DISCARD_PATH | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.discard-path) |
| `cgi.fix_pathinfo` | PHP_CGI_FIX_PATHINFO | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.fix-pathinfo) |
| `cgi.force_redirect` | PHP_CGI_FORCE_REDIRECT | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.force-redirect) |
| `cgi.nph` | PHP_CGI_NPH | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.nph) |
| `cgi.redirect_status_env` | PHP_CGI_REDIRECT_STATUS_ENV | "" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.redirect-status-env) |
| `cgi.rfc2616_headers` | PHP_CGI_RFC2616_HEADERS | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.cgi.rfc2616-headers) |
| `fastcgi.impersonate` | PHP_FASTCGI_IMPERSONATE | "0" | [Link](https://www.php.net/manual/en/ini.core.php#ini.fastcgi.impersonate) |
| `fastcgi.logging` | PHP_FASTCGI_LOGGING | "1" | [Link](https://www.php.net/manual/en/ini.core.php#ini.fastcgi.logging) |

### File Uploads

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `file_uploads` | PHP_FILE_UPLOADS | "On" | [Link](https://www.php.net/manual/en/ini.core.php#ini.file-uploads) |
| `upload_tmp_dir` | php_upload_tmp_dir | Empty | [Link](https://www.php.net/manual/en/ini.core.php#ini.upload-tmp-dir) |
| `upload_max_filesize` | PHP_UPLOAD_MAX_FILESIZE | "2M" | [Link](https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize) |
| `max_file_uploads` | PHP_MAX_FILE_UPLOADS | "20" | [Link](https://www.php.net/manual/en/ini.core.php#ini.max-file-uploads) |

## Affecting PHP's Behaviour

### PHP Options/Info

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `max_input_nesting_level` | PHP_MAX_INPUT_NESTING_LEVEL | 64 | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-input-nesting-level) |
| `max_input_vars` | PHP_MAX_INPUT_VARS | 1000 | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-input-vars) |
| `max_execution_time` | PHP_MAX_EXECUTION_TIME | "30" | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time) |
| `max_input_time` | PHP_MAX_INPUT_TIME | "60" | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-input-time) |

### Error Handling and Logging

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `log_errors` | PHP_LOG_ERRORS | "On" | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.log-errors) |
| `error_reporting` | PHP_ERROR_REPORTING | "E_ALL & ~E_DEPRECATED" | [Link](https://www.php.net/manual/en/function.error-reporting.php) |
| `ignore_repeated_errors` | PHP_IGNORE_REPEATED_ERRORS | "Off" | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.ignore-repeated-errors) |
| `ignore_repeated_source` | PHP_IGNORE_REPEATED_SOURCE | "Off" | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.ignore-repeated-source) |
| `report_memleaks` | PHP_REPORT_MEMLEAKS | "On" | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.report-memleaks) |
| `display_errors` | PHP_DISPLAY_ERRORS | "60" | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.display-errors) |

### APCu

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `apc.enabled` | PHP_APC_ENABLED | "On" | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.enabled) |
| `apc.coredump_unmap` | PHP_APC_COREDUMP_UNMAP | "Off" | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.coredump-unmap) |
| `apc.enable_cli` | PHP_APC_ENABLE_CLI | "Off" | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.enable-cli) |
| `apc.entries_hint` | PHP_APC_ENTRIES_HINT | "0" | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.entries-hint) |
| `apc.gc_ttl` | PHP_APC_GC_TTL | "3600" | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.gc-ttl) |
| `apc.mmap_file_mask` | PHP_APC_MMAP_FILE_MASK | Empty | [Link](https://www.php.net/manual/en/apcu.configuration.php#ini.apcu.mmap-file-mask) |
| `apc.mmap_hugepage_size` | PHP_APC_MMAP_HUGEPAGE_SIZE | "0" |  |
| `apc.preload_path` | PHP_APC_PRELOAD_PATH | Empty | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.preload-path) |
| `apc.serializer` | PHP_APC_SERIALIZER | "php" | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.serializer) |
| `apc.shm_size` | PHP_APC_SHM_SIZE | "32M" | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.shm-size) |
| `apc.slam_defense` | PHP_APC_SLAM_DEFENSE | "Off" | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.slam-defense) |
| `apc.smart` | PHP_APC_SMART | "0" | |
| `apc.ttl` | PHP_APC_TTL | "0" | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.ttl) |
| `apc.use_request_time` | PHP_APC_USE_REQUEST_TIME | "Off" | [Link](https://www.php.net/manual/fr/apcu.configuration.php#ini.apcu.use-request-time) |

### OPcache

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `opcache.enable` | PHP_OPCACHE_ENABLE | "On" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.enable) |
| `opcache.enable_cli` | PHP_OPCACHE_ENABLE_CLI | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.enable-cli) |
| `opcache.blacklist_filename` | PHP_OPCACHE_BLACKLIST_FILENAME | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.blacklist-filename) |
| `opcache.dups_fix` | PHP_OPCACHE_DUPS_FIX | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.dups-fix) |
| `opcache.enable_file_override` | PHP_OPCACHE_ENABLE_FILE_OVERRIDE | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.enable-file-override) |
| `opcache.error_log` | PHP_OPCACHE_ERROR_LOG | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.error-log) |
| `opcache.file_cache` | PHP_OPCACHE_FILE_CACHE | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.file-cache) |
| `opcache.file_cache_consistency_checks` | PHP_OPCACHE_FILE_CACHE_CONSISTENCY_CHECKS | "On" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.file-cache-consistency-checks) |
| `opcache.file_cache_only` | PHP_OPCACHE_FILE_CACHE_ONLY | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.file-cache-only) |
| `opcache.file_update_protection` | PHP_OPCACHE_FILE_UPDATE_PROTECTION | "2" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.file_update_protection) |
| `opcache.force_restart_timeout` | PHP_OPCACHE_FORCE_RESTART_TIMEOUT | "180" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.force-restart-timeout) |
| `opcache.huge_code_pages` | PHP_OPCACHE_HUGE_CODE_PAGES | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.huge_code_pages) |
| `opcache.interned_strings_buffer` | PHP_OPCACHE_INTERNED_STRINGS_BUFFER | "8" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.interned-strings-buffer) |
| `opcache.jit` | PHP_OPCACHE_JIT | "disable" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit) |
| `opcache.jit_bisect_limit` | PHP_OPCACHE_JIT_BISECT_LIMIT | "0" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-bisect-limit) |
| `opcache.jit_blacklist_root_trace` | PHP_OPCACHE_JIT_BLACKLIST_ROOT_TRACE | "16" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-blacklist-root-trace) |
| `opcache.jit_blacklist_side_trace` | PHP_OPCACHE_JIT_BLACKLIST_SIDE_TRACE | "8" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-blacklist-side-trace) |
| `opcache.jit_buffer_size` | PHP_OPCACHE_JIT_BUFFER_SIZE | "64M" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-buffer-size) |
| `opcache.jit_debug` | PHP_OPCACHE_JIT_DEBUG | "0" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-debug) |
| `opcache.jit_hot_func` | PHP_OPCACHE_JIT_HOT_FUNC | "127" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-hot-func) |
| `opcache.jit_hot_loop` | PHP_OPCACHE_JIT_HOT_LOOP | "64" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-hot-loop) |
| `opcache.jit_hot_return` | PHP_OPCACHE_JIT_HOT_RETURN | "8" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-hot-return) |
| `opcache.jit_hot_side_exit` | PHP_OPCACHE_JIT_HOT_SIDE_EXIT | "8" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-hot-side-exit) |
| `opcache.jit_max_exit_counters` | PHP_OPCACHE_JIT_MAX_EXIT_COUNTERS | "8192" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-exit-counters) |
| `opcache.jit_max_loop_unrolls` | PHP_OPCACHE_JIT_MAX_LOOP_UNROLLS | "8" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-loop-unrolls) |
| `opcache.jit_max_polymorphic_calls` | PHP_OPCACHE_JIT_MAX_POLYMORPHIC_CALLS | "2" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-polymorphic-calls) |
| `opcache.jit_max_recursive_calls` | PHP_OPCACHE_JIT_MAX_RECURSIVE_CALLS | "2" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-recursive-calls) |
| `opcache.jit_max_recursive_returns` | PHP_OPCACHE_JIT_MAX_RECURSIVE_RETURNS | "2" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-recursive-return) |
| `opcache.jit_max_root_traces` | PHP_OPCACHE_JIT_MAX_ROOT_TRACES | "1024" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-root-traces) |
| `opcache.jit_max_side_traces` | PHP_OPCACHE_JIT_MAX_SIDE_TRACES | "128" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-max-side-traces) |
| `opcache.jit_max_trace_length` | PHP_OPCACHE_JIT_MAX_TRACE_LENGTH | "1024" | |
| `opcache.jit_prof_threshold` | PHP_OPCACHE_JIT_PROF_THRESHOLD | "0.005" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit-prof-threshold) |
| `opcache.lockfile_path` | PHP_OPCACHE_LOCKFILE_PATH | "/app/tmp" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.lockfile_path) |
| `opcache.log_verbosity_level` | PHP_OPCACHE_LOG_VERBOSITY_LEVEL | "1" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.log-verbosity-level) |
| `opcache.max_accelerated_files` | PHP_OPCACHE_MAX_ACCELERATED_FILES | "4000" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.max-accelerated-files) |
| `opcache.max_file_size` | PHP_OPCACHE_MAX_FILE_SIZE | "0" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.max-file-size) |
| `opcache.max_wasted_percentage` | PHP_OPCACHE_MAX_WASTED_PERCENTAGE | "5" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.max-wasted-percentage) |
| `opcache.memory_consumption` | PHP_OPCACHE_MEMORY_CONSUMPTION | "128" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.memory-consumption) |
| `opcache.opt_debug_level` | PHP_OPCACHE_OPT_DEBUG_LEVEL | "0" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.opt_debug_level) |
| `opcache.optimization_level` | PHP_OPCACHE_OPTIMIZATION_LEVEL | "0x7FFEBFFF" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.optimization-level) |
| `opcache.preferred_memory_model` | PHP_OPCACHE_PREFERRED_MEMORY_MODEL | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.preferred-memory-model) |
| `opcache.preload` | PHP_OPCACHE_PRELOAD | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.preload) |
| `opcache.preload_user` | PHP_OPCACHE_PRELOAD_USER | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.preload-user) |
| `opcache.protect_memory` | PHP_OPCACHE_PROTECT_MEMORY | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.protect-memory) |
| `opcache.record_warnings` | PHP_OPCACHE_RECORD_WARNINGS | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.record-warnings) |
| `opcache.restrict_api` | PHP_OPCACHE_RESTRICT_API | Empty | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.restrict-api) |
| `opcache.revalidate_freq` | PHP_OPCACHE_REVALIDATE_FREQ | "2" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.revalidate-freq) |
| `opcache.revalidate_path` | PHP_OPCACHE_REVALIDATE_PATH | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.revalidate-path) |
| `opcache.save_comments` | PHP_OPCACHE_SAVE_COMMENTS | "On" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.save-comments) |
| `opcache.use_cwd` | PHP_OPCACHE_USE_CWD | "On" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.use-cwd) |
| `opcache.validate_permission` | PHP_OPCACHE_VALIDATE_PERMISSION | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.validate-permission) |
| `opcache.validate_root` | PHP_OPCACHE_VALIDATE_ROOT | "Off" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.validate-root) |
| `opcache.validate_timestamps` | PHP_OPCACHE_VALIDATE_TIMESTAMPS | "On" | [Link](https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.validate-timestamps) |

## Date and Time Related Extensions

### Date/Time

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `date.timezone` | PHP_DATE_TIMEZONE | "Europe/Brussels" | [Link](https://www.php.net/manual/en/datetime.configuration.php#ini.date.timezone) |

## Image Processing and Generation

### Exif

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `exif.decode_jis_intel` | PHP_EXIF_DECODE_JIS_INTEL | "JIS" | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.decode-jis-intel) |
| `exif.decode_jis_motorola` | PHP_EXIF_DECODE_JIS_MOTOROLA | "JIS" | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.decode-jis-motorola) |
| `exif.decode_unicode_intel` | PHP_EXIF_DECODE_UNICODE_INTEL | "UCS-2LE" | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.decode-unicode-intel) |
| `exif.decode_unicode_motorola` | PHP_EXIF_DECODE_UNICODE_MOTOROLA | "UCS-2BE" | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.decode-unicode-motorola) |
| `exif.encode_jis` | PHP_EXIF_ENCODE_JIS | Empty | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.encode-jis) |
| `exif.encode_unicode` | PHP_EXIF_ENCODE_UNICODE | "ISO-8859-15" | [Link](https://www.php.net/manual/en/exif.configuration.php#ini.exif.encode-unicode) |

### GD

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `gd.jpeg_ignore_warning` | PHP_GD_JPEG_IGNORE_WARNING | "On" | [Link](https://www.php.net/manual/en/image.configuration.php#ini.gd.jpeg-ignore-warning) |

## Human Language and Character Encoding Support

### Intl

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `intl.default_locale` | PHP_INTL_DEFAULT_LOCALE | Empty | [Link](https://www.php.net/manual/en/intl.configuration.php#ini.intl.default-locale) |
| `intl.error_level` | PHP_INTL_ERROR_LEVEL | "0" | [Link](https://www.php.net/manual/en/intl.configuration.php#ini.intl.error-level) |
| `intl.use_exceptions` | PHP_INTL_USE_EXCEPTIONS | "Off" | [Link](https://www.php.net/manual/en/intl.configuration.php#ini.intl.use-exceptions) |

## Other Services

### LDAP

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `ldap.max_links` | PHP_LDAP_MAX_LINKS | "-1" | [Link](https://www.php.net/manual/en/ldap.configuration.php#ini.ldap.max_links) |

## Web Services

### SOAP

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `soap.wsdl_cache` | PHP_SOAP_WSDL_CACHE | "1" | [Link](https://www.php.net/manual/en/soap.configuration.php#ini.soap.wsdl-cache) |
| `soap.wsdl_cache_dir` | PHP_SOAP_WSDL_CACHE_DIR | "/app/tmp" | [Link](https://www.php.net/manual/en/soap.configuration.php#ini.soap.wsdl-cache-dir) |
| `soap.wsdl_cache_enabled` | PHP_SOAP_WSDL_CACHE_ENABLED | "On" | [Link](https://www.php.net/manual/en/soap.configuration.php#ini.soap.wsdl-cache-enabled) |
| `soap.wsdl_cache_limit` | PHP_SOAP_WSDL_CACHE_LIMIT | "5" | [Link](https://www.php.net/manual/en/soap.configuration.php#ini.soap.wsdl-cache-limit) |
| `soap.wsdl_cache_ttl` | PHP_SOAP_WSDL_CACHE_TTL | "86400" | [Link](https://www.php.net/manual/en/soap.configuration.php#ini.soap.wsdl-cache-ttl) |

## Database Extensions

### MySQLi

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `mysqli.allow_local_infile` | PHP_MYSQLI_ALLOW_LOCAL_INFILE | "Off" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.allow-local-infile) |
| `mysqli.allow_persistent` | PHP_MYSQLI_ALLOW_PERSISTENT | "On" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.allow-persistent) |
| `mysqli.default_host` | PHP_MYSQLI_DEFAULT_HOST | Empty | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.default-host) |
| `mysqli.default_port` | PHP_MYSQLI_DEFAULT_PORT | "3306" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.default-port) |
| `mysqli.default_pw` | PHP_MYSQLI_DEFAULT_PW | Empty | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.default-pw) |
| `mysqli.default_socket` | PHP_MYSQLI_DEFAULT_SOCKET | Empty | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.default-socket) |
| `mysqli.default_user` | PHP_MYSQLI_DEFAULT_USER | Empty | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.default-user) |
| `mysqli.local_infile_directory` | PHP_MYSQLI_LOCAL_INFILE_DIRECTORY | Empty | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.local-infile-directory) |
| `mysqli.max_links` | PHP_MYSQLI_MAX_LINKS | "-1" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.max-links) |
| `mysqli.max_persistent` | PHP_MYSQLI_MAX_PERSISTENT | "-1" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.max-persistent) |
| `mysqli.rollback_on_cached_plink` | PHP_MYSQLI_ROLLBACK_ON_CACHED_PLINK | "Off" | [Link](https://www.php.net/manual/en/mysqli.configuration.php#ini.mysqli.rollback-on-cached-plink) |

### MySQL PDO Driver

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `pdo_mysql.default_socket` | PHP_PDO_MYSQL_DEFAULT_SOCKET | Empty | [Link](https://www.php.net/manual/en/ref.pdo-mysql.php#ini.pdo-mysql.default-socket) |

### PostgreSQL

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `pgsql.allow_persistent` | PHP_PGSQL_ALLOW_PERSISTENT | "On" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.allow-persistent) |
| `pgsql.auto_reset_persistent` | PHP_PGSQL_AUTO_RESET_PERSISTENT | "Off" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.auto-reset-persistent) |
| `pgsql.ignore_notice` | PHP_PGSQL_IGNORE_NOTICE | "Off" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.ignore-notice) |
| `pgsql.log_notice` | PHP_PGSQL_LOG_NOTICE | "Off" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.log-notice) |
| `pgsql.max_links` | PHP_PGSQL_MAX_LINKS | "-1" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.max-links) |
| `pgsql.max_persistent` | PHP_PGSQL_MAX_PERSISTENT | "-1" | [Link](https://www.php.net/manual/en/pgsql.configuration.php#ini.pgsql.max-persistent) |

### Redis

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `redis.arrays.algorithm` | PHP_REDIS_ARRAYS_ALGORITHM | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.auth` | PHP_REDIS_ARRAYS_AUTH | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.autorehash` | PHP_REDIS_ARRAYS_AUTOREHASH | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.connecttimeout` | PHP_REDIS_ARRAYS_CONNECTTIMEOUT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.consistent` | PHP_REDIS_ARRAYS_CONSISTENT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.distributor` | PHP_REDIS_ARRAYS_DISTRIBUTOR | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.functions` | PHP_REDIS_ARRAYS_FUNCTIONS | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.hosts` | PHP_REDIS_ARRAYS_HOSTS | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.index` | PHP_REDIS_ARRAYS_INDEX | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.lazyconnect` | PHP_REDIS_ARRAYS_LAZYCONNECT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.names` | PHP_REDIS_ARRAYS_NAMES | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.pconnect` | PHP_REDIS_ARRAYS_PCONNECT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.previous` | PHP_REDIS_ARRAYS_PREVIOUS | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.readtimeout` | PHP_REDIS_ARRAYS_READTIMEOUT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.arrays.retryinterval` | PHP_REDIS_ARRAYS_RETRYINTERVAL | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.auth` | PHP_REDIS_CLUSTERS_AUTH | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.cache_slots` | PHP_REDIS_CLUSTERS_CACHE_SLOTS | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.persistent` | PHP_REDIS_CLUSTERS_PERSISTENT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.read_timeout` | PHP_REDIS_CLUSTERS_READ_TIMEOUT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.seeds` | PHP_REDIS_CLUSTERS_SEEDS | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.clusters.timeout` | PHP_REDIS_CLUSTERS_TIMEOUT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.connection_limit` | PHP_REDIS_PCONNECT_CONNECTION_LIMIT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.echo_check_liveness` | PHP_REDIS_PCONNECT_ECHO_CHECK_LIVENESS | "1" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.pool_detect_dirty` | PHP_REDIS_PCONNECT_POOL_DETECT_DIRTY | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.pool_pattern` | PHP_REDIS_PCONNECT_POOL_PATTERN | Empty | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.pool_poll_timeout` | PHP_REDIS_PCONNECT_POOL_POLL_TIMEOUT | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.pconnect.pooling_enabled` | PHP_REDIS_PCONNECT_POOLING_ENABLED | "1" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.compression` | PHP_REDIS_SESSION_COMPRESSION | "none" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.compression_level` | PHP_REDIS_SESSION_COMPRESSION_LEVEL | "3" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.early_refresh` | PHP_REDIS_SESSION_EARLY_REFRESH | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.lock_expire` | PHP_REDIS_SESSION_LOCK_EXPIRE | "0" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.lock_retries` | PHP_REDIS_SESSION_LOCK_RETRIES | "100" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.lock_wait_time` | PHP_REDIS_SESSION_LOCK_WAIT_TIME | "20000" | [Link](https://github.com/phpredis/phpredis/) |
| `redis.session.locking_enabled` | PHP_REDIS_SESSION_LOCKING_ENABLED | "0" | [Link](https://github.com/phpredis/phpredis/) |

## Other Basic Extensions

### Tidy

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `tidy.clean_output` | PHP_TIDY_CLEAN_OUTPUT | "Off" | [Link](https://www.php.net/manual/en/tidy.configuration.php#ini.tidy.clean-output) |
| `tidy.default_config` | PHP_TIDY_DEFAULT_CONFIG | Empty | [Link](https://www.php.net/manual/en/tidy.configuration.php#ini.tidy.default-config) |

### OpenTelemetry

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `opentelemetry.allow_stack_extension` | PHP_OPENTELEMETRY_ALLOW_STACK_EXTENSION | "Off" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.attr_hooks_enabled` | PHP_OPENTELEMETRY_ATTR_HOOKS_ENABLED | "Off" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.attr_post_handler_function` | PHP_OPENTELEMETRY_ATTR_POST_HANDLER_FUNCTION | "OpenTelemetry\API\Instrumentation\WithSpanHandler::post" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.attr_pre_handler_function` | PHP_OPENTELEMETRY_ATTR_PRE_HANDLER_FUNCTION | "OpenTelemetry\API\Instrumentation\WithSpanHandler::pre" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.conflicts` | PHP_OPENTELEMETRY_CONFLICTS | Empty | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.display_warnings` | PHP_OPENTELEMETRY_DISPLAY_WARNINGS | "Off" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `opentelemetry.validate_hook_functions` | PHP_OPENTELEMETRY_VALIDATE_HOOK_FUNCTIONS | "On" | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |

### Xdebug

| Directive | Environment Variable | Default Value | Documentation |
| --------- | -------------------- | ------------- | ------------- |
| `xdebug.cli_color` | PHP_XDEBUG_CLI_COLOR | "0" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.client_discovery_header` | PHP_XDEBUG_CLIENT_DISCOVERY_HEADER | "HTTP_X_FORWARDED_FOR,REMOTE_ADDR" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.client_host` | PHP_XDEBUG_CLIENT_HOST | "host.docker.internal" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.client_port` | PHP_XDEBUG_CLIENT_PORT | "9003" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.cloud_id` | PHP_XDEBUG_CLOUD_ID | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.collect_assignments` | PHP_XDEBUG_COLLECT_ASSIGNMENTS | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.collect_params` | PHP_XDEBUG_COLLECT_PARAMS | "On" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.collect_return` | PHP_XDEBUG_COLLECT_RETURN | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.connect_timeout_ms` | PHP_XDEBUG_CONNECT_TIMEOUT_MS | "200" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.control_socket` | PHP_XDEBUG_CONTROL_SOCKET | "time: 25ms" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.discover_client_host` | PHP_XDEBUG_DISCOVER_CLIENT_HOST | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.COOKIE` | PHP_XDEBUG_DUMP_COOKIE | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.ENV` | PHP_XDEBUG_DUMP_ENV | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.FILES` | PHP_XDEBUG_DUMP_FILES | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.GET` | PHP_XDEBUG_DUMP_GET | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.POST` | PHP_XDEBUG_DUMP_POST | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.REQUEST` | PHP_XDEBUG_DUMP_REQUEST | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.SERVER` | PHP_XDEBUG_DUMP_SERVER | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump.SESSION` | PHP_XDEBUG_DUMP_SESSION | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump_globals` | PHP_XDEBUG_DUMP_GLOBALS | "On" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump_once` | PHP_XDEBUG_DUMP_ONCE | "On" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.dump_undefined` | PHP_XDEBUG_DUMP_UNDEFINED | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.file_link_format` | PHP_XDEBUG_FILE_LINK_FORMAT | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.filename_format` | PHP_XDEBUG_FILENAME_FORMAT | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.force_display_errors` | PHP_XDEBUG_FORCE_DISPLAY_ERRORS | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.force_error_reporting` | PHP_XDEBUG_FORCE_ERROR_REPORTING | "0" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.gc_stats_output_name` | PHP_XDEBUG_GC_STATS_OUTPUT_NAME | "gcstats.%p" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.halt_level` | PHP_XDEBUG_HALT_LEVEL | "0" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.idekey` | PHP_XDEBUG_IDEKEY | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.log` | PHP_XDEBUG_LOG | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.log_level` | PHP_XDEBUG_LOG_LEVEL | "7" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.max_nesting_level` | PHP_XDEBUG_MAX_NESTING_LEVEL | "512" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.max_stack_frames` | PHP_XDEBUG_MAX_STACK_FRAMES | "-1" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.mode` | PHP_XDEBUG_MODE | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.output_dir` | PHP_XDEBUG_OUTPUT_DIR | "/app/tmp" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.profiler_append` | PHP_XDEBUG_PROFILER_APPEND | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.profiler_output_name` | PHP_XDEBUG_PROFILER_OUTPUT_NAME | "cachegrind.out.%p" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.scream` | PHP_XDEBUG_SCREAM | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.show_error_trace` | PHP_XDEBUG_SHOW_ERROR_TRACE | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.show_exception_trace` | PHP_XDEBUG_SHOW_EXCEPTION_TRACE | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.show_local_vars` | PHP_XDEBUG_SHOW_LOCAL_VARS | "Off" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.start_upon_error` | PHP_XDEBUG_START_UPON_ERROR | "default" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.start_with_request` | PHP_XDEBUG_START_WITH_REQUEST | "yes" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.trace_format` | PHP_XDEBUG_TRACE_FORMAT | "0" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.trace_options` | PHP_XDEBUG_TRACE_OPTIONS | "0" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.trace_output_name` | PHP_XDEBUG_TRACE_OUTPUT_NAME | "trace.%c" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.trigger_value` | PHP_XDEBUG_TRIGGER_VALUE | Empty | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.use_compression` | PHP_XDEBUG_USE_COMPRESSION | "1" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.var_display_max_children` | PHP_XDEBUG_VAR_DISPLAY_MAX_CHILDREN | "128" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.var_display_max_data` | PHP_XDEBUG_VAR_DISPLAY_MAX_DATA | "512" | [Link](https://xdebug.org/docs/all_settings) |
| `xdebug.var_display_max_depth` | PHP_XDEBUG_VAR_DISPLAY_MAX_DEPTH | "3" | [Link](https://xdebug.org/docs/all_settings) |
