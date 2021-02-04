func replaceEasyInstall()
{
    if (repomirror != "")
    {
        replaceTo = repomirror
    }
    else
    {
        replaceTo = "10.153.3.130"
    }

    #build_debian.sh
    #printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"for searchdir in \$(find /usr -type d -name setuptools) ; do find \$searchdir -type f -name \\\"*.py\\\" -exec sed -i \\\"s/https:\\\\/\\\\/pypi.python.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g;s/https:\\\\/\\\\/pypi.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g\\\" {} + ; done\"\n");

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"find /usr/lib/python2.7/dist-packages/setuptools/ -type f -name \\\"*.py\\\" -exec sed -i \\\"s/https:\\\\/\\\\/pypi.python.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g;s/https:\\\\/\\\\/pypi.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g\\\" {} +\"\n");
    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"[ ! -d /usr/lib/python3/dist-packages/setuptools/ ] || find /usr/lib/python3/dist-packages/setuptools/ -type f -name \\\"*.py\\\" -exec sed -i \\\"s/https:\\\\/\\\\/pypi.python.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g;s/https:\\\\/\\\\/pypi.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g\\\" {} +\"\n");
    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"[ ! -d /usr/lib/python3.7/dist-packages/setuptools/ ] || find /usr/lib/python3.7/dist-packages/setuptools/ -type f -name \\\"*.py\\\" -exec sed -i \\\"s/https:\\\\/\\\\/pypi.python.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g;s/https:\\\\/\\\\/pypi.org/http:\\\\/\\\\/10.153.3.130\\\\/pypi\\\\/web/g\\\" {} +\"\n");

    printf("sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"echo -e \\\"[global]\\nindex-url=http://%s/pypi/web/simple\\ntrusted-host=%s\\\" >/etc/pip.conf\"", replaceTo, replaceTo)
    #print "sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"apt-get install -y python-pip\""
    #print "sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"pip install -U pip\""
}

BEGIN { done=0 }
{
    if (done == 0)
    {
        if ($0~/easy_install pip/)
        {
            replaceEasyInstall()
            printf "\n"
            print $0
            print "sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT /bin/bash -c \"pip install wheel\""
            done=1
        }
        else
        {
            print $0
        }
    }
    else
    {
        print $0
    }
}

