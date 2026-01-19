group "default" {
  targets = ["fpm-prd","nginx-prd","apache-prd","cli-prd","fpm-dev","nginx-dev","apache-dev","cli-dev"]
}

variable "VARIANTS" {
  default = ["fpm", "nginx", "apache", "cli"]
}

variable "ALPINE_VERSION" {
  default = "3.23"
}

variable "PHP_VERSION" {
  default = "8.4.17"
}

variable "PHP_EXT_INSTALLER_VERSION" {
  default = "2.9.27"
}

variable "NGINX_VERSION" {
  default = "1.28.0"
}

variable "NODE_VERSION" {
  default = "22"
}

variable "COMPOSER_VERSION" {
  default = "2.9.3"
}

variable "AWS_CLI_VERSION" {
  default = "2.32.7"
}

variable "GOMPLATE_VERSION" {
  default = "4.3.3"
}

variable "WAIT4X_VERSION" {
  default = "3.6.0"
}

variable "DOCKER_IMAGE_NAME" {
  default = "smalswebtech/base-php"
}

variable "DOCKER_IMAGE_VERSION" {
  default = "snapshot"
}

variable "DOCKER_IMAGE_LATEST" {
  default = true
}

variable "GIT_HASH" {}

function "tag" {
  params = [version, tgt, variant, githash]
  result = [
    # remove latest- prefix while "latest" version must be just $variant-$target tag
    version == "" ? "" : "${DOCKER_IMAGE_NAME}:${trimprefix("${version}-${variant}${tgt == "dev" ? "-dev" : ""}${githash == "" ? "" : "-${githash}"}", "latest-")}",
  ]
}

# cleanTag ensures that the tag is a valid Docker tag
# see https://github.com/distribution/distribution/blob/v2.8.2/reference/regexp.go#L37
function "clean_tag" {
  params = [tag]
  result = substr(regex_replace(regex_replace(tag, "[^\\w.-]", "-"), "^([^\\w])", "r$0"), 0, 127)
}

# semver adds semver-compliant tag if a semver version number is passed, or returns the revision itself
# see https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
function "semver" {
  params = [rev]
  result = __semver(_semver(regexall("^v?(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", rev)))
}

function "_semver" {
    params = [matches]
    result = length(matches) == 0 ? {} : matches[0]
}

function "__semver" {
    params = [v]
    result = v == {} ? [clean_tag(DOCKER_IMAGE_VERSION)] : v.prerelease == null ? [v.major, "${v.major}.${v.minor}", "${v.major}.${v.minor}.${v.patch}"] : ["${v.major}.${v.minor}.${v.patch}-${v.prerelease}"]
}

target "default" {
  name = "${variant}-${tgt}"

  matrix = {
    tgt = ["prd","dev"]
    variant = ["cli", "fpm", "nginx", "apache"]
  }

  context    = "."
  dockerfile = "Dockerfile"
  target     = "${variant}-${tgt}"

  platforms  = [
    "linux/amd64",
    "linux/arm64"
  ]

  args = {
    ALPINE_VERSION_ARG = ALPINE_VERSION
    PHP_VERSION_ARG = DOCKER_IMAGE_VERSION == "snapshot" ? PHP_VERSION : DOCKER_IMAGE_VERSION
    PHP_EXT_INSTALLER_VERSION_ARG = PHP_EXT_INSTALLER_VERSION
    NODE_VERSION_ARG = NODE_VERSION
    COMPOSER_VERSION_ARG = COMPOSER_VERSION
    AWS_CLI_VERSION_ARG = AWS_CLI_VERSION
    NGINX_VERSION_ARG = NGINX_VERSION
    GOMPLATE_VERSION_ARG = GOMPLATE_VERSION
    WAIT4X_VERSION_ARG = WAIT4X_VERSION
  }

  labels = {
    "be.smals.webtech.base.build-date"     = "${timestamp()}"
    "be.smals.webtech.base.name"           = "Base PHP 8.4.x Docker Image"
    "be.smals.webtech.base.description"    = "Docker base image is the basic image on which you add layers (which are basically filesystem changes) and create a final image containing your App."
    "be.smals.webtech.base.url"            = "https://www.smals.be"
    "be.smals.webtech.base.vcs-ref"        = GIT_HASH
    "be.smals.webtech.base.vcs-url"        = "https://github.com/Smals-Webtech/base-php"
    "be.smals.webtech.base.vendor"         = "sebastian.molle@smals.be"
    "be.smals.webtech.base.version"        = DOCKER_IMAGE_VERSION == "snapshot" ? PHP_VERSION : DOCKER_IMAGE_VERSION
    "be.smals.webtech.base.release"        = GIT_HASH
    "be.smals.webtech.base.environment"    = tgt
    "be.smals.webtech.base.variant"        = variant
    "be.smals.webtech.base.schema-version" = "1.0"
  }

  tags = distinct(flatten([
      DOCKER_IMAGE_LATEST ? tag("latest", tgt, variant, "") : [],
      GIT_HASH != "" && DOCKER_IMAGE_VERSION != "snapshot" ? tag("${DOCKER_IMAGE_VERSION}", tgt, variant, "${substr(GIT_HASH, 0, 7)}") : [],     
      DOCKER_IMAGE_VERSION == "snapshot"
        ? [tag("snapshot", tgt, variant, "")]
        : [for v in semver(DOCKER_IMAGE_VERSION) : tag(v, tgt, variant, "")]
    ])
  )

  attest = [
    {
      type = "provenance"
      mode = "max"
    },
    {
      type = "sbom"
    }
  ]

}