# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_bookmarks_add {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        $Pldb bookmarks_insert $lid $tid
        my populate_bookmarks_menu
    }
}

oo::define App method on_bookmarks_remove {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        $Pldb bookmarks_delete $lid $tid
        my populate_bookmarks_menu
    }
}
