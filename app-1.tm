# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require pld
package require ui

oo::singleton create App {
    variable Player
    variable ListTree
    variable TrackTree
    variable Pldb
    variable GotSecs
}

package require app_actions
package require app_category_actions
package require app_list_actions
package require app_play_actions
package require app_populate
package require app_track_actions
package require app_ui

oo::define App constructor {} {
    ui::wishinit
    tk appname Playlists
    Config new ;# we need tk scaling done early
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
    my populate_listtree $lid
    after idle [list select_tree_item $TrackTree $lid:$tid]
}

oo::define App method get_current_lid {} {
    if {[set lid [$ListTree selection]] ne ""} {
        if {[string match C* $lid]} { return }
        return [string trimleft $lid L]
    }
}

oo::define App method play_track ttid {
    lassign [split $ttid :] lid tid
    lassign [$Pldb track_for_tid $tid] filename _
    my play_db_track $lid $tid $filename
}

oo::define App method play_db_track {lid tid filename {goto false}} {
    if {$filename ne ""} {
        if {$goto} { my goto_track $lid $tid $filename }
        set GotSecs 0
        wm title . "[humanize_trackname $filename] — [tk appname]"
        $Player play $filename
        $Pldb history_insert $lid $tid
        after idle [callback populate_history_menu]
    }
}

oo::define App method goto_track {lid tid filename} {
    if {[$ListTree selection] ne "L$lid"} {
        set done 0
        foreach tcid [$ListTree children {}] {
            foreach tlid [$ListTree children $tcid] {
                if {$tlid eq "L$lid"} {
                    $ListTree selection set L$lid
                    set done 1
                    break
                }
            }
            if {$done} { break }
        }
    }
    after idle [list select_tree_item $TrackTree $lid:$tid]
}
