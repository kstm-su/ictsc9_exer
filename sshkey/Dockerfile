FROM ubuntu:18.04

RUN apt update && apt install -y sudo rsyslog openssh-server iproute2 less
RUN mkdir -p /run/sshd

ADD entrypoint.sh /entrypoint.sh
ADD ssh_config /root/.ssh/config

RUN echo 'user ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN useradd -s/bin/bash -m user && echo 'user\nuser' | passwd user

RUN useradd -s/bin/bash -m hoge
ADD https://github.com/bgpat.keys /home/hoge/.ssh/authorized_keys
RUN chown -R hoge:hoge /home/hoge/.ssh
RUN chmod 666 /home/hoge/.ssh/authorized_keys

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
