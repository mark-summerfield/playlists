# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::singleton create Mplayer {
    variable Pipe
    variable Playing
    variable Pos
    variable Debug
    variable Exe
}

oo::define Mplayer initialize {
    variable FILETYPES
    const FILETYPES {{{Audio Files} {.mp3 .ogg}}}
}

oo::define Mplayer classmethod filetypes {} {
    variable FILETYPES
    return $FILETYPES
}

oo::define Mplayer constructor {} {
    set Pipe ""
    set Playing 0
    set Pos 0.0
    set Debug 0
    if {[set Exe [auto_execok mplayer]] ne ""} { my open }
}

oo::define Mplayer method open {} {
    if {$Pipe eq ""} {
        set Pipe [open "|$Exe -slave -idle -input nodefault-bindings \
                  -noconfig all" r+]
        fconfigure $Pipe -blocking 0 -buffering line
        fileevent $Pipe readable [callback ReadPipe]
    }
}

oo::define Mplayer method close {} {
    if {$Pipe ne ""} {
        my stop
        flush $Pipe
        fileevent $Pipe readable {}
        close $Pipe
        set Pipe ""
    }
}

oo::define Mplayer method has_mplayer {} { expr {$Exe ne ""} }

oo::define Mplayer method closed {} { expr {$Pipe eq ""} }

oo::define Mplayer method play filename {
    my stop
    after 100        
    my Do "loadfile \"$filename\""
    set Playing 1
}

oo::define Mplayer method replay {} { my Do "set_property time_pos 0" }

oo::define Mplayer method pause {} { my Do pause }

oo::define Mplayer method stop {} { set Playing 0 ; my Do stop }

oo::define Mplayer method volume_down {} { my Do "volume -5" }

oo::define Mplayer method volume_up {} { my Do "volume +5" }

oo::define Mplayer method Do action { puts $Pipe $action ; flush $Pipe }

oo::define Mplayer method ReadPipe {} {
    foreach line [split [read $Pipe] \n] {
        if {[set line [string trim $line]] ne ""} {
            if {[regexp {^A:\s*(\d+.\d+).*?of\s*(\d+.\d+)} $line _ pos \
                    total]} {
                if {[set rpos [expr {round($pos * 5) / 5.0}]] != $Pos} {
                    set Pos $rpos ;# Every ⅕th sec (200ms).
                    if {$Playing} {
                        if {$pos + 1 >= $total} {
                            set Playing 0
                            event generate . <<MplayerPos>> \
                                -data "$total $total"
                            my Do stop
                            event generate . <<MplayerStopped>>
                        } else {
                            event generate . <<MplayerPos>> \
                                -data "$pos $total"
                        }
                    }
                }
            } elseif {$Debug} {
                event generate . <<MplayerDebug>> -data "$line"
            }
        }
    }
    if {[eof $Pipe]} {
        fileevent $Pipe readable {}
        close $Pipe
        set Pipe ""
    }
}

oo::define Mplayer method debug {} { return $Debug }
oo::define Mplayer method set_debug debug { set Debug $debug }
