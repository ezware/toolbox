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

function outputFnLine(fnline) {
    pos=sub("[ ]*", "", fnline);
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

        if ($1 == "\"\"\"") {
            state = 12;
        }
        break;
    }
    case 12:	#parse class doc and doc end
    {
        if ($1 == "\"\"\"") {
            outputClassDoc(cls, clsline, clsdesc);
            state = 1;
        } else {
            clsdesc=clsdesc "\n" $0;
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
        if ($1=="\"\"\"") {
            state=3;
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
        if ($1=="\"\"\"")
        {
            outputFnDoc(fn, fnline, desc)
            state=1
        } else {
            desc=desc "\n" $0;
        }
        break;
    }
    default:
    {
    }
  }
}
