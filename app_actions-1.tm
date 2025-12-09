# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config_form
package require misc
package require ref

oo::define App method on_file_open {} {
    const filetypes {{{Audio Files} {.mp3 .ogg}}}
    set filename [[Config new] last_track]
    set dir [get_music_dir $filename]
    set filename [tk_getOpenFile -parent . -filetypes $filetypes \
                  -initialdir $dir]
    if {$filename ne ""} {
        my play_track $filename
    }
}

oo::define App method on_play_prev {} {
    if {[set prev [$TrackView prev [$TrackView selection]]] ne ""} {
        $TrackView selection set $prev
        $TrackView see $prev
        my play_track $prev
    }
}

oo::define App method on_play_replay {} { $Player replay }

oo::define App method on_play_pause_resume {} { $Player pause }

oo::define App method on_play {} {
    if {[set selection [$TrackView selection]] ne ""} {
        my play_track $selection
    }
}

oo::define App method on_play_next {} {
    if {[set next [$TrackView next [$TrackView selection]]] ne ""} {
        $TrackView selection set $next
        $TrackView see $next
        my play_track $next
    }
}

oo::define App method on_volume_down {} {
    if {$Player ne ""} { $Player volume_down }
}

oo::define App method on_volume_up {} {
    if {$Player ne ""} { $Player volume_up }
}

oo::define App method on_history_remove {} {
    if {[set selection [$TrackView selection]] ne ""} {
        [Config new] remove_history [from_id $selection]
        my populate_history_menu
    }
}

oo::define App method on_bookmarks_add {} {
    if {[set selection [$TrackView selection]] ne ""} {
        [Config new] add_bookmark [from_id $selection]
        my populate_bookmarks_menu
    }
}

oo::define App method on_bookmarks_remove {} {
    if {[set selection [$TrackView selection]] ne ""} {
        [Config new] remove_bookmark [from_id $selection]
        my populate_bookmarks_menu
    }
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new 0]
    set debug [Ref new [$Player debug]]
    set form [ConfigForm new $ok $debug]
    tkwait window [$form form]
    if {[$ok get]} {
        $Player set_debug [$debug get]
    }
}

oo::define App method on_about {} {
    AboutForm new "Play tracks" \
        https://github.com/mark-summerfield/playtrack-tcl
}

oo::define App method on_quit {} {
    $Player close 
    [Config new] save
    exit
}
