# sonic rebuilder

## prepare
Add "-include repack.mk" at the end of slave.mk

```makefile
...
-include repack.mk
```

# add some process to repack_script.sh

For example:

```bash
function repack_it() {
    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9855-48cd8d-w1-r0/
    sudo cp target/debs/buster/platform-modules-h3c-s9855-48cd8d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9855-48cd8d-w1-r0/

    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9855-24c8d-w1-r0/
    sudo cp target/debs/buster/platform-modules-h3c-s9855-24c8d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9855-24c8d-w1-r0/

    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9825-64d-w1-r0/
    sudo cp target/debs/buster/platform-modules-h3c-s9825-64d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-h3c_s9825-64d-w1-r0/

    sudo dpkg --root=$FILESYSTEM_ROOT -r sonic-device-data-h3c || true
    sudo dpkg --root=$FILESYSTEM_ROOT -i target/debs/buster/sonic-device-data-h3c_1.0_all.deb
}

repack_it || true

```

# run repack.sh or rebuild.sh 
