# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require misc
package require ui
package require util

oo::singleton create App {
    variable Player
    variable ListTree
    variable TrackView
    variable GotSecs
    variable Db
}

package require app_actions
package require app_ui

oo::define App constructor {} {
    ui::wishinit
    tk appname Playlists
    set config [Config new] ;# we need tk scaling done early
    set pld [regsub {.ini$} [util::get_ini_filename] .pld]
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
    puts on_startup ;# TODO select last category/playlist/track from pld
}

oo::define App method play_track filename {
    set GotSecs 0
    set filename [from_id $filename]
    wm title . "[humanize_filename $filename] — [tk appname]"
    $Player play $filename
    #$config add_history $filename ;# TODO pld
    #my populate_history_menu    
}
