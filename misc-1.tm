# Copyright © 2025 Mark Summerfield. All rights reserved.

proc humanize_secs secs {
    if {![set secs [expr {int(round($secs))}]]} {
        return "0s"
    }
    lassign [divmod $secs 3600] hours secs
    lassign [divmod $secs 60] mins secs
    set parts [list]
    if {$hours} { lappend parts "${hours}h" }
    if {$mins} { lappend parts "${mins}m" }
    if {$secs || ![llength $parts]} { lappend parts "${secs}s" }
    join $parts ""
}

proc divmod {n div} {
    set d [expr {$n / $div}]
    set m [expr {$n % $div}]
    list $d $m
}

proc humanize_trackname filename {
    set name [file tail [file rootname $filename]]
    set name [string trim [string trimleft $name "0123456789"]]
    string trim [regsub -all {[-_.]} $name " "]
}

proc get_music_dir filename {
    if {$filename ne ""} {
        set dir [file dirname $filename]
    } else {
        set home [file home]
        set dir $home/Music
        if {![file exists $dir]} {
            set dir $home/music
            if {![file exists $dir]} {
                set dir $home
            }
        }
    }
    return $dir
}

proc get_db_filename {} {
    set home [file home]
    set dir $home/data
    if {![file exists $dir]} {
        set dir $home
    }
    return $dir/[info hostname].pld
}
