func addpipconf()
{
    if (repomirror != "") 
    {
        replaceTo = repomirror
    }
    else
    {
        replaceTo = "10.153.3.130"
    }

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT echo \"[global]\" > /etc/pip.conf \
    && echo \"index-url=http://%s/pypi/web/simple\" >> /etc/pip.conf \
    && echo \"trusted-host=%s\" >> /etc/pip.conf \
    && mkdir -p /root/.pip && cp /etc/pip.conf /root/.pip/\n", replaceTo, replaceTo)

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT [ ! -d /usr/lib/python2.7/dist-packages/setuptools/ ] || find /usr/lib/python2.7/dist-packages/setuptools/ -type f -name \"*.py\" -exec sed -i \"s/https:\\/\\/pypi.python.org/http:\\/\\/%s\\/pypi\\/web/g;s/https:\\/\\/pypi.org/http:\\/\\/%s\\/pypi\\/web/g\" {} +\n", replaceTo, replaceTo)

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT [ ! -d /usr/lib/python3/dist-packages/setuptools/ ] || find /usr/lib/python3/dist-packages/setuptools/ -type f -name \"*.py\" -exec sed -i \"s/https:\\/\\/pypi.python.org/http:\\/\\/%s\\/pypi\\/web/g;s/https:\\/\\/pypi.org/http:\\/\\/%s\\/pypi\\/web/g\" {} +\n", replaceTo, replaceTo)

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT [ ! -d /usr/local/lib/python2.7/dist-packages/setuptools/ ] || find /usr/local/lib/python2.7/dist-packages/setuptools/ -type f -name \"*.py\" -exec sed -i \"s/https:\\/\\/pypi.python.org/http:\\/\\/%s\\/pypi\\/web/g;s/https:\\/\\/pypi.org/http:\\/\\/%s\\/pypi\\/web/g\" {} +\n", replaceTo, replaceTo)

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT pip2 install [ ! -d /usr/local/lib/python3.7/dist-packages/setuptools/ ] || find /usr/local/lib/python3.7/dist-packages/setuptools/ -type f -name \"*.py\" -exec sed -i \"s/https:\\/\\/pypi.python.org/http:\\/\\/%s\\/pypi\\/web/g;s/https:\\/\\/pypi.org/http:\\/\\/%s\\/pypi\\/web/g\" {} +\n", replaceTo, replaceTo)
}

BEGIN { done=0 }
{
    if (done == 0)
    {
        if ($0 ~ /pip[23]? install/) 
        {
            addpipconf()
            printf "\n"
            done=1
        }
    }

    print $0
}
