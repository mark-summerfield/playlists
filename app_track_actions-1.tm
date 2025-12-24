# Copyright © 2025 Mark Summerfield. All rights reserved.

package require choose_list_form
package require entry_form
package require yes_no_form

oo::define App method on_track_rename {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [$Pldb track_names $tid] filename name
        set name [humanize_trackname $filename $name]
        if {[set name [EntryForm show "Rename Track — [tk appname]" \
                "Name" {} $name]] ne ""} {
            $Pldb track_update_name $tid $name
            my populate_tracktree $lid $tid
            my populate_history_menu
            my populate_bookmarks_menu
        }
    }
}

oo::define App method on_track_copy_name {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [$Pldb track_names $tid] filename name
        set name [humanize_trackname $filename $name]
        clipboard clear
        clipboard append $name
        my update_status "Copied “$name” to the clipboard"
    }
}

oo::define App method on_track_move_up {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        $Pldb track_move_up $lid $tid
        my populate_tracktree $lid $tid
    }
}

oo::define App method on_track_move_down {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        $Pldb track_move_down $lid $tid
        my populate_tracktree $lid $tid
    }
}

oo::define App method on_track_goto_current {} {
    lassign [$Pldb most_recent] lid tid filename
    if {$tid} {
        my goto_track $lid $tid $filename
    }
}

oo::define App method on_track_find_next {} {
    if {$FindWhat eq ""} {
        my on_track_find
    } else {
        set found 0
        foreach tuple [lrange [$Pldb list_tracks] $FindIndex end] {
            incr FindIndex
            lassign $tuple lid tid filename name
            set basename [file tail $filename]
            if {[string match -nocase *$FindWhat* $basename] ||
                    [string match -nocase *$FindWhat* $name]} {
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
        set list_name [$Pldb list_name $lid]
        lassign [$Pldb track_names $tid] filename name
        set name [humanize_trackname $filename $name]
        if {[set to_lid [ChooseListForm show "Copy Track" "Copy track\
                “$name” from\nlist “$list_name” to:" $Pldb $lid $data]] \
                != -1} {
            $Pldb track_copy $tid $to_lid
            my populate_listtree $lid
            my update_status "Copied track “$name”"
        }
    }
}

oo::define App method on_track_move_to_list {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        set data [$Pldb list_category_data $lid]
        set list_name [$Pldb list_name $lid]
        lassign [$Pldb track_names $tid] filename name
        set name [humanize_trackname $filename $name]
        if {[set to_lid [ChooseListForm show "Move Track" "Move track\
                “$name”\nfrom the “$list_name” list to:" $Pldb $lid \
                $data]] != -1} {
            $Pldb track_move $tid $to_lid $lid
            my populate_listtree $lid
            my populate_tracktree $lid
            my populate_history_menu
            my populate_bookmarks_menu
            my update_status "Moved track “$name”"
        }
    }
}

oo::define App method on_track_remove_from_list {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [my GetListAndTrack $lid $tid] list_name track
        if {[YesNoForm show "Remove Track — [tk appname]" \
                "Remove track “$track”\n from the\
                “$list_name” list?"] eq "yes"} {
            $Pldb track_remove $tid $lid
            my populate_tracktree $lid
            my populate_history_menu
            my populate_bookmarks_menu
        }
    }
}

oo::define App method on_track_delete {} {
    lassign [my GetLidAndTid] lid tid
    if {$tid} {
        lassign [my GetListAndTrack $lid $tid] list_name track
        if {[YesNoForm show "Delete Track — [tk appname]" \
                "Delete track “$track” from all\
                lists?\nOr click No and move it to another list\nor to\
                the Uncategorized category’s Unlisted list." no] eq "yes"} {
            $Pldb track_delete $tid
            my populate_tracktree $lid
            my populate_history_menu
            my populate_bookmarks_menu
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
    lassign [$Pldb track_names $tid] filename name
    set list_name [$Pldb list_name $lid]
    list $list_name [humanize_trackname $filename $name]
}

oo::define App method on_track_context_menu {x y} {
    if {[set tlid [$TrackTree identify item $x $y]] ne ""} {
        $TrackTree selection set $tlid
        tk_popup $TrackTreeContextMenu \
                [expr {[winfo rootx $TrackTree] + $x + 3}] $y
    }
}
