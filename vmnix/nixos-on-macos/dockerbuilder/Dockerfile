FROM golang:1.20 as builder
WORKDIR /code
COPY reverse-ssh .
RUN RS_PUB="$(cat ./assets/id_reverse-ssh.pub)" make build

FROM nixos/nix

#RUN wget https://github.com/Fahrj/reverse-ssh/releases/download/v1.2.0/reverse-sshx64 -O reverse-sshx64
COPY --from=builder /code/bin/reverse-sshx64 .
RUN chmod +x reverse-sshx64

RUN echo '#!/root/.nix-profile/bin/bash' > /bin/new
RUN echo 'export PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin' >> /bin/new
RUN echo 'export USER="root"' >> /bin/new
RUN echo 'export TERM="xterm-256color"' >> /bin/new
RUN echo '/root/.nix-profile/bin/bash' >> /bin/new
RUN chmod +x /bin/new
RUN echo "system-features = kvm" >> /etc/nix/nix.conf

#rm /root/.nix-profile/bin/nix-store
#echo '#!/bin/sh' > /root/.nix-profile/bin/nix-store
#echo '/nix/store/azvn85cras6xv4z5j85fiy406f24r1q0-nix-2.18.1/bin/nix-store --serve --write 2>/dev/null' >> /root/.nix-profile/bin/nix-store
#chmod +x /root/.nix-profile/bin/nix-store

ENV TERM=xterm-256color
CMD ["./reverse-sshx64", "-l", "-p", "22", "-s", "/bin/new", "-v"]

#
#         * Password "letmeinbrudipls"
#         * PubKey   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlbJwr+ueQ0gojy4QWr2sUWcNC/Y9eV9RdY3PLO7Bk/ Brudi"

# docker build -t xd .
# docker run -p 2222:22 -t xd
# ssh root@127.0.0.1 -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null