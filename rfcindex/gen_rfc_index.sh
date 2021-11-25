#!/bin/bash

function getDownloader {
    local fn="$1"

    which wget
    if [ $? -eq 0 ]; then
        if [ ! -z $fn ]; then
            echo "wget --no-check-certificate -O"
        else
            echo "wget --no-check-certificate"
        fi
        return
    fi

    which curl
    if [ $? -eq 0 ]; then
        if [ ! -z $fn ]; then
            echo "curl -o"
        else
            echo "curl -O -"
        fi
        return
    fi

    return
}
#$1 url
#$2 filename, optional
function getFile {
    local url="$1"
    local fn="$2"
    local dl=""

    dl=$(getDownloader "$fn")
    if [ -z $dl ]; then
        echo "No download tool, wget or curl needed"
        exit 1
    fi

    $dl "$fn" "$url"
}

if [ ! -f "rfc-index.txt" ]; then
    getFile "https://www.rfc-editor.org/rfc-index.txt"
    getFile "https://www.rfc-editor.org/in-notes/tar/RFC-all.zip"
fi

output="index.html"

echo -n "" >$output

echo '
<html>
    <head>
    <title>RFC Index</title>
    <script src="vue.js"></script>
    <style>
        body, div, li {
            padding: 6px;
            font-family: "Consolas";
            font-size: 18px;
        }
    </style>
    <meta content="text/html; charset=utf-8" http-equiv="content-type">
    </head>

    <body onload = "javascript:init()">
        <div id="app">
            <span>最大结果数：</span><input v-model="maxcnt" size=5></input>
            &nbsp;
            <span>搜索关键字或RFC编号：</span><input v-model="key" @keyup="keyup"></input>
            <div><ul><li v-for="r in results" v-html="r"></li></ul></div>
        </div>

        <script language = "javascript">
            function init()
            {
                const rfcindex = {
                    data() {
                        return this.getData()
                    },
                    methods: {
                    keyChanged()
                    {
                        rfc=this.rfc
                        key=this.key
                        cnt=rfc.length
                        results2=[]
                        j = 0

                        found=key.match(/^rfc[0-9]+/i)
                        if (found != null)
                        {
                            key = key.replace(/^rfc/i, "")
                        }

                        if (!isNaN(key))
                        {
                            if ((key <= cnt) && (key > 0))
                            {
                                i = key - 1;
                                if (rfc[i].index == key)
                                {
                                    results2.push("<a href=\"txt/rfc" + rfc[i].index + ".txt\">rfc" + rfc[i].index + "</a> " + rfc[i].desc)
                                    results2.push("<hr/>")
                                }
                            }
                        }

                        for (i = cnt - 1; i >= 0; i--)
                        {
                            if ((rfc[i].index == this.key) || (rfc[i].desc.search(this.key)>=0))
                            {
                                results2.push("<a href=\"txt/rfc" + rfc[i].index + ".txt\">rfc" + rfc[i].index + "</a> " + rfc[i].desc)
                                j++;

                                if (j > this.maxcnt)
                                {
                                    break
                                }
                            }
                        }
                        this.results = results2
                    },
                    keyup()
                    {
                        setTimeout(this.keyChanged, 1000);
                    },
                    getData()
                    {
                        return { maxcnt: 15, results: [], rfc: [
        ' >> ${output}


sed 's/\r//' rfc-index.txt | awk '
function esc(s)
{
    gsub("\"","\\\"", s)
    return s
}

BEGIN {
    isfirst=1
    cnt=0
}
{
    if ($0 ~/^[0-9]+/)
    {
        cnt++
        if (isfirst)
        {
            printf("\t\t\t\t{index: %d, desc: \"%s", $1, esc($0))
            isfirst = 0
        }
        else
        {
            printf("\"},\n\t\t\t\t{index: %d, desc: \"%s", $1, esc($0))
        }
    }
    else
    {
        if (!isfirst)
        {
            for (i=1; i <= NF; i++)
            {
                printf(" %s", esc($i))
            }
        }
    }
} END {
    if (cnt)
    {
        printf("\"}\n")
    }
}' >>${output}

echo -e '
                ]
            } //end of rfc
            } //end of getData
            } //end of methods
            } //end of rfcindex
                Vue.createApp(rfcindex).mount("#app")
        }
        </script>
    </body>
</html>
' >>${output}

