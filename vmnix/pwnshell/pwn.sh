#!/bin/bash

docker build --platform linux/amd64 --build-arg frombuild=ubuntu -t pwn-amd64 -f ./Dockerfile.multi .
docker build --platform linux/arm/v7 --build-arg frombuild=ubuntu -t pwn-arm32v7 -f ./Dockerfile.multi .
docker build --platform linux/arm64 --build-arg frombuild=ubuntu -t pwn-arm64v8 -f ./Dockerfile.multi .

#docker run -v $(pwd):/work -w /work --rm --cap-add SYS_PTRACE -it pwn-amd64 bash
#docker run -v $(pwd):/work -w /work --rm --privileged -it pwn-amd64 bash
# nerdctl run -v /Users/psondej/nix:/Users/psondej/nix -v /Users/psondej/projekty/PycharmProjects/ctf/:/ctf -w /ctf --rm --cap-add SYS_PTRACE -it pwn-amd64 bash
# nerdctl run -v /Users/psondej/nix:/work/nix -v /Users/psondej/projekty/PycharmProjects/ctf/:/ctf -w /ctf --rm --privileged -it pwn-amd64 bash
# nix-shell /ctf/pwnshell/shell.nix
# cd /work/szkolenie/zad1
# python exploit.py

# nix copy --to file:///tmp/lima/nix $(nix-build --no-out-link shell.nix -A inputDerivation)
# nix copy --to file:///Users/psondej/nix $(nix-build --no-out-link shell.nix -A inputDerivation)