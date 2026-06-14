#!/bin/bash

# Standalone test for get_latest_kernel_ver_in_repository parsing logic

set -e

echo "=== Running Kernel Version Parsing Tests ==="

# Mock environment variables
export mirror_url="http://mock.mirror/debian"
export debian_dist="sid"
export ocs_live_only_kernels="amd64"
export ocs_live_exclude_kernels="unsigned-kernel"
export DRBL_SCRIPT_PATH="."

# Mock wget function to intercept the download and create custom Packages.xz
wget() {
  local target_dir=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -P)
        target_dir="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  if [ -n "$target_dir" ]; then
    mkdir -p "$target_dir"
    # Create the Packages file with various kernel version patterns
    # In particular, 7.0.12+deb14.1-amd64 should be the highest version
    cat <<EOF > "$target_dir/Packages"
Package: linux-image-7.0.12+deb14.1-amd64
Package: linux-image-7.0.12+deb14-amd64
Package: linux-image-6.16.12+deb14+1-amd64
Package: linux-image-6.12.33+deb13-amd64
Package: linux-image-5.4.0-14-generic
Package: linux-image-6.5.0-5-amd64
Package: linux-image-6.6.9-amd64
EOF
    # Compress it to Packages.xz
    xz -f -z "$target_dir/Packages"
  fi
}
export -f wget

# Load functions
. scripts/sbin/ocs-functions

# Run the target function
release_kernel_ver=""
get_latest_kernel_ver_in_repository amd64

echo "Selected kernel version: '$release_kernel_ver'"

if [ "$release_kernel_ver" = "7.0.12+deb14.1" ]; then
  echo "PASS: Successfully parsed and found the latest kernel version '7.0.12+deb14.1'"
  exit 0
else
  echo "FAIL: Expected '7.0.12+deb14.1', but got '$release_kernel_ver'"
  exit 1
fi
