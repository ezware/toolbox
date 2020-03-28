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

function getDocNote(str) {
    if (str == "\"\"\"") {
        return 1;
    } else if (str == "'''") {
        return 2;
    }
    
    return 0;
}

function isDocNote(str) {
    return getDocNote(str);
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
    if (isDocNote(substr(str, 0, 3))) {
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

    if (isDocNote(substr(str, strlen - 2))) {
        return 1;
    } else {
        return 0;
    }
}

function getBeginDocNote(str) {
    return getDocNote(substr(str, 0, 3))
}

function getEndDocNote(str) {
    strlen = length(str);
    if (strlen < 3) {
        return 0
    }

    return getDocNote(substr(str, strlen - 2));
}

function ltrimDocNote(str) {
    return substr(ltrim(str), 4);
}

function rtrimDocNote(str) {
    #remove whitespace
    nospace=rtrim(str);
    return substr(nospace, 0, length(nospace) - 3);
}

BEGIN {
    state=1
}
{
  switch (state) {
    case 10:	#parse class
    {
        if ($1 == "class") {
            cls=removeBracket($2);
            clsline=$0;
            clsdesc=""
            state = 11;
        }
        break;
    }
    case 11:	#parse class doc begin
    {
        if ($1 == "def") {
            outputClassDoc(cls, clsline, clsdesc)
            fn=removeBracket($2);
            fnline=$0;
            state=2;
            desc="";
        }

        if (isDocNote($1) && (NF == 1)) {
            beginDocNote = getDocNote($1);
            state = 12;
        } else if (beginWithDocNote($1)) {
            beginDocNote = getBeginDocNote($1)
            #doc begin with """ and no new line
            if (endWithDocNote($NF)) {
                #doc in one line
                endDocNote = getEndDocNote($NF);
                if (endDocNote == beginDocNote) {
                    clsdesc = rtrimDocNote(ltrimDocNote(rtrim(ltrim($0))));
                    outputClassDoc(cls, clsline, clsdesc);
                    state = 1;
                } else {
                    clsdesc = clsdesc "\n" ltrimDocNote($0);
                    state = 12;                    
                }
            } else {
                clsdesc = clsdesc "\n" ltrimDocNote($0);
                state = 12;
            }
        }
        break;
    }
    case 12:	#parse class doc and doc end
    {
        needAppend = 0;
        if (isDocNote($1)) {
            endDocNote = getDocNote($1);
            if (endDocNote == beginDocNote) {
                outputClassDoc(cls, clsline, clsdesc);
                state = 1;
            } else {
                needAppend = 1;
            }
        } else if (endWithDocNote($NF)) {
            endDocNote = getEndDocNote($NF);
            if (endDocNote == beginDocNote) {
                clsdesc = clsdesc "\n" rtrimDocNote(rtrim($0));
                outputClassDoc(cls, clsline, clsdesc);
                state = 1;
            } else {
                needAppend = 1;
            }
        } else {
            needAppend = 1;
        }

        if (needAppend) {
            clsdesc = clsdesc "\n" $0;
        }
        break;
    }
    case 1:	#parse function
    {
      if ($1 == "def") {
        fn=removeBracket($2)
        fnline=$0
        state=2;
        desc="";
      }

      if ($1 == "class") {
        cls=removeBracket($2);
        clsline=$0;
        state=11;
        clsdesc=""
      }
      break;
    } 

    case 2:	#parse function doc begin
    { 
        if (isDocNote($1) && (NF == 1)) {
            beginDocNote = getDocNote($1);
            state=3;
        } else if (beginWithDocNote($1)) {
            beginDocNote = getBeginDocNote($1);
            if (endWithDocNote($NF)) {
                endDocNote = getEndDocNote($NF);
                if (beginDocNote == endDocNote) {
                    desc = "\n" rtrimDocNote(ltrimDocNote(rtrim(ltrim($0))));
                    outputFnDoc(fn, fnline, desc);
                    state = 1;
                } else {
                    desc = desc "\n" ltrimDocNote($0);
                }
            } else {
                desc = desc "\n" ltrimDocNote($0);
                state = 3;
            }
        }
        if ($1=="def") {
            fn=removeBracket($2)
            fnline=$0
            desc=""
        }
        if ($1 == "class") {
            outputNoDocFn(fn, fnline)
            cls=removeBracket($2);
            clsline=$0;
            state=11;
            clsdesc=""
        }
        break;
    }

    case 3:	#parse function doc and doc end
    {
        needAppend = 0
        if (isDocNote($1))
        {
            endDocNote = getDocNote($1);
            if (endDocNote == beginDocNote) {
                outputFnDoc(fn, fnline, desc);
                state = 1;
            } else {
                needAppend = 1;
            }
        } else if (endWithDocNote($NF)) {
            endDocNote = getEndDocNote($NF);
            if (endDocNote == beginDocNote) {
                desc = desc "\n" rtrimDocNote(rtrim($0));
                outputFnDoc(fn, fnline, desc);
                state = 1;
            } else {
                needAppend = 1;
            }
        } else {
            needAppend = 1;
        }

        if (needAppend) {
            desc=desc "\n" $0;
        }
        break;
    }
    default:
    {
    }
  }
}
