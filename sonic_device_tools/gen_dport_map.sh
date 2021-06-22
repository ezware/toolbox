#!/bin/bash

#get phy port order from pannel port list
PHY_PORT_ORDER=$(show interfaces status | grep -E '[0-9]' | awk -F, '{print $1}' | awk '{print $2}')

#gen port2logic dict from portmap
eval $(bcmcmd "show portmap" | grep -v cpu | grep -v lb[0-9] | grep [0-9] | awk '{printf("PORT2LOGIC[%d]=%d\n", $4, $3)}')

#get logical port from port2logic dict
function findLogicalPortByPhyPort() {
    local phyPort=$1
    eval "echo \${PORT2LOGIC[$phyPort]}"
}

#gen dport_map_port
function genDPortMap() {
  #gen header
  echo -e "---\nbcm_device:\n    0:\n        port:"

  #gen map
  prefix1="            "
  prefix2="                "

  i=1

  #gen pannel port map
  for port in $PHY_PORT_ORDER
  do
    lport=$(findLogicalPortByPhyPort "$port")
    #echo $lport
    printf "%s%d:\n%sdport_map_port: %d\n" "$prefix1" "$lport" "$prefix2" "$i"
    ((i++))
  done

  # gen inner port map
  lblports=$(bcmcmd "show portmap" | grep lb[0-9] | awk '{print $3}')

  for lport in $lblports
  do
    printf "%s%d:\n%sdport_map_port: %d\n" "$prefix1" "$lport" "$prefix2" "$i"
    ((i++))
  done

  #gen footer
  echo "..."
}

genDPortMap

