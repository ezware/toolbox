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

    findDirs[0] = "/usr/lib/python2.7/dist-packages/setuptools/"
    findDirs[1] = "/usr/lib/python3/dist-packages/setuptools/"
    findDirs[2] = "/usr/local/lib/python2.7/dist-packages/setuptools/"
    findDirs[3] = "/usr/local/lib/python3.7/dist-packages/setuptools/"

    dirCount = length(findDirs)
    for (i = 0; i < dirCount; i++)
    {
        printf("RUN [ ! -d %s ] || find %s -type f -name '*.py' -exec sed -i 's|https://pypi.python.org|http://%s/pypi/web|g;s|https://pypi.org|http://%s/pypi/web|g' {} +\n", 
               findDirs[i], findDirs[i], replaceTo, replaceTo)
    }
}

BEGIN { done=0 }
{
    print $0

#    if (done == 0)
#    {
        if ($0~/install[ ]+setuptools/) 
        {
            addpipconf()
            printf "\n"
            #done=1
        }
#    }
}
