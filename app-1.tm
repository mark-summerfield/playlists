# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require misc
package require pld
package require ui
package require util

oo::singleton create App {
    variable Player
    variable ListTree
    variable TrackTree
    variable GotSecs
    variable Pldb
}

package require app_actions
package require app_ui

oo::define App constructor {} {
    ui::wishinit
    tk appname Playlists
    set config [Config new] ;# we need tk scaling done early
    set Pldb [Pld new [get_db_filename]]
    set Player ""
    set GotSecs 0
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
    if {[set sashpos [$config sashpos]]} { .mf.pw sashpos 0 $sashpos }
    my populate {*}[$Pldb last_item]
}

oo::define App method play_track tid {
    set GotSecs 0
    lassign [$Pldb track_for_tid $tid] filename secs
    if {$filename ne ""} {
        if {$secs} { set GotSecs 1 }
        wm title . "[humanize_trackname $filename] — [tk appname]"
        $Player play $filename
        #$config add_history $filename ;# TODO pld
        #my populate_history_menu    
    }
}

oo::define App method populate {{sel_lid 0} {sel_tid 0}} {
    my populate_listtree $sel_lid
    my populate_tracktree $sel_lid $sel_tid
}

oo::define App method populate_listtree {{sel_lid 0}} {
    $ListTree delete [$ListTree children {}]
    foreach row [$Pldb categories] {
        lassign $row cid name
        $ListTree insert {} end -id C$cid -text $name
    }
    foreach row [$Pldb lists] {
        lassign $row cid lid name
        if {!$sel_lid} { set sel_lid $lid }
        $ListTree insert C$cid end -id L$lid -text $name
    }
    if {$sel_lid} { select_tree_item $ListTree L$sel_lid }
}

oo::define App method populate_tracktree {lid {sel_tid 0}} {
    $TrackTree delete [$TrackTree children {}]
    set n 0
    foreach row [$Pldb tracks_for_lid $lid] {
        lassign $row tid filename secs
        set secs [expr {$secs ? [humanize_secs $secs] : ""}]
        $TrackTree insert {} end -id $lid:$tid -text [incr n]. \
            -values [list [humanize_trackname $filename] $secs]
        if {!$sel_tid} { set sel_tid $tid }
    }
    if {$n} {
        select_tree_item $TrackTree $lid:$sel_tid
        focus $TrackTree
    } else {
        focus $ListTree
    }
}
