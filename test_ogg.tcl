#!/usr/bin/env tclsh9

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require ogg

proc main {} {
    foreach filename $::argv {
        set secs [ogg::duration_in_secs $filename]
        puts "[file tail $filename] $secs secs"
    }
}

main
