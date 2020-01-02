ARG CF_DEBIAN_RELEASE
ARG CF_DEBIAN_VERSION
ARG CF_CPUARCH_DEB_DIST

FROM tsle/os-debian-${CF_DEBIAN_RELEASE}-${CF_CPUARCH_DEB_DIST}:${CF_DEBIAN_VERSION}

#
WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt-get update \
	&& apt-get --assume-yes upgrade \
	&& apt-get --assume-yes dist-upgrade \
	&& apt-get -y --no-install-recommends install \
			ca-certificates \
			apt-transport-https \
			gnupg2 \
			unzip \
			p7zip

#
ARG CF_DARTSDK_VERSION
ARG CF_CPUARCH_DARTSDK

ARG CF_CPUARCH_DEB_DIST

ARG CF_DARTSASS_VERSION

ENV PATH=$PATH:/root/dart-sdk/bin

RUN \
	curl -L -o dartsdk.zip \
			https://storage.googleapis.com/dart-archive/channels/stable/release/${CF_DARTSDK_VERSION}/sdk/dartsdk-linux-${CF_CPUARCH_DARTSDK}-release.zip \
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

ENV TMP_DARTSDK_BFN="dartsdk-linux-${CF_CPUARCH_DEB_DIST}-${CF_DARTSDK_VERSION}"

ENV TMP_DARTSASS_BFN="sass.dart-linux-${CF_CPUARCH_DEB_DIST}-${CF_DARTSASS_VERSION}"

COPY files/sass-template /root/

RUN \
	if [ "${CF_CPUARCH_DEB_DIST}" = "i386" ]; then \
		cd /root; \
		#
		chmod a+r -R dart-sdk/ \
		&& find dart-sdk/ -type d -exec chmod a+x {} \; \
		&& chmod a+x dart-sdk/bin/* \
		|| exit 1; \
		#
		mkdir /opt/${TMP_DARTSASS_BFN}-snapshot \
		&& sed \
				-e "s/###CPUARCH###/${CF_CPUARCH_DEB_DIST}/g" \
				-e "s/###SASSVERSION###/${CF_DARTSASS_VERSION}/g" \
				-e "s/###DARTSDKVERSION###/${CF_DARTSDK_VERSION}/g" \
				sass-template > /opt/${TMP_DARTSASS_BFN}-snapshot/sass \
		&& chmod a+rx /opt/${TMP_DARTSASS_BFN}-snapshot/sass \
		&& cp dart-sdk/bin/dart /opt/${TMP_DARTSASS_BFN}-snapshot/ \
		&& cd dart-sass-${CF_DARTSASS_VERSION} \
		&& echo "Creating Dart-Sass snapshot..." \
		&& /opt/${TMP_DARTSASS_BFN}-snapshot/dart \
				--snapshot=/opt/${TMP_DARTSASS_BFN}-snapshot/sass.dart-snapshot \
				bin/sass.dart \
		&& echo "Creating tarball of Dart-Sass snapshot..." \
		&& cd /opt \
		&& tar czf \
				/root/${TMP_DARTSASS_BFN}-snapshot.tgz \
				${TMP_DARTSASS_BFN}-snapshot \
		&& rm -r ${TMP_DARTSASS_BFN}-snapshot \
		|| exit 1; \
		#
		cd /root; \
		#
		mkdir ${TMP_DARTSASS_BFN}-src \
		&& cp -r dart-sdk ${TMP_DARTSASS_BFN}-src/${TMP_DARTSDK_BFN} \
		&& cp -r dart-sass-${CF_DARTSASS_VERSION} ${TMP_DARTSASS_BFN}-src/dart-sass \
		&& echo "#!/bin/bash" > ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "cd dart-sass || exit 1" >> ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "../${TMP_DARTSDK_BFN}/bin/pub get || exit 1" >> ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "cd .." >> ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "echo 'To run Dart-Sass use'" >> ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "echo \"  \$(pwd)/${TMP_DARTSDK_BFN}/bin/dart \$(pwd)/dart-sass/bin/sass.dart\"" >> ${TMP_DARTSASS_BFN}-src/make.sh \
		&& chmod a+x ${TMP_DARTSASS_BFN}-src/make.sh \
		&& echo "Creating 7-Zip'ed tarball of Dart-Sass..." \
		&& tar cf - "${TMP_DARTSASS_BFN}-src" | \
			7zr a -si -v45m "${TMP_DARTSASS_BFN}-src.tar.7z" \
		&& rm -r "${TMP_DARTSASS_BFN}-src" \
		|| exit 1; \
		if [ ! -f ${TMP_DARTSASS_BFN}-src.tar.7z.002 ]; then \
			mv \
					${TMP_DARTSASS_BFN}-src.tar.7z.001 \
					${TMP_DARTSASS_BFN}-src.tar.7z || exit 1; \
		fi; \
		for TMPFN in ${TMP_DARTSASS_BFN}-src.tar.7z*; do md5sum $TMPFN > $TMPFN.md5; done \
	else \
		echo "Compiling native binary..."; \
		cd /root/dart-sass-${CF_DARTSASS_VERSION} \
		&& dart2native bin/sass.dart -o /root/${TMP_DARTSASS_BFN} \
		&& cd .. \
		&& tar czf \
				${TMP_DARTSASS_BFN}.tgz \
				${TMP_DARTSASS_BFN}; \
	fi; \
	cd /root \
	&& for TMPFN in sass.dart-linux-*.tgz; do md5sum $TMPFN > $TMPFN.md5; done \
	&& rm -r dart-sdk dart-sass-${CF_DARTSASS_VERSION} \
	#&& rm -r .pub-cache \
	&& echo -n

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
ENV DEBIAN_FRONTEND=dialog

# Copy out the generated binary
VOLUME /dist

ENV CF_CPUARCH_DEB_DIST=${CF_CPUARCH_DEB_DIST}
ENV CF_DARTSDK_VERSION=${CF_DARTSDK_VERSION}

CMD \
	[ -f /root/${TMP_DARTSASS_BFN}-src.tar.7z.001 ] && cp /root/${TMP_DARTSASS_BFN}-src.tar.7z.* /dist; \
	[ -f /root/${TMP_DARTSASS_BFN}-src.tar.7z ] && cp /root/${TMP_DARTSASS_BFN}-src.tar.7z* /dist; \
	cp /root/sass.dart-*.tgz* /dist
