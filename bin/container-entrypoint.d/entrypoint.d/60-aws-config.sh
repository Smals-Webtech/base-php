#!/usr/bin/env bash

AWS_ACCESS_KEY_ID_WCMTECH_DEFAULT=""
AWS_SECRET_ACCESS_KEY_WCMTECH_DEFAULT=""

# Temporary credentials are useless without their session token. Declaring the
# default keeps .Env.AWS_SESSION_TOKEN defined for the template, which renders
# the line only when a token was actually supplied.
AWS_SESSION_TOKEN_WCMTECH_DEFAULT=""

# AWS_REGION is the variable the SDKs and the CLI read first, and it carries no
# _WCMTECH_DEFAULT on purpose -- without one it is never registered for cleanup,
# so it survives into the application environment, which is what the documented
# IAM-role setup relies on. Seeding the default from it means a caller who sets
# only AWS_REGION still gets that region written to the rendered config file. An
# explicit AWS_DEFAULT_REGION still wins: 99-export-vars.sh keeps a value that is
# already set.
AWS_DEFAULT_REGION_WCMTECH_DEFAULT="${AWS_REGION:-us-east-1}"

AWS_PROFILE_WCMTECH_DEFAULT="default"
AWS_DEFAULT_OUTPUT_WCMTECH_DEFAULT="json"
AWS_CONFIG_FILE_WCMTECH_DEFAULT="/opt/etc/aws/config"
AWS_SHARED_CREDENTIALS_FILE_WCMTECH_DEFAULT="/opt/etc/aws/credentials"
AWS_S3_ENDPOINT_URL_WCMTECH_DEFAULT="https://s3.amazonaws.com"

true
