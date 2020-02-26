FROM jenkins/jnlp-slave:alpine
USER root

ENV JENKINS_MASTER http://localhost:8080
ENV JENKINS_SLAVE_NAME dind-node
ENV JENKINS_SLAVE_SECRET ""
ENV JNLP_POSTGRESQL_VER="42.2.10"
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 19.03.5
ENV CLAIR_SCANNER_VERSION 8
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 52379fa76dee07ca038624d639d9e14f4fb719ff

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
RUN apk add --no-cache \
    btrfs-progs \
    ca-certificates \
    curl \
    e2fsprogs \
    e2fsprogs-extra \
    gcc \
    iproute2 \
    iptables \
    libc-dev \
    libffi-dev \
    make \
    openssl-dev \
    py-pip \
    python-dev \
    sudo \
    xfsprogs \
    xz \
# pigz: https://github.com/moby/moby/pull/35697 (faster gzip implementation)
		pigz \
	; \
  curl -o /usr/local/lib/postgresql.jar -sS "https://jdbc.postgresql.org/download/postgresql-${JNLP_POSTGRESQL_VER}.jar"; \
# only install zfs if it's available for the current architecture
# https://git.alpinelinux.org/cgit/aports/tree/main/zfs/APKBUILD?h=3.6-stable#n9 ("all !armhf !ppc64le" as of 2017-11-01)
# "apk info XYZ" exits with a zero exit code but no output when the package exists but not for this arch
	if zfs="$(apk info --no-cache --quiet zfs)" && [ -n "$zfs" ]; then \
		apk add --no-cache zfs; \
	fi

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN set -eux; \
	\
# this "case" statement is generated via "update.sh"
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) dockerArch='x86_64' ;; \
		armhf) dockerArch='armel' ;; \
		aarch64) dockerArch='aarch64' ;; \
		ppc64le) dockerArch='ppc64le' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
	esac; \
  \
	if ! wget -O /usr/local/bin/clair-scanner "https://github.com/arminc/clair-scanner/releases/download/v${CLAIR_SCANNER_VERSION}/clair-scanner_linux_amd64"; then \
		echo >&2 "error: failed to download 'clair-scanner_linux_amd64 ${CLAIR_SCANNER_VERSION}"; \
		exit 1; \
	fi; \
  chmod +x /usr/local/bin/clair-scanner; \
	\
	if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	docker --version; \
  pip install docker-compose awscli \
  # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
	&& addgroup -S dockremap \
	&& adduser -S -G dockremap dockremap \
	&& echo 'dockremap:165536:65536' >> /etc/subuid \
	&& echo 'dockremap:165536:65536' >> /etc/subgid \
  && wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind \
  # Fix /home/jenkins/.ssh folder
  && mkdir -p /home/jenkins/.ssh && rm -rf /home/jenkins/.ssh/* && chown jenkins.jenkins /home/jenkins/.ssh -R

ADD .docker/base/ /

VOLUME /var/lib/docker
EXPOSE 2375

ENTRYPOINT ["jenkins-slave"]

USER jenkins
