# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::singleton create Mplayer {
    variable Stream
    variable Debug
    variable Exe
}

oo::define Mplayer constructor {} {
    set Stream ""
    set Debug 0
    if {[set Exe [auto_execok mplayer]] ne ""} { my open }
}

oo::define Mplayer method open {} {
    if {$Stream eq ""} {
        set Stream [open "|$Exe -slave -idle -input nodefault-bindings \
                    -noconfig all" r+]
        fconfigure $Stream -blocking 0 -buffering line
        fileevent $Stream readable [callback ReadPipe]
    }
}

oo::define Mplayer method close {} {
    if {$Stream ne ""} {
        my stop
        flush $Stream
        fileevent $Stream readable {}
        close $Stream
        set Stream ""
    }
}

oo::define Mplayer method has_mplayer {} { expr {$Exe ne ""} }

oo::define Mplayer method closed {} { expr {$Stream eq ""} }

oo::define Mplayer method replay {} { my Do "set_property time_pos 0" }

oo::define Mplayer method play filename {
    my stop
    after 200        
    my Do "loadfile \"$filename\""
}

oo::define Mplayer method pause {} { my Do pause }

oo::define Mplayer method stop {} { my Do stop }

oo::define Mplayer method volume_down {} { my Do "volume -5" }

oo::define Mplayer method volume_up {} { my Do "volume +5" }

oo::define Mplayer method Do action { puts $Stream $action ; flush $Stream }

oo::define Mplayer method ReadPipe {} {
    foreach line [split [read $Stream] \n] {
        if {[set line [string trim $line]] ne ""} {
            if {[regexp {^A:\s*(\d+.\d+).*?of\s*(\d+.\d+)} $line _ pos \
                    total]} {
                event generate . <<MplayerPos>> -data "$pos $total"
            } elseif {$Debug} {
                event generate . <<MplayerDebug>> -data "$line"
            }
        }
    }
    if {[eof $Stream]} {
        fileevent $Stream readable {}
        close $Stream
        set Stream ""
    }
}

oo::define Mplayer method debug {} { return $Debug }
oo::define Mplayer method set_debug debug { set Debug $debug }
