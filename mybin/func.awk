#!/usr/bin/awk -f
function removeBracket(src) {
        pos=index(src, "(");
        if (pos > 0)
        {
            after=substr(src, 0, pos-1);
        }
        else
        {
            after=src; 
        }

	return after
}

function ltrim(str) {
    sub("^[ \t\n\r]+", "", str)
    return str
}

function rtrim(str) {
    sub("[ \t\n\r]+$", "", str)
    return str
}

function outputFnLine(fnline) {
    sub("[ ]*", "", fnline);
    printf "*" fnline "*"
}

function outputFnDoc(fn,fnline,doc) {
    print "##",fn;
    outputFnLine(fnline)
    print "\n```",doc,"\n```\n";
}

function outputNoDocFn(fn, fnline) {
    #don't output no doc function
}

function outputClsLine(clsline) {
    #to be done
}

function outputClassDoc(cls, clsline, doc) {
    print "#",cls;
    outputFnLine(clsline)
    print "\n```",doc,"\n```\n";
}

function beginWithDocNote(str) {
    if (substr(str, 0, 3) == "\"\"\"") {
        return 1;
    } else {
        return 0;
    }
}

function endWithDocNote(str) {
    strlen = length(str);
    if (strlen < 3) {
        return 0;
    }

    if (substr(str, strlen - 2) == "\"\"\"") {
        return 1;
    } else {
        return 0;
    }
}

function ltrimDocNote(str) {
    #remove whitespace
    #print "Before:", str;
    #print "After1:", ltrim(str);
    #print "After2:", substr(str, 3);
    return substr(ltrim(str), 4);
}

function rtrimDocNote(str) {
    #remove whitespace
    #print "Before2:", str;
    #print "After21:", rtrim(str);
    #print "After22:", substr(str,0,length(str) - 3);
    nospace=rtrim(str);
    return substr(nospace, 0, length(nospace) - 3);
}
