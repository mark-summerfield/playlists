# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require pld
package require ui

oo::singleton create App {
    variable Player
    variable ListTree
    variable ListTreeExpanded
    variable ListTreeContextMenu
    variable TrackTree
    variable Pldb
    variable GotSecs
}

package require app_actions
package require app_bookmarks_actions
package require app_category_actions
package require app_file_actions
package require app_history_actions
package require app_list_actions
package require app_play_actions
package require app_populate
package require app_track_actions
package require app_ui

oo::define App constructor {} {
    ui::wishinit
    tk appname Playlists
    Config new ;# we need tk scaling done early
    set ListTreeExpanded 0
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
    if {$tid} { after idle [list select_tree_item $TrackTree $lid:$tid] }
    if {![$Pldb has_tracks]} {
        after idle [callback maybe_add_tracks]
    }
}

oo::define App method get_current_lid {} {
    if {[set lid [$ListTree selection]] ne ""} {
        if {[string match C* $lid]} { return }
        return [string range $lid 1 end]
    }
}

oo::define App method play_track ttid {
    lassign [split $ttid :] lid tid
    lassign [$Pldb track_for_tid $tid] filename _
    my play_db_track $lid $tid $filename
}

oo::define App method play_db_track {lid tid filename {goto 0}} {
    if {$filename ne ""} {
        if {$goto} { my goto_track $lid $tid $filename }
        set GotSecs 0
        $Pldb history_insert $lid $tid
        wm title . "[humanize_trackname $filename] — [tk appname]"
        $Player play $filename
    }
}

oo::define App method play_saved_track {lid tid filename {goto 0} \
        {history 0}} {
    if {[$Pldb track_exists $lid $tid]} {
        my play_db_track $lid $tid $filename $goto
    } elseif {$history} {
        $Pldb history_delete $lid $tid
        my populate_history_menu
    } else {
        $Pldb bookmarks_delete $lid $tid
        my populate_bookmarks_menu
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
