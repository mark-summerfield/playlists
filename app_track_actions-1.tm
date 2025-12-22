# Copyright © 2025 Mark Summerfield. All rights reserved.

package require yes_no_form

oo::define App method on_track_find {} {
    # TODO to find a track by (partial) case-insensitive name
    puts on_track_find ;# TODO
}

oo::define App method on_track_copy_to_list {} {
    puts on_track_copy_to_list ;# TODO
}

oo::define App method on_track_move_to_list {} {
    puts on_track_move_to_list ;# TODO
}

oo::define App method on_track_remove_from_list {} {
    puts on_track_remove_from_list ;# TODO
}

oo::define App method on_track_delete {} {
    if {[set lid_tid [$TrackTree selection]] ne ""} {
        lassign [split $lid_tid :] lid tid
        lassign [$Pldb track_for_tid $tid] track _
        set list_name [$Pldb list_name $lid]
        if {[YesNoForm show "Delete Track — [tk appname]" \
                "Delete track “[humanize_trackname $track]” from all\
                lists?\nIt is usually best to move to the Uncategorized\
                category’s Unlisted list."] eq "yes"} {
            $Pldb track_delete $tid
            my populate_tracktree $lid
        }
    }
}
