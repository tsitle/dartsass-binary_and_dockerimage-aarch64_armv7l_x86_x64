#! /bin/bash

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

function md5sum_poly() {
	case "$OSTYPE" in
		linux*) md5sum "$1" ;;
		darwin*) md5 -r "$1" | sed -e 's/ /  /' ;;
		*) echo "Error: Unknown OSTYPE '$OSTYPE'" >/dev/stderr; echo -n "$1" ;;
	esac
}

# @param string $1 Filename
# @param bool $2 (Optional) Output error on MD5.err404? Default=true
function _getCommonFile() {
	[ -z "$LVAR_GITHUB_BASE" ] && return 1
	[ -z "$1" ] && return 1
	if [ ! -f "cache/$1" -o ! -f "cache/$1.md5" ]; then
		local TMP_DN="$(dirname "$1")"
		if [ "$TMP_DN" != "." -a "$TMP_DN" != "./" -a "$TMP_DN" != "/" ]; then
			[ ! -d "cache/$TMP_DN" ] && {
				mkdir "cache/$TMP_DN" || return 1
			}
		fi
		if [ ! -f "cache/$1.md5" ]; then
			echo -e "\nDownloading file '$1.md5'...\n"
			curl -L \
					-o cache/$1.md5 \
					${LVAR_GITHUB_BASE}/$1.md5 || return 1
		fi

		local TMP_MD5EXP="$(cat "cache/$1.md5" | cut -f1 -d\ )"
		if [ -z "$TMP_MD5EXP" ]; then
			echo "Could not get expected MD5. Aborting." >/dev/stderr
			rm "cache/$1.md5"
			return 1
		fi
		if [ "$TMP_MD5EXP" = "404:" ]; then
			[ "$2" != "false" ] && echo "Could not download MD5 file (Err 404). Aborting." >/dev/stderr
			rm "cache/$1.md5"
			return 2
		fi

		echo -e "\nDownloading file '$1'...\n"
		curl -L \
				-o cache/$1 \
				${LVAR_GITHUB_BASE}/$1 || return 1
		local TMP_MD5CUR="$(md5sum_poly "cache/$1" | cut -f1 -d\ )"
		if [ "$TMP_MD5EXP" != "$TMP_MD5CUR" ]; then
			echo "Expected MD5 != current MD5. Aborting." >/dev/stderr
			echo "  '$TMP_MD5EXP' != '$TMP_MD5CUR'" >/dev/stderr
			echo "Renaming file to '${1}-'" >/dev/stderr
			mv "cache/$1" "cache/${1}-"
			return 1
		fi
	fi
	return 0
}

# ----------------------------------------------------------

LVAR_GITHUB_BASE="https://raw.githubusercontent.com/tsitle/docker_images_common_files/master"

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"
LVAR_DEBIAN_RFS="$(_getCpuArch debian_rootfs)"
LVAR_DEBIAN_VERSION="9.11"

# ----------------------------------------------------------

LVAR_DARTSDK_VERSION="2.7.0"
LVAR_CPUARCH_DARTSDK="$(_getCpuArch dartsdk)"
LVAR_DARTSASS_VERSION="1.24.0"

LVAR_IMAGE_NAME="dartsass-builder-native-${LVAR_DEBIAN_DIST}"
LVAR_IMAGE_VER="$LVAR_DARTSASS_VERSION"

cd build-ctx || exit 1

[ ! -d cache ] && {
	mkdir cache || exit 1
}

_getCommonFile "debian_stretch/rootfs-debian_stretch_${LVAR_DEBIAN_VERSION}-${LVAR_DEBIAN_RFS}.tar.xz" || exit 1

echo -e "\n$VAR_MYNAME: Building Docker Image '${LVAR_IMAGE_NAME}:${LVAR_IMAGE_VER}'...\n"
docker build \
		--build-arg CF_CPUARCH_DEB_ROOTFS="$LVAR_DEBIAN_RFS" \
		--build-arg CF_DEBIAN_VERSION="$LVAR_DEBIAN_VERSION" \
		--build-arg CF_DARTSDK_VERSION="$LVAR_DARTSDK_VERSION" \
		--build-arg CF_CPUARCH_DARTSDK="$LVAR_CPUARCH_DARTSDK" \
		--build-arg CF_CPUARCH_DEB_DIST="$LVAR_DEBIAN_DIST" \
		--build-arg CF_DARTSASS_VERSION="$LVAR_DARTSASS_VERSION" \
		-t "${LVAR_IMAGE_NAME}":"$LVAR_IMAGE_VER" \
		. || exit 1

cd ..

docker run --rm -v "$(pwd)/dist":/dist "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" || exit 1

echo -e "\n$VAR_MYNAME: File has been created in ./dist/"
