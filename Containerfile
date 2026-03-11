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
    && dnf clean all

# Disable unnecessary systemd services for container
RUN systemctl mask systemd-remount-fs.service \
    systemd-update-done.service \
    systemd-udev-trigger.service

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/sbin/init"]
