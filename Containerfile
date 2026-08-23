FROM registry.access.redhat.com/ubi10/ubi-init:latest

LABEL maintainer="fatherlinux <scott.mccarty@crunchtools.com>"
LABEL description="UBI 10 core base image with troubleshooting tools and systemd hardening"

# All packages available in UBI repos — no RHSM needed
RUN dnf install -y \
      iputils \
      bind-utils \
      net-tools \
      less \
      cronie \
      procps-ng \
      diffutils \
      rsyslog \
    && dnf clean all

# Disable unnecessary systemd services for container
RUN systemctl mask systemd-remount-fs.service \
    systemd-update-done.service \
    systemd-udev-trigger.service

# Central log forwarding (constitution XIII). Inherited by every image built on
# this base, so the ~12 systemd-based services on lotor get it without each
# repo having to opt in.
COPY config/rsyslog-forward.conf /etc/rsyslog.d/00-crunchtools-forward.conf
COPY config/rsyslog-restart.conf /etc/systemd/system/rsyslog.service.d/restart.conf
RUN systemctl enable rsyslog

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/sbin/init"]
