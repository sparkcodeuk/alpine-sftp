FROM alpine:latest
MAINTAINER Dan Harris <daniel@sparkcode.co.uk>

#############################################################################
# NOTE: Check the README.md for information on how best to build this image #
#############################################################################

# Configurable build arguments (with defaults)
ARG SFTP_UID=1000
ARG SFTP_GID=1000
ARG SFTP_USERNAME=sftp

# Check build arguments are set
RUN test -n "${SFTP_UID}" \
    && test -n "${SFTP_GID}" \
    && test -n "${SFTP_USERNAME}"

# Update & install required software
RUN apk update \
    && apk upgrade \
    && apk add \
        openssh-server \
        openssh-sftp-server \
        pwgen

# Trash all users & groups (except for root/sshd)
# Generate host keys
# Generate strong password
# Add sftp group/user
# Update password
# Configure /sftp directory
# Configure SSH service
# Print generated password
RUN sed -e 's/:.*//' /etc/passwd|grep -v '^\(root\|sshd\)$'|xargs -n1 -I{} sh -c 'deluser {} 2>/dev/null || true' \
    && sed -e 's/:.*//' /etc/group|grep -v '^\(root\|sshd\)$'|xargs -n1 -I{} sh -c 'delgroup {} 2>/dev/null || true' \
    && ssh-keygen -A \
    && SFTP_PASSWORD=$(pwgen -s1 32) \
    && addgroup -g ${SFTP_GID} ${SFTP_USERNAME} \
    && adduser -h /sftp -s /sbin/nologin -G ${SFTP_USERNAME} -D -u ${SFTP_UID} ${SFTP_USERNAME} \
    && echo "${SFTP_USERNAME}:$SFTP_PASSWORD" | chpasswd \
    && echo -e '\e[32m******************************************\e[39m' \
    && echo -e "\e[32mCreated SFTP user...\e[39m" \
    && echo -e "\e[32mUsername: ${SFTP_USERNAME}\e[39m" \
    && echo -e "\e[32mPassword: $SFTP_PASSWORD\e[39m" \
    && echo -e "\e[32mUser ID: (${SFTP_UID}) / Group ID: (${SFTP_GID})\e[39m" \
    && echo -e '\e[32m******************************************\e[39m' \
    && unset SFTP_PASSWORD \
    && mkdir -p /sftp \
    && chown -R root:root /sftp \
    && chmod 755 /sftp \
    && echo -e "\n\
Match User ${SFTP_USERNAME}\n\
ForceCommand internal-sftp\n\
PasswordAuthentication yes\n\
ChrootDirectory /sftp\n\
PermitTunnel no\n\
AllowAgentForwarding no\n\
AllowTcpForwarding no\n\
X11Forwarding no\n\
\n" >> /etc/ssh/sshd_config

VOLUME ["/sftp"]

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
