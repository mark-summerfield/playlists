# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_list_select {} {
    set ltlid [$ListTree selection]
    if {[string match C* $ltlid]} {
        $TrackTree delete [$TrackTree children {}] ;# category is trackless
    } else {
        my populate_tracktree [string range $ltlid 1 end]
    }
}
