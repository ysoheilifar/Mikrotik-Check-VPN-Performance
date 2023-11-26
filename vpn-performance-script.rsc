:log warning "----------ScriptSTART----------"
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
            :log info $zt
            :delay 3s
            :set pingrec [/tool ping address=$targetAddress2 interface=$intzt count=1]
            :log info $pingrec
            :set pingresult [/tool ping address=$targetAddress2 interface=$intzt count=1 as-value]
            :log info $pingresult
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

:log info $pingTimeDict
:log info $intnameDict

:local max ($pingTimeDict->0)
:local min ($pingTimeDict->0)

:foreach i in=$pingTimeDict do={
  :if ($i > $max) do={:set max $i}
  :if ($i < $min) do={
    :set min $i
  }
}

:log info "max ping time = $max"
:log info "min ping time = $min"

:local intnameDictSort $intnameDict;
:local A;
:local pingTimeDictSort $pingTimeDict;
:local B;
:local n [ :len $pingTimeDictSort ];
:local swapped;
:put "Before unsorted $pingTimeDictSort";
do {
    :set swapped false;
    :for i from=1 to=($n - 1) do={
        :if ([ :pick $pingTimeDictSort ($i - 1) ]  > [ :pick $pingTimeDictSort $i ]) do={
            :set B [ :pick $pingTimeDictSort ($i - 1) ];
            :set A [ :pick $intnameDictSort ($i - 1) ];
            :set $pingTimeDictSort ([ :pick $pingTimeDictSort 0 ($i - 1) ], [ :pick $pingTimeDictSort $i ], $B, [ :pick $pingTimeDictSort ($i + 1) [ :len $pingTimeDictSort ] ]);
            :set $intnameDictSort ([ :pick $intnameDictSort 0 ($i - 1) ], [ :pick $intnameDictSort $i ], $A, [ :pick $intnameDictSort ($i + 1) [ :len $intnameDictSort ] ]);
            :set swapped true;
        }
    }
    :set n ($n - 1);
} while=($swapped);

:log info $pingTimeDict
:log info $pingTimeDictSort
:log info $intnameDictSort
:local lenpingDictSort [:len $pingTimeDictSort]
:local lenintnameDict [:len $intnameDict]
:local lenintnameDictSort [:len $intnameDictSort]

:log info "Length pingDictSort: $lenpingDictSort"
:log info "Length intnameDict: $lenintnameDict"
:log info "Length intnameDictSort: $lenintnameDictSort"

:foreach key in=$intnameDictSort do={
  :local value [:pick $pingTimeDictSort [:find $intnameDictSort $key]]
  :set keyvaluearray ( $keyvaluearray, [:tostr $key] . "=" . [:tostr $value] )
}

:local lenkeyvaluearray [:len $keyvaluearray]
:log info "Length keyvaluearray: $lenkeyvaluearray"

:log info $keyvaluearray

:local bestintname ($intnameDictSort->0)
:local lenintnameDictSort2 ($lenintnameDictSort - 1)
:local badintname ($intnameDictSort->$lenintnameDictSort2)
:log info "Best interface is $bestintname"
:log info "BAD interface is $badintname"

:local ztDictallnameSort ({})
:local ztDictnameSort ({})
:local splitItem ({})
:local splitItem2 ({})

:foreach j in=$intnameDictSort do={
  :foreach k in=$ztDictallname do={
    :if ($j = $k) do={
      :set ztDictallnameSort ($ztDictallnameSort, $k)
      :set splitItem [:pick $k ([:find $k "-"]+1) [:len $k]]
      :set splitItem2 [:pick $splitItem ([:find $splitItem "-"]+1) [:len $splitItem]]
      :set ztDictnameSort ($ztDictnameSort, $splitItem2)
    }
  }
}

:log info $ztDictallname
:log info $ztDictallnameSort
:log info $ztDictnameSort

:local ztDictipSort ({})

:foreach r in=$ztDictnameSort do={
  :local index4 0
  :foreach n in=$ztDictname do={
    :if ($r = $n) do={
      :set ztDictipSort ($ztDictipSort, ($ztDictip->$index4))
    }
  :set index4 ($index4 + 1)
  }
}

:log info $ztDictipSort

:local iparray ({})
:local index5 0

:foreach l in=$intnameDictSort do={
  :local found false
  :foreach m in=$ztDictallnameSort do={
    :if ($l = $m) do={
      :set iparray ($iparray, ($ztDictipSort->$index5))
      :set index5 ($index5 + 1)
      :set found true
    }
  }
  :if ($found=false) do={
    :set iparray ($iparray, [/ip address get [find where interface=$l] network])
  }
}

:local leniparray [:len $iparray]

:log info $intnameDictSort
:log info $iparray
:log info "Length iparray: $leniparray"

:local keyvaluearray2 ({})

:foreach key2 in=$intnameDictSort do={
  :local value2 [:pick $iparray [:find $intnameDictSort $key2]]
  :set keyvaluearray2 ( $keyvaluearray2, [:tostr $key2] . "=" . [:tostr $value2] )
}

:local lenkeyvaluearray2 [:len $keyvaluearray2]

:log info "Length keyvaluearray2: $lenkeyvaluearray2"
:log info $keyvaluearray2

:local dist 10

:foreach m in=$iparray do={
  /ip route set [find where routing-table=VPN and gateway=$m] distance=$dist;
  /ip route set [find where routing-table=VPN and gateway=$m] disabled=no;
  :set dist ($dist + 1);
}

/ip route set [find dst-address=1.1.1.1/32] disabled=yes

:foreach o in=$timoutpingDict do={
  /ip route set [find comment=$o] disabled=yes
}

:local lentimoutpingDict [:len $timoutpingDict]

:log info $timoutpingDict
:log info "Number of enabled VPN: $leniparray"
:log info "Number of disabled VPN: $lentimoutpingDict"

:log warning "----------ScriptEnD------------"o