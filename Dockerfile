FROM ubuntu:24.04

# Dependencias para permitir conexiones SSH y ejecutar Ansible.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server sudo python3 python3-apt \
    && useradd -m -s /bin/bash ansible \
    && echo 'ansible:ansible' | chpasswd \
    && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 440 /etc/sudoers.d/ansible \
    && mkdir -p /run/sshd \
    && rm -f /etc/ssh/ssh_host_* \
    && printf 'PasswordAuthentication yes\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/99-ansible-lab.conf \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 22

CMD ["sh", "-c", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]
