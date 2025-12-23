# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval ogg {}

proc ogg::duration_in_secs_and_title filename {
    if {![regexp -nocase {^.*.(?:ogg|oga)$} $filename]} {
        return [list 0 ""] ;# secs title
    }
    set title ""
    set rate 0
    set length 0
    set fh [open $filename rb]
    try {
        while {1} {
            set data [chan read $fh 4280]
            if {$title eq ""} {
                regexp -nocase {TITLE=([^$\x00-\x1F]+)} $data _ title
                set title [encoding convertfrom utf-8 $title]
                set title [string trim [string trim $title "\"$&"]]
                set title [regsub -all {\s'} $title ‘]
                set title [regsub -all ' $title ’]
            }
            set size [string length $data]
            set i [string first "vorbis" $data]
            if {$i > -1 && $i+14 < $size} {
                binary scan [string range $data $i+11 $i+14] iu rate
                break
            }
            if {$size < 4280} { break }
            seek $fh -200 current
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
    if {[string match -nocase "Track *" $title]} { set title "" }
    if {!$rate || !$length} { return [list 0 $title] }
    list [expr {int(round($length / double($rate)))}] $title
}

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

if {[string match *.tm $::argv0]} {
    foreach filename $::argv {
        if {[file isfile $filename]} {
            lassign [ogg::duration_in_secs_and_title $filename] secs title
            puts "[file tail $filename] “$title” $secs secs"
        }
    }
}
