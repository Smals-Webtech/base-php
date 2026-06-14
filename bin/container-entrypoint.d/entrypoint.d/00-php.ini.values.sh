#!/usr/bin/env bash

if [[ "${PHP_BYPASS_INI_DEFAULT_VALUES}" == "true" ]]; then
	return 0
fi

# Map of php.ini directive -> the *_INI_DEFAULT_VALUE variable that receives its
# current value. Every directive is read in a single PHP invocation below
# (instead of one `php -r` fork per directive) to keep container startup fast.

declare -A PHP_INI_DIRECTIVE_MAP=(
	# Core Language Options

	[short_open_tag]="PHP_SHORT_OPEN_TAG_INI_DEFAULT_VALUE"
	[precision]="PHP_PRECISION_INI_DEFAULT_VALUE"
	[serialize_precision]="PHP_SERIALIZE_PRECISION_INI_DEFAULT_VALUE"
	[disable_functions]="PHP_DISABLE_FUNCTIONS_INI_DEFAULT_VALUE"
	[exit_on_timeout]="PHP_EXIT_ON_TIMEOUT_INI_DEFAULT_VALUE"
	[expose_php]="PHP_EXPOSE_PHP_INI_DEFAULT_VALUE"
	[hard_timeout]="PHP_HARD_TIMEOUT_INI_DEFAULT_VALUE"
	[zend.exception_ignore_args]="PHP_ZEND_EXCEPTION_IGNORE_ARGS_INI_DEFAULT_VALUE"
	[zend.multibyte]="PHP_ZEND_MULTIBYTE_INI_DEFAULT_VALUE"
	[zend.script_encoding]="PHP_ZEND_SCRIPT_ENCODING_INI_DEFAULT_VALUE"
	[zend.detect_unicode]="PHP_ZEND_DETECT_UNICODE_INI_DEFAULT_VALUE"
	[zend.signal_check]="PHP_ZEND_SIGNAL_CHECK_INI_DEFAULT_VALUE"
	[zend.assertions]="PHP_ZEND_ASSERTIONS_INI_DEFAULT_VALUE"
	[zend.exception_string_param_max_len]="PHP_ZEND_EXCEPTION_STRING_PARAM_MAX_LEN_INI_DEFAULT_VALUE"

	# Core Resource Limits

	[memory_limit]="PHP_MEMORY_LIMIT_INI_DEFAULT_VALUE"
	[max_memory_limit]="PHP_MAX_MEMORY_LIMIT_INI_DEFAULT_VALUE"

	# Core Performance Tuning

	[realpath_cache_size]="PHP_REALPATH_CACHE_SIZE_INI_DEFAULT_VALUE"
	[realpath_cache_ttl]="PHP_REALPATH_CACHE_TTL_INI_DEFAULT_VALUE"

	# Core Data Handling

	[arg_separator.output]="PHP_ARG_SEPARATOR_OUTPUT_INI_DEFAULT_VALUE"
	[arg_separator.input]="PHP_ARG_SEPARATOR_INPUT_INI_DEFAULT_VALUE"
	[variables_order]="PHP_VARIABLES_ORDER_INI_DEFAULT_VALUE"
	[request_order]="PHP_REQUEST_ORDER_INI_DEFAULT_VALUE"
	[auto_globals_jit]="PHP_AUTO_GLOBALS_JIT_INI_DEFAULT_VALUE"
	[register_argc_argv]="PHP_REGISTER_ARGC_ARGV_INI_DEFAULT_VALUE"
	[enable_post_data_reading]="PHP_ENABLE_POST_DATA_READING_INI_DEFAULT_VALUE"
	[post_max_size]="PHP_POST_MAX_SIZE_INI_DEFAULT_VALUE"
	[auto_prepend_file]="PHP_AUTO_PREPEND_FILE_INI_DEFAULT_VALUE"
	[auto_append_file]="PHP_AUTO_APPEND_FILE_INI_DEFAULT_VALUE"
	[default_mimetype]="PHP_DEFAULT_MIMETYPE_INI_DEFAULT_VALUE"
	[default_charset]="PHP_DEFAULT_CHARSET_INI_DEFAULT_VALUE"
	[input_encoding]="PHP_INPUT_ENCODING_INI_DEFAULT_VALUE"
	[output_encoding]="PHP_OUTPUT_ENCODING_INI_DEFAULT_VALUE"
	[internal_encoding]="PHP_INTERNAL_ENCODING_INI_DEFAULT_VALUE"

	# Core Paths and Directories

	[include_path]="PHP_INCLUDE_PATH_INI_DEFAULT_VALUE"
	[open_basedir]="PHP_OPEN_BASEDIR_INI_DEFAULT_VALUE"
	[doc_root]="PHP_DOC_ROOT_INI_DEFAULT_VALUE"
	[user_dir]="PHP_USER_DIR_INI_DEFAULT_VALUE"
	[user_ini.cache_ttl]="PHP_USER_INI_CACHE_TTL_INI_DEFAULT_VALUE"
	[user_ini.filename]="PHP_USER_INI_FILENAME_INI_DEFAULT_VALUE"
	[extension_dir]="PHP_EXTENSION_DIR_INI_DEFAULT_VALUE"
	[cgi.check_shebang_line]="PHP_CGI_CHECK_SHEBANG_LINE_INI_DEFAULT_VALUE"
	[cgi.discard_path]="PHP_CGI_DISCARD_PATH_INI_DEFAULT_VALUE"
	[cgi.fix_pathinfo]="PHP_CGI_FIX_PATHINFO_INI_DEFAULT_VALUE"
	[cgi.force_redirect]="PHP_CGI_FORCE_REDIRECT_INI_DEFAULT_VALUE"
	[cgi.nph]="PHP_CGI_NPH_INI_DEFAULT_VALUE"
	[cgi.redirect_status_env]="PHP_CGI_REDIRECT_STATUS_ENV_INI_DEFAULT_VALUE"
	[cgi.rfc2616_headers]="PHP_CGI_RFC2616_HEADERS_INI_DEFAULT_VALUE"
	[fastcgi.impersonate]="PHP_FASTCGI_IMPERSONATE_INI_DEFAULT_VALUE"

	# Core File Uploads

	[file_uploads]="PHP_FILE_UPLOADS_INI_DEFAULT_VALUE"
	[max_file_uploads]="PHP_MAX_FILE_UPLOADS_INI_DEFAULT_VALUE"
	[upload_max_filesize]="PHP_UPLOAD_MAX_FILESIZE_INI_DEFAULT_VALUE"
	[upload_tmp_dir]="PHP_UPLOAD_TMP_DIR_INI_DEFAULT_VALUE"

	# Core Options/Info

	[max_input_nesting_level]="PHP_MAX_INPUT_NESTING_LEVEL_INI_DEFAULT_VALUE"
	[max_input_vars]="PHP_MAX_INPUT_VARS_INI_DEFAULT_VALUE"
	[max_execution_time]="PHP_MAX_EXECUTION_TIME_INI_DEFAULT_VALUE"
	[max_input_time]="PHP_MAX_INPUT_TIME_INI_DEFAULT_VALUE"

	# Core Error Handling and Logging

	[log_errors]="PHP_LOG_ERRORS_INI_DEFAULT_VALUE"
	[error_reporting]="PHP_ERROR_REPORTING_INI_DEFAULT_VALUE"
	[ignore_repeated_errors]="PHP_IGNORE_REPEATED_ERRORS_INI_DEFAULT_VALUE"
	[ignore_repeated_source]="PHP_IGNORE_REPEATED_SOURCE_INI_DEFAULT_VALUE"
	[report_memleaks]="PHP_REPORT_MEMLEAKS_INI_DEFAULT_VALUE"
	[display_errors]="PHP_DISPLAY_ERRORS_INI_DEFAULT_VALUE"

	# APCu

	[apc.enabled]="PHP_APC_ENABLED_INI_DEFAULT_VALUE"
	[apc.coredump_unmap]="PHP_APC_COREDUMP_UNMAP_INI_DEFAULT_VALUE"
	[apc.enable_cli]="PHP_APC_ENABLE_CLI_INI_DEFAULT_VALUE"
	[apc.entries_hint]="PHP_APC_ENTRIES_HINT_INI_DEFAULT_VALUE"
	[apc.gc_ttl]="PHP_APC_GC_TTL_INI_DEFAULT_VALUE"
	[apc.mmap_file_mask]="PHP_APC_MMAP_FILE_MASK_INI_DEFAULT_VALUE"
	[apc.mmap_hugepage_size]="PHP_APC_MMAP_HUGEPAGE_SIZE_INI_DEFAULT_VALUE"
	[apc.preload_path]="PHP_APC_PRELOAD_PATH_INI_DEFAULT_VALUE"
	[apc.serializer]="PHP_APC_SERIALIZER_INI_DEFAULT_VALUE"
	[apc.shm_size]="PHP_APC_SHM_SIZE_INI_DEFAULT_VALUE"
	[apc.slam_defense]="PHP_APC_SLAM_DEFENSE_INI_DEFAULT_VALUE"
	[apc.smart]="PHP_APC_SMART_INI_DEFAULT_VALUE"
	[apc.ttl]="PHP_APC_TTL_INI_DEFAULT_VALUE"
	[apc.use_request_time]="PHP_APC_USE_REQUEST_TIME_INI_DEFAULT_VALUE"

	# Opcache

	[opcache.enable]="PHP_OPCACHE_ENABLE_INI_DEFAULT_VALUE"
	[opcache.enable_cli]="PHP_OPCACHE_ENABLE_CLI_INI_DEFAULT_VALUE"
	[opcache.blacklist_filename]="PHP_OPCACHE_BLACKLIST_FILENAME_INI_DEFAULT_VALUE"
	[opcache.dups_fix]="PHP_OPCACHE_DUPS_FIX_INI_DEFAULT_VALUE"
	[opcache.enable_file_override]="PHP_OPCACHE_ENABLE_FILE_OVERRIDE_INI_DEFAULT_VALUE"
	[opcache.error_log]="PHP_OPCACHE_ERROR_LOG_INI_DEFAULT_VALUE"
	[opcache.file_cache]="PHP_OPCACHE_FILE_CACHE_INI_DEFAULT_VALUE"
	[opcache.file_cache_consistency_checks]="PHP_OPCACHE_FILE_CACHE_CONSISTENCY_CHECKS_INI_DEFAULT_VALUE"
	[opcache.file_cache_only]="PHP_OPCACHE_FILE_CACHE_ONLY_INI_DEFAULT_VALUE"
	[opcache.file_cache_read_only]="PHP_OPCACHE_FILE_CACHE_READ_ONLY_INI_DEFAULT_VALUE"
	[opcache.file_update_protection]="PHP_OPCACHE_FILE_UPDATE_PROTECTION_INI_DEFAULT_VALUE"
	[opcache.force_restart_timeout]="PHP_OPCACHE_FORCE_RESTART_TIMEOUT_INI_DEFAULT_VALUE"
	[opcache.huge_code_pages]="PHP_OPCACHE_HUGE_CODE_PAGES_INI_DEFAULT_VALUE"
	[opcache.interned_strings_buffer]="PHP_OPCACHE_INTERNED_STRINGS_BUFFER_INI_DEFAULT_VALUE"
	[opcache.jit]="PHP_OPCACHE_JIT_INI_DEFAULT_VALUE"
	[opcache.jit_bisect_limit]="PHP_OPCACHE_JIT_BISECT_LIMIT_INI_DEFAULT_VALUE"
	[opcache.jit_blacklist_root_trace]="PHP_OPCACHE_JIT_BLACKLIST_ROOT_TRACE_INI_DEFAULT_VALUE"
	[opcache.jit_blacklist_side_trace]="PHP_OPCACHE_JIT_BLACKLIST_SIDE_TRACE_INI_DEFAULT_VALUE"
	[opcache.jit_buffer_size]="PHP_OPCACHE_JIT_BUFFER_SIZE_INI_DEFAULT_VALUE"
	[opcache.jit_debug]="PHP_OPCACHE_JIT_DEBUG_INI_DEFAULT_VALUE"
	[opcache.jit_hot_func]="PHP_OPCACHE_JIT_HOT_FUNC_INI_DEFAULT_VALUE"
	[opcache.jit_hot_loop]="PHP_OPCACHE_JIT_HOT_LOOP_INI_DEFAULT_VALUE"
	[opcache.jit_hot_return]="PHP_OPCACHE_JIT_HOT_RETURN_INI_DEFAULT_VALUE"
	[opcache.jit_hot_side_exit]="PHP_OPCACHE_JIT_HOT_SIDE_EXIT_INI_DEFAULT_VALUE"
	[opcache.jit_max_exit_counters]="PHP_OPCACHE_JIT_MAX_EXIT_COUNTERS_INI_DEFAULT_VALUE"
	[opcache.jit_max_loop_unrolls]="PHP_OPCACHE_JIT_MAX_LOOP_UNROLLS_INI_DEFAULT_VALUE"
	[opcache.jit_max_polymorphic_calls]="PHP_OPCACHE_JIT_MAX_POLYMORPHIC_CALLS_INI_DEFAULT_VALUE"
	[opcache.jit_max_recursive_calls]="PHP_OPCACHE_JIT_MAX_RECURSIVE_CALLS_INI_DEFAULT_VALUE"
	[opcache.jit_max_recursive_returns]="PHP_OPCACHE_JIT_MAX_RECURSIVE_RETURNS_INI_DEFAULT_VALUE"
	[opcache.jit_max_root_traces]="PHP_OPCACHE_JIT_MAX_ROOT_TRACES_INI_DEFAULT_VALUE"
	[opcache.jit_max_side_traces]="PHP_OPCACHE_JIT_MAX_SIDE_TRACES_INI_DEFAULT_VALUE"
	[opcache.jit_max_trace_length]="PHP_OPCACHE_JIT_MAX_TRACE_LENGTH_INI_DEFAULT_VALUE"
	[opcache.jit_prof_threshold]="PHP_OPCACHE_JIT_PROF_THRESHOLD_INI_DEFAULT_VALUE"
	[opcache.lockfile_path]="PHP_OPCACHE_LOCKFILE_PATH_INI_DEFAULT_VALUE"
	[opcache.log_verbosity_level]="PHP_OPCACHE_LOG_VERBOSITY_LEVEL_INI_DEFAULT_VALUE"
	[opcache.max_accelerated_files]="PHP_OPCACHE_MAX_ACCELERATED_FILES_INI_DEFAULT_VALUE"
	[opcache.max_file_size]="PHP_OPCACHE_MAX_FILE_SIZE_INI_DEFAULT_VALUE"
	[opcache.max_wasted_percentage]="PHP_OPCACHE_MAX_WASTED_PERCENTAGE_INI_DEFAULT_VALUE"
	[opcache.memory_consumption]="PHP_OPCACHE_MEMORY_CONSUMPTION_INI_DEFAULT_VALUE"
	[opcache.opt_debug_level]="PHP_OPCACHE_OPT_DEBUG_LEVEL_INI_DEFAULT_VALUE"
	[opcache.optimization_level]="PHP_OPCACHE_OPTIMIZATION_LEVEL_INI_DEFAULT_VALUE"
	[opcache.preferred_memory_model]="PHP_OPCACHE_PREFERRED_MEMORY_MODEL_INI_DEFAULT_VALUE"
	[opcache.preload]="PHP_OPCACHE_PRELOAD_INI_DEFAULT_VALUE"
	[opcache.preload_user]="PHP_OPCACHE_PRELOAD_USER_INI_DEFAULT_VALUE"
	[opcache.protect_memory]="PHP_OPCACHE_PROTECT_MEMORY_INI_DEFAULT_VALUE"
	[opcache.record_warnings]="PHP_OPCACHE_RECORD_WARNINGS_INI_DEFAULT_VALUE"
	[opcache.restrict_api]="PHP_OPCACHE_RESTRICT_API_INI_DEFAULT_VALUE"
	[opcache.revalidate_freq]="PHP_OPCACHE_REVALIDATE_FREQ_INI_DEFAULT_VALUE"
	[opcache.revalidate_path]="PHP_OPCACHE_REVALIDATE_PATH_INI_DEFAULT_VALUE"
	[opcache.save_comments]="PHP_OPCACHE_SAVE_COMMENTS_INI_DEFAULT_VALUE"
	[opcache.use_cwd]="PHP_OPCACHE_USE_CWD_INI_DEFAULT_VALUE"
	[opcache.validate_permission]="PHP_OPCACHE_VALIDATE_PERMISSION_INI_DEFAULT_VALUE"
	[opcache.validate_root]="PHP_OPCACHE_VALIDATE_ROOT_INI_DEFAULT_VALUE"
	[opcache.validate_timestamps]="PHP_OPCACHE_VALIDATE_TIMESTAMPS_INI_DEFAULT_VALUE"

	# Date/Time

	[date.timezone]="PHP_DATE_TIMEZONE_INI_DEFAULT_VALUE"

	# BC Math

	[bcmath.scale]="PHP_BCMATH_SCALE_INI_DEFAULT_VALUE"

	# Exif

	[exif.decode_jis_intel]="PHP_EXIF_DECODE_JIS_INTEL_INI_DEFAULT_VALUE"
	[exif.decode_jis_motorola]="PHP_EXIF_DECODE_JIS_MOTOROLA_INI_DEFAULT_VALUE"
	[exif.decode_unicode_intel]="PHP_EXIF_DECODE_UNICODE_INTEL_INI_DEFAULT_VALUE"
	[exif.decode_unicode_motorola]="PHP_EXIF_DECODE_UNICODE_MOTOROLA_INI_DEFAULT_VALUE"
	[exif.encode_jis]="PHP_EXIF_ENCODE_JIS_INI_DEFAULT_VALUE"
	[exif.encode_unicode]="PHP_EXIF_ENCODE_UNICODE_INI_DEFAULT_VALUE"

	# GD

	[gd.jpeg_ignore_warning]="PHP_GD_JPEG_IGNORE_WARNING_INI_DEFAULT_VALUE"

	# Intl

	[intl.default_locale]="PHP_INTL_DEFAULT_LOCALE_INI_DEFAULT_VALUE"
	[intl.error_level]="PHP_INTL_ERROR_LEVEL_INI_DEFAULT_VALUE"
	[intl.use_exceptions]="PHP_INTL_USE_EXCEPTIONS_INI_DEFAULT_VALUE"

	# LDAP

	[ldap.max_links]="PHP_LDAP_MAX_LINKS_INI_DEFAULT_VALUE"

	# SOAP

	[soap.wsdl_cache]="PHP_SOAP_WSDL_CACHE_INI_DEFAULT_VALUE"
	[soap.wsdl_cache_dir]="PHP_SOAP_WSDL_CACHE_DIR_INI_DEFAULT_VALUE"
	[soap.wsdl_cache_enabled]="PHP_SOAP_WSDL_CACHE_ENABLED_INI_DEFAULT_VALUE"
	[soap.wsdl_cache_limit]="PHP_SOAP_WSDL_CACHE_LIMIT_INI_DEFAULT_VALUE"
	[soap.wsdl_cache_ttl]="PHP_SOAP_WSDL_CACHE_TTL_INI_DEFAULT_VALUE"

	# MySQLi

	[mysqli.allow_local_infile]="PHP_MYSQLI_ALLOW_LOCAL_INFILE_INI_DEFAULT_VALUE"
	[mysqli.allow_persistent]="PHP_MYSQLI_ALLOW_PERSISTENT_INI_DEFAULT_VALUE"
	[mysqli.default_host]="PHP_MYSQLI_DEFAULT_HOST_INI_DEFAULT_VALUE"
	[mysqli.default_port]="PHP_MYSQLI_DEFAULT_PORT_INI_DEFAULT_VALUE"
	[mysqli.default_pw]="PHP_MYSQLI_DEFAULT_PW_INI_DEFAULT_VALUE"
	[mysqli.default_socket]="PHP_MYSQLI_DEFAULT_SOCKET_INI_DEFAULT_VALUE"
	[mysqli.default_user]="PHP_MYSQLI_DEFAULT_USER_INI_DEFAULT_VALUE"
	[mysqli.local_infile_directory]="PHP_MYSQLI_LOCAL_INFILE_DIRECTORY_INI_DEFAULT_VALUE"
	[mysqli.max_links]="PHP_MYSQLI_MAX_LINKS_INI_DEFAULT_VALUE"
	[mysqli.max_persistent]="PHP_MYSQLI_MAX_PERSISTENT_INI_DEFAULT_VALUE"
	[mysqli.rollback_on_cached_plink]="PHP_MYSQLI_ROLLBACK_ON_CACHED_PLINK_INI_DEFAULT_VALUE"

	# MySQL PDO Driver

	[pdo_mysql.default_socket]="PHP_PDO_MYSQL_DEFAULT_SOCKET_INI_DEFAULT_VALUE"

	# PostgreSQL

	[pgsql.allow_persistent]="PHP_PGSQL_ALLOW_PERSISTENT_INI_DEFAULT_VALUE"
	[pgsql.auto_reset_persistent]="PHP_PGSQL_AUTO_RESET_PERSISTENT_INI_DEFAULT_VALUE"
	[pgsql.ignore_notice]="PHP_PGSQL_IGNORE_NOTICE_INI_DEFAULT_VALUE"
	[pgsql.log_notice]="PHP_PGSQL_LOG_NOTICE_INI_DEFAULT_VALUE"
	[pgsql.max_links]="PHP_PGSQL_MAX_LINKS_INI_DEFAULT_VALUE"
	[pgsql.max_persistent]="PHP_PGSQL_MAX_PERSISTENT_INI_DEFAULT_VALUE"

	# Redis

	[redis.arrays.algorithm]="PHP_REDIS_ARRAYS_ALGORITHM_INI_DEFAULT_VALUE"
	[redis.arrays.auth]="PHP_REDIS_ARRAYS_AUTH_INI_DEFAULT_VALUE"
	[redis.arrays.autorehash]="PHP_REDIS_ARRAYS_AUTOREHASH_INI_DEFAULT_VALUE"
	[redis.arrays.connecttimeout]="PHP_REDIS_ARRAYS_CONNECTTIMEOUT_INI_DEFAULT_VALUE"
	[redis.arrays.consistent]="PHP_REDIS_ARRAYS_CONSISTENT_INI_DEFAULT_VALUE"
	[redis.arrays.distributor]="PHP_REDIS_ARRAYS_DISTRIBUTOR_INI_DEFAULT_VALUE"
	[redis.arrays.functions]="PHP_REDIS_ARRAYS_FUNCTIONS_INI_DEFAULT_VALUE"
	[redis.arrays.hosts]="PHP_REDIS_ARRAYS_HOSTS_INI_DEFAULT_VALUE"
	[redis.arrays.index]="PHP_REDIS_ARRAYS_INDEX_INI_DEFAULT_VALUE"
	[redis.arrays.lazyconnect]="PHP_REDIS_ARRAYS_LAZYCONNECT_INI_DEFAULT_VALUE"
	[redis.arrays.names]="PHP_REDIS_ARRAYS_NAMES_INI_DEFAULT_VALUE"
	[redis.arrays.pconnect]="PHP_REDIS_ARRAYS_PCONNECT_INI_DEFAULT_VALUE"
	[redis.arrays.previous]="PHP_REDIS_ARRAYS_PREVIOUS_INI_DEFAULT_VALUE"
	[redis.arrays.readtimeout]="PHP_REDIS_ARRAYS_READTIMEOUT_INI_DEFAULT_VALUE"
	[redis.arrays.retryinterval]="PHP_REDIS_ARRAYS_RETRYINTERVAL_INI_DEFAULT_VALUE"
	[redis.clusters.auth]="PHP_REDIS_CLUSTERS_AUTH_INI_DEFAULT_VALUE"
	[redis.clusters.cache_slots]="PHP_REDIS_CLUSTERS_CACHE_SLOTS_INI_DEFAULT_VALUE"
	[redis.clusters.persistent]="PHP_REDIS_CLUSTERS_PERSISTENT_INI_DEFAULT_VALUE"
	[redis.clusters.read_timeout]="PHP_REDIS_CLUSTERS_READ_TIMEOUT_INI_DEFAULT_VALUE"
	[redis.clusters.seeds]="PHP_REDIS_CLUSTERS_SEEDS_INI_DEFAULT_VALUE"
	[redis.clusters.timeout]="PHP_REDIS_CLUSTERS_TIMEOUT_INI_DEFAULT_VALUE"
	[redis.pconnect.connection_limit]="PHP_REDIS_PCONNECT_CONNECTION_LIMIT_INI_DEFAULT_VALUE"
	[redis.pconnect.echo_check_liveness]="PHP_REDIS_PCONNECT_ECHO_CHECK_LIVENESS_INI_DEFAULT_VALUE"
	[redis.pconnect.pool_detect_dirty]="PHP_REDIS_PCONNECT_POOL_DETECT_DIRTY_INI_DEFAULT_VALUE"
	[redis.pconnect.pool_pattern]="PHP_REDIS_PCONNECT_POOL_PATTERN_INI_DEFAULT_VALUE"
	[redis.pconnect.pool_poll_timeout]="PHP_REDIS_PCONNECT_POOL_POLL_TIMEOUT_INI_DEFAULT_VALUE"
	[redis.pconnect.pooling_enabled]="PHP_REDIS_PCONNECT_POOLING_ENABLED_INI_DEFAULT_VALUE"
	[redis.session.compression]="PHP_REDIS_SESSION_COMPRESSION_INI_DEFAULT_VALUE"
	[redis.session.compression_level]="PHP_REDIS_SESSION_COMPRESSION_LEVEL_INI_DEFAULT_VALUE"
	[redis.session.early_refresh]="PHP_REDIS_SESSION_EARLY_REFRESH_INI_DEFAULT_VALUE"
	[redis.session.lock_expire]="PHP_REDIS_SESSION_LOCK_EXPIRE_INI_DEFAULT_VALUE"
	[redis.session.lock_retries]="PHP_REDIS_SESSION_LOCK_RETRIES_INI_DEFAULT_VALUE"
	[redis.session.lock_wait_time]="PHP_REDIS_SESSION_LOCK_WAIT_TIME_INI_DEFAULT_VALUE"
	[redis.session.locking_enabled]="PHP_REDIS_SESSION_LOCKING_ENABLED_INI_DEFAULT_VALUE"

	# Tidy

	[tidy.clean_output]="PHP_TIDY_CLEAN_OUTPUT_INI_DEFAULT_VALUE"
	[tidy.default_config]="PHP_TIDY_DEFAULT_CONFIG_INI_DEFAULT_VALUE"

	# OpenTelemetry

	[opentelemetry.allow_stack_extension]="PHP_OPENTELEMETRY_ALLOW_STACK_EXTENSION_INI_DEFAULT_VALUE"
	[opentelemetry.attr_hooks_enabled]="PHP_OPENTELEMETRY_ATTR_HOOKS_ENABLED_INI_DEFAULT_VALUE"
	[opentelemetry.attr_post_handler_function]="PHP_OPENTELEMETRY_ATTR_POST_HANDLER_FUNCTION_INI_DEFAULT_VALUE"
	[opentelemetry.attr_pre_handler_function]="PHP_OPENTELEMETRY_ATTR_PRE_HANDLER_FUNCTION_INI_DEFAULT_VALUE"
	[opentelemetry.conflicts]="PHP_OPENTELEMETRY_CONFLICTS_INI_DEFAULT_VALUE"
	[opentelemetry.display_warnings]="PHP_OPENTELEMETRY_DISPLAY_WARNINGS_INI_DEFAULT_VALUE"
	[opentelemetry.validate_hook_functions]="PHP_OPENTELEMETRY_VALIDATE_HOOK_FUNCTIONS_INI_DEFAULT_VALUE"

	# XDebug Runtime Configuration

	[xdebug.cli_color]="PHP_XDEBUG_CLI_COLOR_INI_DEFAULT_VALUE"
	[xdebug.client_discovery_header]="PHP_XDEBUG_CLIENT_DISCOVERY_HEADER_INI_DEFAULT_VALUE"
	[xdebug.client_host]="PHP_XDEBUG_CLIENT_HOST_INI_DEFAULT_VALUE"
	[xdebug.client_port]="PHP_XDEBUG_CLIENT_PORT_INI_DEFAULT_VALUE"
	[xdebug.cloud_id]="PHP_XDEBUG_CLOUD_ID_INI_DEFAULT_VALUE"
	[xdebug.collect_assignments]="PHP_XDEBUG_COLLECT_ASSIGNMENTS_INI_DEFAULT_VALUE"
	[xdebug.collect_params]="PHP_XDEBUG_COLLECT_PARAMS_INI_DEFAULT_VALUE"
	[xdebug.collect_return]="PHP_XDEBUG_COLLECT_RETURN_INI_DEFAULT_VALUE"
	[xdebug.connect_timeout_ms]="PHP_XDEBUG_CONNECT_TIMEOUT_MS_INI_DEFAULT_VALUE"
	[xdebug.control_socket]="PHP_XDEBUG_CONTROL_SOCKET_INI_DEFAULT_VALUE"
	[xdebug.discover_client_host]="PHP_XDEBUG_DISCOVER_CLIENT_HOST_INI_DEFAULT_VALUE"
	[xdebug.dump.COOKIE]="PHP_XDEBUG_DUMP_COOKIE_INI_DEFAULT_VALUE"
	[xdebug.dump.ENV]="PHP_XDEBUG_DUMP_ENV_INI_DEFAULT_VALUE"
	[xdebug.dump.FILES]="PHP_XDEBUG_DUMP_FILES_INI_DEFAULT_VALUE"
	[xdebug.dump.GET]="PHP_XDEBUG_DUMP_GET_INI_DEFAULT_VALUE"
	[xdebug.dump.POST]="PHP_XDEBUG_DUMP_POST_INI_DEFAULT_VALUE"
	[xdebug.dump.REQUEST]="PHP_XDEBUG_DUMP_REQUEST_INI_DEFAULT_VALUE"
	[xdebug.dump.SERVER]="PHP_XDEBUG_DUMP_SERVER_INI_DEFAULT_VALUE"
	[xdebug.dump.SESSION]="PHP_XDEBUG_DUMP_SESSION_INI_DEFAULT_VALUE"
	[xdebug.dump_globals]="PHP_XDEBUG_DUMP_GLOBALS_INI_DEFAULT_VALUE"
	[xdebug.dump_once]="PHP_XDEBUG_DUMP_ONCE_INI_DEFAULT_VALUE"
	[xdebug.dump_undefined]="PHP_XDEBUG_DUMP_UNDEFINED_INI_DEFAULT_VALUE"
	[xdebug.file_link_format]="PHP_XDEBUG_FILE_LINK_FORMAT_INI_DEFAULT_VALUE"
	[xdebug.filename_format]="PHP_XDEBUG_FILENAME_FORMAT_INI_DEFAULT_VALUE"
	[xdebug.force_display_errors]="PHP_XDEBUG_FORCE_DISPLAY_ERRORS_INI_DEFAULT_VALUE"
	[xdebug.force_error_reporting]="PHP_XDEBUG_FORCE_ERROR_REPORTING_INI_DEFAULT_VALUE"
	[xdebug.gc_stats_output_name]="PHP_XDEBUG_GC_STATS_OUTPUT_NAME_INI_DEFAULT_VALUE"
	[xdebug.halt_level]="PHP_XDEBUG_HALT_LEVEL_INI_DEFAULT_VALUE"
	[xdebug.idekey]="PHP_XDEBUG_IDEKEY_INI_DEFAULT_VALUE"
	[xdebug.log]="PHP_XDEBUG_LOG_INI_DEFAULT_VALUE"
	[xdebug.log_level]="PHP_XDEBUG_LOG_LEVEL_INI_DEFAULT_VALUE"
	[xdebug.max_nesting_level]="PHP_XDEBUG_MAX_NESTING_LEVEL_INI_DEFAULT_VALUE"
	[xdebug.max_stack_frames]="PHP_XDEBUG_MAX_STACK_FRAMES_INI_DEFAULT_VALUE"
	[xdebug.mode]="PHP_XDEBUG_MODE_INI_DEFAULT_VALUE"
	[xdebug.output_dir]="PHP_XDEBUG_OUTPUT_DIR_INI_DEFAULT_VALUE"
	[xdebug.profiler_append]="PHP_XDEBUG_PROFILER_APPEND_INI_DEFAULT_VALUE"
	[xdebug.profiler_output_name]="PHP_XDEBUG_PROFILER_OUTPUT_NAME_INI_DEFAULT_VALUE"
	[xdebug.scream]="PHP_XDEBUG_SCREAM_INI_DEFAULT_VALUE"
	[xdebug.show_error_trace]="PHP_XDEBUG_SHOW_ERROR_TRACE_INI_DEFAULT_VALUE"
	[xdebug.show_exception_trace]="PHP_XDEBUG_SHOW_EXCEPTION_TRACE_INI_DEFAULT_VALUE"
	[xdebug.show_local_vars]="PHP_XDEBUG_SHOW_LOCAL_VARS_INI_DEFAULT_VALUE"
	[xdebug.start_upon_error]="PHP_XDEBUG_START_UPON_ERROR_INI_DEFAULT_VALUE"
	[xdebug.start_with_request]="PHP_XDEBUG_START_WITH_REQUEST_INI_DEFAULT_VALUE"
	[xdebug.trace_format]="PHP_XDEBUG_TRACE_FORMAT_INI_DEFAULT_VALUE"
	[xdebug.trace_options]="PHP_XDEBUG_TRACE_OPTIONS_INI_DEFAULT_VALUE"
	[xdebug.trace_output_name]="PHP_XDEBUG_TRACE_OUTPUT_NAME_INI_DEFAULT_VALUE"
	[xdebug.trigger_value]="PHP_XDEBUG_TRIGGER_VALUE_INI_DEFAULT_VALUE"
	[xdebug.use_compression]="PHP_XDEBUG_USE_COMPRESSION_INI_DEFAULT_VALUE"
	[xdebug.var_display_max_children]="PHP_XDEBUG_VAR_DISPLAY_MAX_CHILDREN_INI_DEFAULT_VALUE"
	[xdebug.var_display_max_data]="PHP_XDEBUG_VAR_DISPLAY_MAX_DATA_INI_DEFAULT_VALUE"
	[xdebug.var_display_max_depth]="PHP_XDEBUG_VAR_DISPLAY_MAX_DEPTH_INI_DEFAULT_VALUE"
)

# Read every directive default in one PHP process. Output is NUL-delimited and
# preserves the input order, so values map back to their variable by index.
PHP_INI_DIRECTIVE_NAMES=("${!PHP_INI_DIRECTIVE_MAP[@]}")

# shellcheck disable=SC2016  # the $name is PHP code, intentionally not expanded by the shell
mapfile -d '' -t PHP_INI_DIRECTIVE_VALUES < <(
	printf '%s\n' "${PHP_INI_DIRECTIVE_NAMES[@]}" |
		php -r 'while (($name = fgets(STDIN)) !== false) { $name = rtrim($name, "\n"); if ($name === "") { continue; } echo (string) ini_get($name), "\0"; }'
)

for _idx in "${!PHP_INI_DIRECTIVE_NAMES[@]}"; do
	printf -v "${PHP_INI_DIRECTIVE_MAP[${PHP_INI_DIRECTIVE_NAMES[$_idx]}]}" '%s' "${PHP_INI_DIRECTIVE_VALUES[$_idx]}"
done

unset PHP_INI_DIRECTIVE_MAP PHP_INI_DIRECTIVE_NAMES PHP_INI_DIRECTIVE_VALUES _idx

true
