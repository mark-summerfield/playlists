# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval ogg {}

proc ogg::duration_in_secs filename {
    if {![regexp {^.*.(?:ogg|oga)$} $filename]} { return 0 }
    set fh [open $filename rb]
    set rate 0
    set length 0
    try {
        while {1} {
            set data [chan read $fh 4080]
            if {$data eq ""} { break }
            if {[set i [string first "vorbis" $data]] != -1} {
                incr i 11
                binary scan [string range $data $i $i+3] iu rate
                break
            }
            seek $fh -20 current
        }
        seek $fh -4020 end
        while {1} {
            set data [chan read $fh 4020]
            if {$data eq ""} { break }
            if {[set i [string last "OggS" $data]] != -1} {
                binary scan [string range $data $i+6 $i+13] wu length
                break
            }
            seek $fh -8000 current
        }
    } finally {
        close $fh
    }
    if {!$rate || !$length} { return 0 }
    expr {int(round($length / double($rate)))}
}
