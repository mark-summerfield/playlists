# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require misc
package require ui

oo::singleton create App {
    variable Player
    variable TrackView
}

package require app_actions
package require app_ui

oo::define App constructor {} {
    ui::wishinit
    tk appname Playlists
    Config new ;# we need tk scaling done early
    set Player ""
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
    after idle [callback on_startup]
}

oo::define App method on_startup {} {
    set config [Config new]
    if {[set filename [$config last_track]] ne ""} {
        my maybe_new_dir $filename
    }
    focus $TrackView
}

oo::define App method maybe_new_dir filename {
    set dir [file dirname [file normalize $filename]]
    set home [file home](?:/\[Mm\]usic)?/?
    if {[set dir_label [regsub -- $home $dir ""]] ne \
            [.mf.dirLabel cget -text]} {
        .mf.dirLabel configure -text $dir_label
        $TrackView delete [$TrackView children {}]
        my PopulateTrackView [glob -directory $dir *.{mp3,ogg}]
    }
    catch {
        set name [to_id $filename]
        $TrackView selection set $name
        $TrackView see $name
    }
}

oo::define App method PopulateTrackView filenames {
    set width 0
    set n 0
    foreach name [lsort -dictionary $filenames] {
        set track [humanize_trackname $name]
        if {[set w [string length $track]] > $width} { set width $w }
        $TrackView insert {} end -id [to_id $name] -text "[incr n]. " \
            -values [list $track]
    }
    if {[set width [font measure TkDefaultFont [string repeat W $width]]] \
            > [$TrackView column 0 -minwidth]} {
        $TrackView column 0 -minwidth $width
    }
}

oo::define App method play_track filename {
    set filename [from_id $filename]
    set config [Config new]
    $config set_last_track $filename
    wm title . "[humanize_filename $filename] — [tk appname]"
    my maybe_new_dir $filename
    $Player play $filename
    $config add_history $filename
    my populate_history_menu    
}
