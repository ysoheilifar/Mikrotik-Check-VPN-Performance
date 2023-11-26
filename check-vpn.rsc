:log warning "----------ChackScriptSTART----------"
:local targetAddress "8.8.8.8"
:local targetAddress2 "1.1.1.1"
:local interfaces [/interface find where name~"vpn" and running=yes]
:local intzt [/interface find where type="zerotier"]
:local pingTimeDict ({})
:local intnameDict ({})
:local keyvaluearray ({})
:local timoutpingDict ({})

:local ztDictip ({"10.150.1.250";"10.150.1.79";"10.150.1.176";"10.150.1.30";"10.150.1.196";"10.150.1.189";"10.150.1.251";"10.150.1.126";"10.150.1.213";"10.150.1.177"})
:local ztDictname ({"London01";"Amesterdom01";"Amesterdom02";"Frankfurd01";"Frankfurd02";"Frankfurt03";"UEA01";"London03";"London04";"Spain02"})

:local ztDictallname ({})

:foreach int in=$interfaces do={
  :local interfaceName [:tostr [/interface get $int name]]
  :local pingrec 0
  :local pingresult 0
  :local pingtimepure 0
  :local pingtime 0
  :local index3 0
    :if ($int = $intzt) do={
        :foreach zt in=$ztDictip do={
            :local ztintname ($ztDictname->$index3)
            /ip route set [find where dst-address="$targetAddress2/32"] disabled=no;
            /ip route set [find where dst-address="$targetAddress2/32"] gateway=$zt;
            :delay 3s
            :set pingrec [/tool ping address=$targetAddress2 interface=$intzt count=1]
            :set pingresult [/tool ping address=$targetAddress2 interface=$intzt count=1 as-value]
            :set pingtimepure [:pick $pingresult 4]
            :set pingtime ([:pick $pingtimepure 9 20] / 1000)
            :if ($pingrec = 1) do={          
              :log info ("Ping Time on $interfaceName for $ztintname : " . $pingtime . " ms")
              :set pingTimeDict ($pingTimeDict, $pingtime)
              :set intnameDict ($intnameDict, $interfaceName."-".$ztintname)
              :set ztDictallname ($ztDictallname, $interfaceName."-".$ztintname)
            } else={
              :log error ("Ping Timeout on $interfaceName for $ztintname")
              :set timoutpingDict ($timoutpingDict, ($interfaceName."-".$ztintname))
            }
          :set index3 ($index3 + 1)
        }        
    } else={
        :set pingrec [/tool ping address=$targetAddress interface=$int count=1]
        :set pingresult [/tool ping address=$targetAddress interface=$int count=1 as-value]
        :set pingtimepure [:pick $pingresult 4]
        :set pingtime ([:pick $pingtimepure 9 20] / 1000)
        :if ($pingrec = 1) do={
          :log info ("Ping Time on $interfaceName: " . $pingtime . " ms")
          :set pingTimeDict ($pingTimeDict, $pingtime)
          :set intnameDict ($intnameDict, $interfaceName)
        } else={
          :log error ("Ping Timeout on $interfaceName")
          :set timoutpingDict ($timoutpingDict, $interfaceName)
        }
    }
}

:foreach o in=$timoutpingDict do={
  /ip route set [find comment=$o] disabled=yes
}

foreach p in=$intnameDict do={
    /ip route set [find comment=$p] disabled=no
}

/ip route set [find dst-address=1.1.1.1/32] disabled=yes
:log info $timoutpingDict

:log warning "----------CheckScriptEnD------------"