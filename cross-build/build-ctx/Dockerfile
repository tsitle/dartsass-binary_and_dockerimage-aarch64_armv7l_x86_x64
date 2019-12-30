FROM scratch

ARG CF_DEBIAN_VERSION
ARG CF_CPUARCH_DEB_TRG_ROOTFS

# add Debian root-fs
ADD cache/debian_stretch/rootfs-debian_stretch_${CF_DEBIAN_VERSION}-${CF_CPUARCH_DEB_TRG_ROOTFS}.tar.xz /

# Enable cross-build
ARG CF_QEMU_TRG_ARCH
ADD files/qemu-bin.tgz /usr/bin/
ADD cache/qemu_binary_static/qemu-${CF_QEMU_TRG_ARCH}-static.tgz /usr/bin/

#
COPY files/bash/dot_bashrc /root/.bashrc


# -------------------------
RUN [ "cross-build-start" ]

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt-get update \
	&& apt-get --assume-yes upgrade \
	&& apt-get --assume-yes dist-upgrade \
	&& apt-get -y --no-install-recommends install \
			nano \
			less \
			locales \
			ca-certificates \
			apt-transport-https \
			gnupg2 \
			curl \
			unzip

# set locales
RUN \
	sed -i \
			-e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' \
			-e 's/# de_DE ISO-8859-1/de_DE ISO-8859-1/' \
			-e 's/# de_DE@euro ISO-8859-15/de_DE@euro ISO-8859-15/' \
			-e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
			-e 's/# en_US ISO-8859-1/en_US ISO-8859-1/' \
			-e 's/# en_US@euro ISO-8859-15/en_US@euro ISO-8859-15/' \
			/etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=de_DE.UTF-8

ENV LANG de_DE.UTF-8
ENV LANGUAGE de
ENV LC_ALL de_DE.UTF-8

# set up timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#
ARG CF_DARTSDK_VERSION
ARG CF_CPUARCH_DARTSDK_TRG

ARG CF_CPUARCH_DEB_TRG_DIST

ARG CF_DARTSASS_VERSION

ENV PATH=$PATH:/root/dart-sdk/bin

RUN \
	curl -L -o dartsdk.zip \
			https://storage.googleapis.com/dart-archive/channels/stable/release/${CF_DARTSDK_VERSION}/sdk/dartsdk-linux-${CF_CPUARCH_DARTSDK_TRG}-release.zip \
	&& unzip dartsdk.zip \
	&& rm dartsdk.zip \
	#
	&& curl -L -o dartsass.tgz \
			https://github.com/sass/dart-sass/archive/${CF_DARTSASS_VERSION}.tar.gz \
	&& tar xf dartsass.tgz \
	&& rm dartsass.tgz \
	#
	&& cd dart-sass-${CF_DARTSASS_VERSION} \
	&& pub get

ENV TMP_DARTSASS_BFN="sass.dart-linux-${CF_CPUARCH_DEB_TRG_DIST}-${CF_DARTSASS_VERSION}"

RUN \
	echo "Compiling cross-built binary..."; \
	cd /root/dart-sass-${CF_DARTSASS_VERSION} \
	&& dart2native bin/sass.dart -o /root/${TMP_DARTSASS_BFN} \
	&& cd .. \
	&& tar czf \
			${TMP_DARTSASS_BFN}.tgz \
			${TMP_DARTSASS_BFN} \
	&& md5sum ${TMP_DARTSASS_BFN}.tgz > ${TMP_DARTSASS_BFN}.tgz.md5 \
	&& rm -r dart-sdk dart-sass-${CF_DARTSASS_VERSION} .pub-cache \
	&& rm ${TMP_DARTSASS_BFN}

#
RUN \
	apt-get --quiet --yes autoclean \
	&& apt-get --quiet --yes autoremove \
	&& apt-get --quiet --yes clean \
	&& rm -rf \
			/usr/share/man \
			/usr/share/doc \
			/usr/share/icons \
			/usr/share/poppler \
			/usr/share/mime \
			/var/lib/apt/lists*

#
ENV DEBIAN_FRONTEND=newt

# Disable cross-build
# Note: don't disable this, since we want to run this container on x86_64, not the target host
#RUN [ "cross-build-end" ]

# Copy out the generated binary
VOLUME /dist
CMD cp /root/sass.dart-* /dist
