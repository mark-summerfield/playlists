# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config_form
package require misc
package require ref

oo::define App method on_play_prev {} {
    if {[set prev [$TrackTree prev [$TrackTree selection]]] ne ""} {
        $TrackTree selection set $prev
        $TrackTree see $prev
        my play_track $prev
    }
}

oo::define App method on_play_skip_back {} {
    set config [Config new]
    $Player skip_back [$config skip_by]
}

oo::define App method on_play_replay {} { $Player replay }

oo::define App method on_play_pause_resume {} { $Player pause }

oo::define App method on_play {} {
    if {[set selection [$TrackTree selection]] ne ""} {
        my play_track $selection
    }
}

oo::define App method on_play_skip_forward {} {
    set config [Config new]
    $Player skip_forward [$config skip_by]
}

oo::define App method on_play_next {} {
    if {[set next [$TrackTree next [$TrackTree selection]]] ne ""} {
        $TrackTree selection set $next
        $TrackTree see $next
        my play_track $next
    }
}

oo::define App method on_volume_down {} {
    if {$Player ne ""} { $Player volume_down }
}

oo::define App method on_volume_up {} {
    if {$Player ne ""} { $Player volume_up }
}
