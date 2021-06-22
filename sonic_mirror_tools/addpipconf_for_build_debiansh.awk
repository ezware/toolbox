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

    printf("sudo cp files/pip/pip.conf $FILESYSTEM_ROOT/etc/pip.conf")
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
