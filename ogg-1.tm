# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval ogg {}

proc ogg::metadata filename {
    if {![regexp -nocase {^.*.og[ga]$} $filename]} {
        return [list 0 "" ""] ;# secs title artist
    }
    set title ""
    set artist ""
    set rate 0
    set length 0
    set fh [open $filename rb]
    try {
        while {1} {
            set data [chan read $fh 4280]
            if {$title eq ""} {
                regexp -nocase {TITLE=([^$\x00-\x1F]+)} $data _ title
                set title [FixText $title]
            }
            if {$artist eq ""} {
                regexp -nocase {ARTIST=([^$\x00-\x1F]+)} $data _ artist
                set artist [FixText $artist]
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
    if {[regexp -nocase {^(?:Track\M|Side\s[A-Z])} $title]} { set title "" }
    if {!$rate || !$length} { return [list 0 $title $artist] }
    list [expr {int(round($length / double($rate)))}] $title $artist
}

proc ogg::FixText txt {
    set txt [string trim [encoding convertfrom utf-8 $txt]]
    set txt [regsub -all {\s'} $txt ‘]
    set txt [regsub -all ' $txt ’]
    set txt [regsub -all {\s\"} $txt " “"]
    set txt [regsub -all {\"} $txt ”]
    string trim [string trim $txt "\"'/\\$&%#+,;"]
}

if {[string match *.tm $::argv0]} {
    foreach filename $::argv {
        if {[file isfile $filename]} {
            lassign [ogg::metadata $filename] secs title artist
            puts "[file tail $filename] «$title» by «$artist» ${secs}s"
        }
    }
}
