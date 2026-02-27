#!/usr/bin/env bash

if [[ "${PHP_BYPASS_INI_DEFAULT_VALUES}" == "true" ]]; then
	return 0
fi

# Core Language Options

PHP_SHORT_OPEN_TAG_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("short_open_tag");')"
PHP_PRECISION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("precision");')"
PHP_SERIALIZE_PRECISION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("serialize_precision");')"
PHP_DISABLE_FUNCTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("disable_functions");')"
PHP_DISABLE_CLASSES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("disable_classes");')"
PHP_EXIT_ON_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exit_on_timeout");')"
PHP_EXPOSE_PHP_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("expose_php");')"
PHP_HARD_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("hard_timeout");')"
PHP_ZEND_EXCEPTION_IGNORE_ARGS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.exception_ignore_args");')"
PHP_ZEND_MULTIBYTE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.multibyte");')"
PHP_ZEND_SCRIPT_ENCODING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.script_encoding");')"
PHP_ZEND_DETECT_UNICODE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.detect_unicode");')"
PHP_ZEND_SIGNAL_CHECK_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.signal_check");')"
PHP_ZEND_ASSERTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.assertions");')"
PHP_ZEND_EXCEPTION_STRING_PARAM_MAX_LEN_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("zend.exception_string_param_max_len");')"

# Core Resource Limits

PHP_MEMORY_LIMIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("memory_limit");')"

# Core Performance Tuning

PHP_REALPATH_CACHE_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("realpath_cache_size");')"
PHP_REALPATH_CACHE_TTL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("realpath_cache_ttl");')"

# Core Data Handling

PHP_ARG_SEPARATOR_OUTPUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("arg_separator.output");')"
PHP_ARG_SEPARATOR_INPUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("arg_separator.input");')"
PHP_VARIABLES_ORDER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("variables_order");')"
PHP_REQUEST_ORDER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("request_order");')"
PHP_AUTO_GLOBALS_JIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("auto_globals_jit");')"
PHP_REGISTER_ARGC_ARGV_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("register_argc_argv");')"
PHP_ENABLE_POST_DATA_READING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("enable_post_data_reading");')"
PHP_POST_MAX_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("post_max_size");')"
PHP_AUTO_PREPEND_FILE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("auto_prepend_file");')"
PHP_AUTO_APPEND_FILE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("auto_append_file");')"
PHP_DEFAULT_MIMETYPE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("default_mimetype");')"
PHP_DEFAULT_CHARSET_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("default_charset");')"
PHP_INPUT_ENCODING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("input_encoding");')"
PHP_OUTPUT_ENCODING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("output_encoding");')"
PHP_INTERNAL_ENCODING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("internal_encoding");')"

# Core Paths and Directories

PHP_INCLUDE_PATH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("include_path");')"
PHP_OPEN_BASEDIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("open_basedir");')"
PHP_DOC_ROOT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("doc_root");')"
PHP_USER_DIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("user_dir");')"
PHP_USER_INI_CACHE_TTL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("user_ini.cache_ttl");')"
PHP_USER_INI_FILENAME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("user_ini.filename");')"
PHP_EXTENSION_DIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("extension_dir");')"
PHP_CGI_CHECK_SHEBANG_LINE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.check_shebang_line");')"
PHP_CGI_DISCARD_PATH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.discard_path");')"
PHP_CGI_FIX_PATHINFO_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.fix_pathinfo");')"
PHP_CGI_FORCE_REDIRECT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.force_redirect");')"
PHP_CGI_NPH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.nph");')"
PHP_CGI_REDIRECT_STATUS_ENV_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.redirect_status_env");')"
PHP_CGI_RFC2616_HEADERS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("cgi.rfc2616_headers");')"
PHP_FASTCGI_IMPERSONATE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("fastcgi.impersonate");')"

# Core File Uploads

PHP_FILE_UPLOADS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("file_uploads");')"
PHP_MAX_FILE_UPLOADS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("max_file_uploads");')"
PHP_UPLOAD_MAX_FILESIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("upload_max_filesize");')"
PHP_UPLOAD_TMP_DIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("upload_tmp_dir");')"

# Core Options/Info

PHP_MAX_INPUT_NESTING_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("max_input_nesting_level");')"
PHP_MAX_INPUT_VARS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("max_input_vars");')"
PHP_MAX_EXECUTION_TIME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("max_execution_time");')"
PHP_MAX_INPUT_TIME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("max_input_time");')"

# Core Error Handling and Logging

PHP_LOG_ERRORS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("log_errors");')"
PHP_ERROR_REPORTING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("error_reporting");')"
PHP_IGNORE_REPEATED_ERRORS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("ignore_repeated_errors");')"
PHP_IGNORE_REPEATED_SOURCE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("ignore_repeated_source");')"
PHP_REPORT_MEMLEAKS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("report_memleaks");')"
PHP_DISPLAY_ERRORS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("display_errors");')"

# APCu

PHP_APC_ENABLED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.enabled");')"
PHP_APC_COREDUMP_UNMAP_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.coredump_unmap");')"
PHP_APC_ENABLE_CLI_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.enable_cli");')"
PHP_APC_ENTRIES_HINT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.entries_hint");')"
PHP_APC_GC_TTL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.gc_ttl");')"
PHP_APC_MMAP_FILE_MASK_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.mmap_file_mask");')"
PHP_APC_MMAP_HUGEPAGE_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.mmap_hugepage_size");')"
PHP_APC_PRELOAD_PATH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.preload_path");')"
PHP_APC_SERIALIZER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.serializer");')"
PHP_APC_SHM_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.shm_size");')"
PHP_APC_SLAM_DEFENSE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.slam_defense");')"
PHP_APC_SMART_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.smart");')"
PHP_APC_TTL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.ttl");')"
PHP_APC_USE_REQUEST_TIME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("apc.use_request_time");')"

# Opcache

PHP_OPCACHE_ENABLE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.enable");')"
PHP_OPCACHE_ENABLE_CLI_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.enable_cli");')"
PHP_OPCACHE_BLACKLIST_FILENAME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.blacklist_filename");')"
PHP_OPCACHE_DUPS_FIX_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.dups_fix");')"
PHP_OPCACHE_ENABLE_FILE_OVERRIDE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.enable_file_override");')"
PHP_OPCACHE_ERROR_LOG_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.error_log");')"
PHP_OPCACHE_FILE_CACHE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.file_cache");')"
PHP_OPCACHE_FILE_CACHE_CONSISTENCY_CHECKS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.file_cache_consistency_checks");')"
PHP_OPCACHE_FILE_CACHE_ONLY_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.file_cache_only");')"
PHP_OPCACHE_FILE_UPDATE_PROTECTION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.file_update_protection");')"
PHP_OPCACHE_FORCE_RESTART_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.force_restart_timeout");')"
PHP_OPCACHE_HUGE_CODE_PAGES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.huge_code_pages");')"
PHP_OPCACHE_INTERNED_STRINGS_BUFFER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.interned_strings_buffer");')"
PHP_OPCACHE_JIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit");')"
PHP_OPCACHE_JIT_BISECT_LIMIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_bisect_limit");')"
PHP_OPCACHE_JIT_BLACKLIST_ROOT_TRACE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_blacklist_root_trace");')"
PHP_OPCACHE_JIT_BLACKLIST_SIDE_TRACE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_blacklist_side_trace");')"
PHP_OPCACHE_JIT_BUFFER_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_buffer_size");')"
PHP_OPCACHE_JIT_DEBUG_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_debug");')"
PHP_OPCACHE_JIT_HOT_FUNC_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_hot_func");')"
PHP_OPCACHE_JIT_HOT_LOOP_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_hot_loop");')"
PHP_OPCACHE_JIT_HOT_RETURN_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_hot_return");')"
PHP_OPCACHE_JIT_HOT_SIDE_EXIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_hot_side_exit");')"
PHP_OPCACHE_JIT_MAX_EXIT_COUNTERS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_exit_counters");')"
PHP_OPCACHE_JIT_MAX_LOOP_UNROLLS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_loop_unrolls");')"
PHP_OPCACHE_JIT_MAX_POLYMORPHIC_CALLS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_polymorphic_calls");')"
PHP_OPCACHE_JIT_MAX_RECURSIVE_CALLS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_recursive_calls");')"
PHP_OPCACHE_JIT_MAX_RECURSIVE_RETURNS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_recursive_returns");')"
PHP_OPCACHE_JIT_MAX_ROOT_TRACES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_root_traces");')"
PHP_OPCACHE_JIT_MAX_SIDE_TRACES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_side_traces");')"
PHP_OPCACHE_JIT_MAX_TRACE_LENGTH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_max_trace_length");')"
PHP_OPCACHE_JIT_PROF_THRESHOLD_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.jit_prof_threshold");')"
PHP_OPCACHE_LOCKFILE_PATH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.lockfile_path");')"
PHP_OPCACHE_LOG_VERBOSITY_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.log_verbosity_level");')"
PHP_OPCACHE_MAX_ACCELERATED_FILES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.max_accelerated_files");')"
PHP_OPCACHE_MAX_FILE_SIZE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.max_file_size");')"
PHP_OPCACHE_MAX_WASTED_PERCENTAGE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.max_wasted_percentage");')"
PHP_OPCACHE_MEMORY_CONSUMPTION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.memory_consumption");')"
PHP_OPCACHE_OPT_DEBUG_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.opt_debug_level");')"
PHP_OPCACHE_OPTIMIZATION_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.optimization_level");')"
PHP_OPCACHE_PREFERRED_MEMORY_MODEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.preferred_memory_model");')"
PHP_OPCACHE_PRELOAD_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.preload");')"
PHP_OPCACHE_PRELOAD_USER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.preload_user");')"
PHP_OPCACHE_PROTECT_MEMORY_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.protect_memory");')"
PHP_OPCACHE_RECORD_WARNINGS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.record_warnings");')"
PHP_OPCACHE_RESTRICT_API_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.restrict_api");')"
PHP_OPCACHE_REVALIDATE_FREQ_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.revalidate_freq");')"
PHP_OPCACHE_REVALIDATE_PATH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.revalidate_path");')"
PHP_OPCACHE_SAVE_COMMENTS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.save_comments");')"
PHP_OPCACHE_USE_CWD_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.use_cwd");')"
PHP_OPCACHE_VALIDATE_PERMISSION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.validate_permission");')"
PHP_OPCACHE_VALIDATE_ROOT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.validate_root");')"
PHP_OPCACHE_VALIDATE_TIMESTAMPS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opcache.validate_timestamps");')"

# Date/Time

PHP_DATE_TIMEZONE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("date.timezone");')"

# BC Math

PHP_BCMATH_SCALE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("bcmath.scale");')"

# Exif

PHP_EXIF_DECODE_JIS_INTEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.decode_jis_intel");')"
PHP_EXIF_DECODE_JIS_MOTOROLA_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.decode_jis_motorola");')"
PHP_EXIF_DECODE_UNICODE_INTEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.decode_unicode_intel");')"
PHP_EXIF_DECODE_UNICODE_MOTOROLA_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.decode_unicode_motorola");')"
PHP_EXIF_ENCODE_JIS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.encode_jis");')"
PHP_EXIF_ENCODE_UNICODE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("exif.encode_unicode");')"

# GD

PHP_GD_JPEG_IGNORE_WARNING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("gd.jpeg_ignore_warning");')"

# Intl

PHP_INTL_DEFAULT_LOCALE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("intl.default_locale");')"
PHP_INTL_ERROR_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("intl.error_level");')"
PHP_INTL_USE_EXCEPTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("intl.use_exceptions");')"

# LDAP

PHP_LDAP_MAX_LINKS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("intl.use_exceptions");')"

# SOAP

PHP_SOAP_WSDL_CACHE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("soap.wsdl_cache");')"
PHP_SOAP_WSDL_CACHE_DIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("soap.wsdl_cache_dir");')"
PHP_SOAP_WSDL_CACHE_ENABLED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("soap.wsdl_cache_enabled");')"
PHP_SOAP_WSDL_CACHE_LIMIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("soap.wsdl_cache_limit");')"
PHP_SOAP_WSDL_CACHE_TTL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("soap.wsdl_cache_ttl");')"

# MySQLi

PHP_MYSQLI_ALLOW_LOCAL_INFILE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.allow_local_infile");')"
PHP_MYSQLI_ALLOW_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.allow_persistent");')"
PHP_MYSQLI_DEFAULT_HOST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.default_host");')"
PHP_MYSQLI_DEFAULT_PORT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.default_port");')"
PHP_MYSQLI_DEFAULT_PW_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.default_pw");')"
PHP_MYSQLI_DEFAULT_SOCKET_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.default_socket");')"
PHP_MYSQLI_DEFAULT_USER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.default_user");')"
PHP_MYSQLI_LOCAL_INFILE_DIRECTORY_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.local_infile_directory");')"
PHP_MYSQLI_MAX_LINKS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.max_links");')"
PHP_MYSQLI_MAX_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.max_persistent");')"
PHP_MYSQLI_ROLLBACK_ON_CACHED_PLINK_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("mysqli.rollback_on_cached_plink");')"

# MySQL PDO Driver

PHP_PDO_MYSQL_DEFAULT_SOCKET_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pdo_mysql.default_socket");')"

# PostgreSQL

PHP_PGSQL_ALLOW_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.allow_persistent");')"
PHP_PGSQL_AUTO_RESET_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.auto_reset_persistent");')"
PHP_PGSQL_IGNORE_NOTICE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.ignore_notice");')"
PHP_PGSQL_LOG_NOTICE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.log_notice");')"
PHP_PGSQL_MAX_LINKS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.max_links");')"
PHP_PGSQL_MAX_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("pgsql.max_persistent");')"

# Redis

PHP_REDIS_ARRAYS_ALGORITHM_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.algorithm");')"
PHP_REDIS_ARRAYS_AUTH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.auth");')"
PHP_REDIS_ARRAYS_AUTOREHASH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.autorehash");')"
PHP_REDIS_ARRAYS_CONNECTTIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.connecttimeout");')"
PHP_REDIS_ARRAYS_CONSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.consistent");')"
PHP_REDIS_ARRAYS_DISTRIBUTOR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.distributor");')"
PHP_REDIS_ARRAYS_FUNCTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.functions");')"
PHP_REDIS_ARRAYS_HOSTS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.hosts");')"
PHP_REDIS_ARRAYS_INDEX_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.index");')"
PHP_REDIS_ARRAYS_LAZYCONNECT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.lazyconnect");')"
PHP_REDIS_ARRAYS_NAMES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.names");')"
PHP_REDIS_ARRAYS_PCONNECT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.pconnect");')"
PHP_REDIS_ARRAYS_PREVIOUS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.previous");')"
PHP_REDIS_ARRAYS_READTIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.readtimeout");')"
PHP_REDIS_ARRAYS_RETRYINTERVAL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.arrays.retryinterval");')"
PHP_REDIS_CLUSTERS_AUTH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.auth");')"
PHP_REDIS_CLUSTERS_CACHE_SLOTS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.cache_slots");')"
PHP_REDIS_CLUSTERS_PERSISTENT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.persistent");')"
PHP_REDIS_CLUSTERS_READ_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.read_timeout");')"
PHP_REDIS_CLUSTERS_SEEDS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.seeds");')"
PHP_REDIS_CLUSTERS_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.clusters.timeout");')"
PHP_REDIS_PCONNECT_CONNECTION_LIMIT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.connection_limit");')"
PHP_REDIS_PCONNECT_ECHO_CHECK_LIVENESS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.echo_check_liveness");')"
PHP_REDIS_PCONNECT_POOL_DETECT_DIRTY_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.pool_detect_dirty");')"
PHP_REDIS_PCONNECT_POOL_PATTERN_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.pool_pattern");')"
PHP_REDIS_PCONNECT_POOL_POLL_TIMEOUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.pool_poll_timeout");')"
PHP_REDIS_PCONNECT_POOLING_ENABLED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.pconnect.pooling_enabled");')"
PHP_REDIS_SESSION_COMPRESSION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.compression");')"
PHP_REDIS_SESSION_COMPRESSION_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.compression_level");')"
PHP_REDIS_SESSION_EARLY_REFRESH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.early_refresh");')"
PHP_REDIS_SESSION_LOCK_EXPIRE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.lock_expire");')"
PHP_REDIS_SESSION_LOCK_RETRIES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.lock_retries");')"
PHP_REDIS_SESSION_LOCK_WAIT_TIME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.lock_wait_time");')"
PHP_REDIS_SESSION_LOCKING_ENABLED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("redis.session.locking_enabled");')"

# Tidy

PHP_TIDY_CLEAN_OUTPUT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("tidy.clean_output");')"
PHP_TIDY_DEFAULT_CONFIG_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("tidy.default_config");')"

# OpenTelemetry

PHP_OPENTELEMETRY_ALLOW_STACK_EXTENSION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.allow_stack_extension");')"
PHP_OPENTELEMETRY_ATTR_HOOKS_ENABLED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.attr_hooks_enabled");')"
PHP_OPENTELEMETRY_ATTR_POST_HANDLER_FUNCTION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.attr_post_handler_function");')"
PHP_OPENTELEMETRY_ATTR_PRE_HANDLER_FUNCTION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.attr_pre_handler_function");')"
PHP_OPENTELEMETRY_CONFLICTS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.conflicts");')"
PHP_OPENTELEMETRY_DISPLAY_WARNINGS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.display_warnings");')"
PHP_OPENTELEMETRY_VALIDATE_HOOK_FUNCTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("opentelemetry.validate_hook_functions");')"

# XDebug Runtime Configuration

PHP_XDEBUG_CLI_COLOR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.cli_color");')"
PHP_XDEBUG_CLIENT_DISCOVERY_HEADER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.client_discovery_header");')"
PHP_XDEBUG_CLIENT_HOST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.client_host");')"
PHP_XDEBUG_CLIENT_PORT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.client_port");')"
PHP_XDEBUG_CLOUD_ID_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.cloud_id");')"
PHP_XDEBUG_COLLECT_ASSIGNMENTS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.collect_assignments");')"
PHP_XDEBUG_COLLECT_PARAMS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.collect_params");')"
PHP_XDEBUG_COLLECT_RETURN_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.collect_return");')"
PHP_XDEBUG_CONNECT_TIMEOUT_MS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.connect_timeout_ms");')"
PHP_XDEBUG_CONTROL_SOCKET_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.control_socket");')"
PHP_XDEBUG_DISCOVER_CLIENT_HOST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.discover_client_host");')"
PHP_XDEBUG_DUMP_COOKIE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.COOKIE");')"
PHP_XDEBUG_DUMP_ENV_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.ENV");')"
PHP_XDEBUG_DUMP_FILES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.FILES");')"
PHP_XDEBUG_DUMP_GET_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.GET");')"
PHP_XDEBUG_DUMP_POST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.POST");')"
PHP_XDEBUG_DUMP_REQUEST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.REQUEST");')"
PHP_XDEBUG_DUMP_SERVER_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.SERVER");')"
PHP_XDEBUG_DUMP_SESSION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump.SESSION");')"
PHP_XDEBUG_DUMP_GLOBALS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump_globals");')"
PHP_XDEBUG_DUMP_ONCE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump_once");')"
PHP_XDEBUG_DUMP_UNDEFINED_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.dump_undefined");')"
PHP_XDEBUG_FILE_LINK_FORMAT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.file_link_format");')"
PHP_XDEBUG_FILENAME_FORMAT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.filename_format");')"
PHP_XDEBUG_FORCE_DISPLAY_ERRORS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.force_display_errors");')"
PHP_XDEBUG_FORCE_ERROR_REPORTING_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.force_error_reporting");')"
PHP_XDEBUG_GC_STATS_OUTPUT_NAME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.gc_stats_output_name");')"
PHP_XDEBUG_HALT_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.halt_level");')"
PHP_XDEBUG_IDEKEY_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.idekey");')"
PHP_XDEBUG_LOG_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.log");')"
PHP_XDEBUG_LOG_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.log_level");')"
PHP_XDEBUG_MAX_NESTING_LEVEL_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.max_nesting_level");')"
PHP_XDEBUG_MAX_STACK_FRAMES_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.max_stack_frames");')"
PHP_XDEBUG_MODE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.mode");')"
PHP_XDEBUG_OUTPUT_DIR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.output_dir");')"
PHP_XDEBUG_PROFILER_APPEND_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.profiler_append");')"
PHP_XDEBUG_PROFILER_OUTPUT_NAME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.profiler_output_name");')"
PHP_XDEBUG_SCREAM_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.scream");')"
PHP_XDEBUG_SHOW_ERROR_TRACE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.show_error_trace");')"
PHP_XDEBUG_SHOW_EXCEPTION_TRACE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.show_exception_trace");')"
PHP_XDEBUG_SHOW_LOCAL_VARS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.show_local_vars");')"
PHP_XDEBUG_START_UPON_ERROR_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.start_upon_error");')"
PHP_XDEBUG_START_WITH_REQUEST_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.start_with_request");')"
PHP_XDEBUG_TRACE_FORMAT_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.trace_format");')"
PHP_XDEBUG_TRACE_OPTIONS_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.trace_options");')"
PHP_XDEBUG_TRACE_OUTPUT_NAME_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.trace_output_name");')"
PHP_XDEBUG_TRIGGER_VALUE_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.trigger_value");')"
PHP_XDEBUG_USE_COMPRESSION_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.use_compression");')"
PHP_XDEBUG_VAR_DISPLAY_MAX_CHILDREN_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.var_display_max_children");')"
PHP_XDEBUG_VAR_DISPLAY_MAX_DATA_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.var_display_max_data");')"
PHP_XDEBUG_VAR_DISPLAY_MAX_DEPTH_INI_DEFAULT_VALUE="$(php -r 'echo ini_get("xdebug.var_display_max_depth");')"

true
