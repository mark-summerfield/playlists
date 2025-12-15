# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_list_select {} {
    set tlid [$ListTree selection]
    if {[string match C* $tlid]} {
        $TrackTree delete [$TrackTree children {}] ;# category is trackless
    } else {
        my populate_tracktree [string range $tlid 1 end]
    }
}
