# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require misc
package require pld
package require ui
package require util

oo::singleton create App {
    variable Player
    variable ListTree
    variable TrackView
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
    lassign [$Pldb last_item] lid tid
    my populate_listtree $lid:$tid
}

oo::define App method play_track tid {
    set GotSecs 0
    set filename "" ;# TODO get from db using tid
    wm title . "[humanize_filename $filename] — [tk appname]"
    $Player play $filename
    #$config add_history $filename ;# TODO pld
    #my populate_history_menu    
}

oo::define App method populate_listtree {{sel_id "0:0"}} {
    $ListTree delete [$ListTree children {}]
    set prev_parent {}
    set prev_category ""
    set first ""
    foreach row [$Pldb lists] {
        lassign $row lid name
        set parent {}
        set category ""
        if {[set i [string first / $name]] != -1} {
            set category [string range $name 0 $i-1]
            set name [string range $name $i+1 end]
        }
        if {$category ne ""} {
            if {$category eq $prev_category} {
                set parent $prev_parent
            } else {
                set parent [$ListTree insert {} end -text $category]
                set prev_parent $parent
                set prev_category $category
            }
        }
        set playlist [$ListTree insert $parent end -id $lid -text $name]
        if {$first eq ""} { set first $playlist } ;# TODO $track
        foreach track [$Pldb tids_for_lid $lid] {
            puts $track
        }
        # TODO insert all the list's tracks as children of $playlist
        # using: -id L$lidT$tid and humanized names
    }
    if {$sel_id ne "" && $sel_id ne "0:0"} { set first $sel_id }
    if {$first ne "" && $first ne "0:0"} {
        $ListTree selection set $first
        $ListTree see $first
        $ListTree focus $first
    }
    focus $ListTree
}
