# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_history_remove {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        $Pldb history_delete $lid $tid
        my populate_history_menu
    }
}
