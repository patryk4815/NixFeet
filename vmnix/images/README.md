

```
unzstd -d nixos-sd-image-22.05pre335501.c71f061c68b-aarch64-linux.img.zst

diskutil list

diskutil unmountDisk /dev/disk4

dd bs=1m if=a.img of=/dev/disk4
dd bs=1m if=nixos-sd-image-22.05.20220724.dirty-aarch64-linux.img of=/dev/disk4


```