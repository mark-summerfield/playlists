# Copyright © 2025 Mark Summerfield. All rights reserved.

package require choose_list_form
package require entry_form
package require yes_no_form

oo::define App method on_track_find_next {} {
    if {$FindWhat eq ""} {
        my on_track_find
    } else {
        set found 0
        foreach tuple [lrange [$Pldb list_tracks] $FindIndex end] {
            incr FindIndex
            lassign $tuple lid tid filename
            set name [file tail $filename]
            if {[string match -nocase *$FindWhat* $name]} {
                my on_category_expand_all
                my goto_track $lid $tid $filename
                set found 1
                break
            }
        }
        if {!$found} { my update_status "No (more) match “$FindWhat”" }
    }
}

oo::define App method on_track_find {} {
    if {[set FindWhat [EntryForm show "Find Track — [tk appname]" \
            "Find Track" {} $FindWhat]] ne ""} {
        set FindIndex 0
        my on_track_find_next
    }
}

oo::define App method on_track_copy_to_list {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        set data [$Pldb list_category_data $lid]
        set name [$Pldb list_name $lid]
        lassign [$Pldb track_for_tid $tid] track _
        if {[set to_lid [ChooseListForm show "Copy Track" "Copy track\
                “[humanize_trackname $track]” from\nlist “$name” to:" \
                $Pldb $lid $data]] != -1} {
            $Pldb track_copy $tid $to_lid
            my populate_listtree $lid
            my update_status "Copied track “[humanize_trackname $track]”"
        }
    }
}

oo::define App method on_track_move_to_list {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        set data [$Pldb list_category_data $lid]
        set name [$Pldb list_name $lid]
        lassign [$Pldb track_for_tid $tid] track _
        if {[set to_lid [ChooseListForm show "Move Track" "Move track\
                “[humanize_trackname $track]” from\nlist “$name” to:" \
                $Pldb $lid $data]] != -1} {
            $Pldb track_move $tid $to_lid $lid
            my populate_listtree $lid
            my populate_tracktree $lid
            my update_status "Moved track “[humanize_trackname $track]”"
        }
    }
}

oo::define App method on_track_remove_from_list {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [my GetListAndTrack $lid $tid] list_name track
        if {[YesNoForm show "Remove Track — [tk appname]" \
                "Remove track “[humanize_trackname $track]” from\nlist\
                “$list_name”?"] eq "yes"} {
            $Pldb track_remove $tid $lid
            my populate_tracktree $lid
        }
    }
}

oo::define App method on_track_delete {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [my GetListAndTrack $lid $tid] list_name track
        if {[YesNoForm show "Delete Track — [tk appname]" \
                "Delete track “[humanize_trackname $track]” from all\
                lists?\nOr click No and move it to another list\nor to\
                the Uncategorized category’s Unlisted list." no] eq "yes"} {
            $Pldb track_delete $tid
            my populate_tracktree $lid
        }
    }
}

oo::define App method GetLidAndTid {} {
    if {[set lid_tid [$TrackTree selection]] eq ""} {
        return [list 0 0]
    }
    split $lid_tid :
}

oo::define App method GetListAndTrack {lid tid} {
    lassign [$Pldb track_for_tid $tid] track _
    set list_name [$Pldb list_name $lid]
    list $list_name $track
}

oo::define App method on_track_context_menu {x y} {
    if {[set tlid [$TrackTree identify item $x $y]] ne ""} {
        $TrackTree selection set $tlid
        tk_popup $TrackTreeContextMenu \
                [expr {[winfo rootx $TrackTree] + $x + 3}] $y
    }
}
