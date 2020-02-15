#!/bin/bash

#
# by TS, Apr 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

function printUsageAndExit() {
	echo "Usage: $VAR_MYNAME" >/dev/stderr
	exit 1
}

if [ $# -eq 1 ] && [ "$1" = "-h" -o "$1" = "--help" ]; then
	printUsageAndExit
fi

if [ $# -ne 0 ]; then
	printUsageAndExit
fi

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			if [ "$1" = "dartsdk" ]; then
				echo -n "x64"
			else
				echo -n "amd64"
			fi
			;;
		i686*)
			if [ "$1" = "qemu" ]; then
				echo -n "i386"
			elif [ "$1" = "dartsdk" ]; then
				echo -n "ia32"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" ]; then
				echo -n "x86"
			else
				echo -n "i386"
			fi
			;;
		aarch64*)
			if [ "$1" = "qemu" ]; then
				echo -n "aarch64"
			elif [ "$1" = "dartsdk" ]; then
				echo -n "arm64"
			elif [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			else
				echo -n "arm64"
			fi
			;;
		armv7*)
			if [ "$1" = "qemu" ]; then
				echo -n "arm"
			elif [ "$1" = "dartsdk" ]; then
				echo -n "arm"
			elif [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			else
				echo -n "armhf"
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

# ----------------------------------------------------------

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"
LVAR_DEBIAN_RELEASE="stretch"
LVAR_DEBIAN_VERSION="9.11"

# ----------------------------------------------------------

LVAR_DARTSDK_VERSION="2.7.0"
LVAR_CPUARCH_DARTSDK="$(_getCpuArch dartsdk)"
LVAR_DARTSASS_VERSION="1.24.0"

LVAR_IMAGE_NAME="dartsass-builder-native-${LVAR_DEBIAN_DIST}"
LVAR_IMAGE_VER="$LVAR_DARTSASS_VERSION"

# ----------------------------------------------------------

cd build-ctx || exit 1

LVAR_SRC_OS_IMAGE="tsle/os-debian-${LVAR_DEBIAN_RELEASE}-${LVAR_DEBIAN_DIST}:${LVAR_DEBIAN_VERSION}"
docker pull $LVAR_SRC_OS_IMAGE || exit 1
echo

echo -e "\n$VAR_MYNAME: Building Docker Image '${LVAR_IMAGE_NAME}:${LVAR_IMAGE_VER}'...\n"
docker build \
		--build-arg CF_SRC_OS_IMAGE="$LVAR_SRC_OS_IMAGE" \
		--build-arg CF_CPUARCH_DEB_DIST="$LVAR_DEBIAN_DIST" \
		--build-arg CF_DARTSDK_VERSION="$LVAR_DARTSDK_VERSION" \
		--build-arg CF_CPUARCH_DARTSDK="$LVAR_CPUARCH_DARTSDK" \
		--build-arg CF_DARTSASS_VERSION="$LVAR_DARTSASS_VERSION" \
		-t "${LVAR_IMAGE_NAME}":"$LVAR_IMAGE_VER" \
		. || exit 1

cd ..

docker run --rm -v "$(pwd)/dist":/dist "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" || exit 1

echo -e "\n$VAR_MYNAME: File has been created in ./dist/"
