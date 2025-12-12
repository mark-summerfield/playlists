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
package require app_play_actions
package require app_populate
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

oo::define App method get_current_lid {} {
    if {[set lid [$ListTree selection]] ne ""} {
        if {[string match C* $lid]} { return }
        return [string trimleft $lid L]
    }
}

oo::define App method play_track ttid {
    set GotSecs 0
    lassign [split $ttid :] lid tid
    lassign [$Pldb track_for_tid $tid] filename secs
    if {$filename ne ""} {
        if {!$GotSecs && $secs} {
            $Pldb track_update_secs $tid $secs
            set GotSecs 1
        }
        $Pldb history_insert $lid $tid
        wm title . "[humanize_trackname $filename] — [tk appname]"
        $Player play $filename
    }
}
