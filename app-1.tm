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
    tk appname PlayTrack
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
    if {[set dir [file dirname [file normalize $filename]]] ne \
            [.mf.dirLabel cget -text]} {
        .mf.dirLabel configure -text $dir
        $TrackView delete [$TrackView children {}]
        foreach name [lsort -dictionary \
                      [glob -directory $dir *.{mp3,ogg}]] {
            $TrackView insert {} end -id $name \
                -text [humanize_filename $name]
        }
        catch {
            $TrackView selection set $filename
            $TrackView see $filename
        }
    }
}

oo::define App method play_track filename {
    [Config new] set_last_track $filename
    wm title . "[humanize_filename $filename] — [tk appname]"
    my maybe_new_dir $filename
    $Player play $filename
}
