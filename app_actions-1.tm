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
            foreach dir [glob -directory $music_dir -types d *] {
                set lid [$Pldb list_insert 0 [humanize_dirname $dir]]
                set trav [fileutil::traverse %AUTO% $dir \
                    -filter [lambda filename {
                        regexp {^.*\.(?:ogg|mpe)$} $filename
                    }]]
                $Pldb list_insert_tracks $lid [$trav files]
                my populate_listtree
                update idletasks
            }
            my populate_listtree
        } finally {
            tk busy forget .
        }
    }
}
