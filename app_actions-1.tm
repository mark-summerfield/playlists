# Copyright © 2025 Mark Summerfield. All rights reserved.

package require misc

oo::define App method on_list_select {} {
    set tlid [$ListTree selection]
    if {[string match C* $tlid]} {
        $TrackTree delete [$TrackTree children {}] ;# category is trackless
    } else {
        my populate_tracktree [string range $tlid 1 end]
    }
}

oo::define App method maybe_add_tracks {} {
    set dir [get_music_dir]
    if {[YesNoForm show "Discover Tracks — [tk appname]" \
            "Add Lists of Tracks from the music folder:\n$dir"] eq "yes"} {
        $ListTree item C0 -open 1
        set music_dir [get_music_dir]
        tk busy .
        try {
            set secs [clock seconds]
            set dirs [glob -directory $music_dir -types d *]
            .mf.play.progress configure -value 0 -maximum [llength $dirs] \
                -text "none read"
            set i 0
            foreach dir $dirs {
                incr i
                set lid [$Pldb list_insert 0 [humanize_dirname $dir]]
                set trav [fileutil::traverse %AUTO% $dir \
                    -filter [lambda filename {
                        regexp {^.*\.(?:ogg|mpe)$} $filename
                    }]]
                $Pldb list_insert_tracks $lid [$trav files]
                lassign [util::n_s $i] j s
                .mf.play.progress configure -value $i \
                    -text "Read $j folder$s…"
                my populate_listtree
                update idletasks
            }
            my populate_listtree
            set secs [expr {[clock seconds] - $secs}]
            lassign [util::n_s $i] i s
            .mf.play.progress configure -value 0 \
                -text "Created $i list$s in [commas $secs]s"
        } finally {
            tk busy forget .
        }
    }
}
