pkg_name=tecmint-app
pkg_origin=gm_habitat
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_shasum="TODO"

pkg_svc_user="root" # so we can start nginx properly
pkg_deps=(
  core/curl
  core/coreutils
  chef/mlsa
  core/nginx
  core/jq-static
)
pkg_build_deps=(
  core/git
  core/make
  core/node
  core/rsync
)
pkg_exports=(
  [port]=service.port
  [host]=service.host
)
pkg_exposes=(port)

do_unpack() {
  # Copy the project files into the cache src path so we can have a clean
  # node_modules and only the files we need
  mkdir -p $CACHE_PATH/tecmint-app
  #mkdir -p $CACHE_PATH/library
  rsync --archive --exclude node_modules $PLAN_CONTEXT/.. $CACHE_PATH/tecmint-app
  #rsync --archive --exclude node_modules $PLAN_CONTEXT/../../library $CACHE_PATH
}

npm_install() {
  # --unsafe-perm enables the package.json install task to copy files when running
  # as superuser during the hab package building.
  # Copied from Habitat's node scaffolding:
  # https://github.com/habitat-sh/core-plans/blob/be88f083c123ab998711fd3a93976ad10492a955/scaffolding-node/lib/scaffolding.sh#L111-L116
  npm install \
    --unsafe-perm \
    --loglevel error \
    --fetch-retries 5 \
    "$@"
}

fix_interpreters() {
  # Fix the interpreters of the binaries
  # Note: many bin/* files are links, so the output will have duplicate entries
  for b in node_modules/.bin/*; do
    fix_interpreter "$(readlink -f -n "$b")" core/coreutils bin/env
  done
}

do_build() {
  # Disabling Usage Analytics
  export NG_CLI_ANALYTICS=false

#  echo "Building $CACHE_PATH/chef-ui-library"
#  pushd "$CACHE_PATH/chef-ui-library"
#    npm_install
#    fix_interpreters
#    npm run build:prod
#  popd

  echo "Building $CACHE_PATH/tecmint-app"
  pushd "$CACHE_PATH/tecmint-app"
    npm_install --production

    # Angular CLI isn't included in production deps so we need to install it manually.
    npm_install @angular/cli

    fix_interpreters
    npm run build

    npm uninstall @angular/cli --no-save
  popd
}

do_install() {
  ls $CACHE_PATH/tecmint-app
  cp -R $CACHE_PATH/tecmint-app/dist "$pkg_prefix"
}

do_after() {
  rm -rf ~/.netrc
}
