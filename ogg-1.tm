# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval ogg {}

proc ogg::duration_in_secs filename {
    if {![regexp -nocase {^.*.(?:ogg|oga)$} $filename]} { return 0 }
    set rate 0
    set length 0
    set fh [open $filename rb]
    try {
        while {1} {
            set data [chan read $fh 4080]
            set size [string length $data]
            set i [string first "vorbis" $data]
            if {$i > -1 && $i+14 < $size} {
                binary scan [string range $data $i+11 $i+14] iu rate
                break
            }
            if {$size < 4080} { break }
            seek $fh -20 current
        }
        seek $fh -4020 end
        while {1} {
            set data [chan read $fh 4020]
            set size [string length $data]
            set i [string last "OggS" $data]
            if {$i > -1 && $i+13 < $size} {
                binary scan [string range $data $i+6 $i+13] wu length
                break
            }
            if {$size < 4020} { break }
            seek $fh -8000 current
        }
    } finally {
        close $fh
    }
    if {!$rate || !$length} { return 0 }
    expr {int(round($length / double($rate)))}
}
