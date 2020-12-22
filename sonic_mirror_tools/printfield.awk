function printfield(ptn) {
    print NF
    for (i=1; i< NF; i++)
    {
        if ($i~/ptn/)
        {
            print $i
        }
        else
        {
            print "No match pattern",ptn,"$i"
        }
    }
}
