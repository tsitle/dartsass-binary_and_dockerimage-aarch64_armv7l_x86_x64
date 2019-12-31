# Dart Sass binary packages for AARCH64, ARMv7l, X86 and X64 and Docker Image for creating the packages

This repository provides [Dart Sass](https://sass-lang.com/dart-sass) binary packages for

- AARCH64 (aarch64/arm64v8/arm64)
- ARMv7l (armv7l/arm32v7/armhf)
- X86 (x86/i386/i686/ia32)
- X64 (x64/amd64/x86_64)

as well as the Docker Image used for building the binary packages.  

## Using the pre-built binary
### AARCH64 or ARMv7l or X64
Extract the binary package on the target host:

```
$ sudo tar xf binary/sass.dart-linux-<ARCH>-<VERSION>.tgz -C /usr/local/bin/
$ sudo ln -s /usr/local/bin/sass.dart-linux-<ARCH>-<VERSION> /usr/local/bin/sass
```

### X86
On X86 Dart Sass cannot be compiled into a binary.  
Instead the runtime interpreter needs to be used.

```
$ sudo tar xf binary/sass.dart-linux-i386-<SASS_VERSION>-snapshot.tgz -C /opt/
$ sudo ln -s /opt/sass.dart-linux-i386-<SASS_VERSION>-snapshot/sass /usr/local/bin/
```

### Verify that the binary is OK

```
$ sass
```

Note: due to reasons unknown the command `$ sass --version` will issue an error.

## Building the binary
### Cross-compiling on a X64/AMD64 host
On the X64/AMD64 host, run:

```
$ cd cross-build
For AARCH64:
	$ ./build_binary.sh arm64
```

(Cross-compiling is currently only available for the AARCH64 target)

This will generate the binary package `./dist/sass.dart-linux-<ARCH>-<VERSION>.tgz`.

Follow above instructions for using the pre-built binary.  
You'll just need to replace the path `binary/` with `dist/`.

### Compiling on the target host
On the host machine, run:

```
$ cd native-build
$ ./build_binary.sh
```

This will generate the binary package `./dist/sass.dart-linux-<ARCH>-<VERSION>.tgz`.

Follow above instructions for using the pre-built binary.  
You'll just need to replace the path `binary/` with `dist/`.

---

The Docker Image is based on:

- [https://github.com/tsitle/dockercompose-binary\_and\_dockerimage-aarch64\_armv7l\_x86\_x64](https://github.com/tsitle/dockercompose-binary_and_dockerimage-aarch64_armv7l_x86_x64)
- [https://github.com/tsitle/go-binary\_and\_dockerimage-aarch64\_armv7l\_x86](https://github.com/tsitle/go-binary_and_dockerimage-aarch64_armv7l_x86)
