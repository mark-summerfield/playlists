# Copyright © 2025 Mark Summerfield. All rights reserved.

package require lambda 1
package require util

const STARS3 "#0000FF" ;# blue
const STARS2 "#009A00" ;# green
const STARS1 "#9A6324" ;# brown
const STARS0 "#707070" ;# gray

proc select_tree_item {tree id} {
    if {[llength [$tree children {}]]} {
        if {[$tree exists $id]} {
            $tree selection set $id
            $tree see $id
            $tree focus $id
        }
    }
}

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

proc humanize_trackname {filename {name ""}} {
    if {$name ne ""} { return $name }
    set name [file tail [file rootname $filename]]
    set name [string trim [string trimleft $name "0123456789"]]
    humanize_name $name
}

proc humanize_dirname dirname {
    humanize_name [lindex [file split $dirname] end]
}

proc humanize_name name {
    set name [regsub -all -command \
        {\s(?:And|A[ns]|A|I[ns]|But|For|O[fn]|The|To)\s} $name \
        [lambda s { string tolower $s }]]
    set name [regsub -all {'\s} $name "’ "]
    set name [regsub -all {\s'} $name " ‘"]
    string trim [regsub -all {[-_. ]+} $name " "]
}

proc get_music_dir {{filename ""}} {
    if {$filename ne ""} {
        set dir [file dirname $filename]
    } else {
        set home [file home]
        catch { set dir [exec xdg-user-dir MUSIC] }
        if {[info exists dir] && $dir ne "" \
                && [string trimright $dir /] ne [string trimright $home /] \
                && [file isdirectory $dir]} {
            return $dir
        }
        set dir $home/Music
        if {![file isdirectory $dir]} {
            set dir $home/music
            if {![file isdirectory $dir]} {
                set dir $home
            }
        }
    }
    return $dir
}

proc get_db_filename {} {
    regsub {.ini$} [util::get_ini_filename] -[info hostname].pld
}
