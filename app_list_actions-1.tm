# Copyright © 2025 Mark Summerfield. All rights reserved.

package require add_edit_list_form
package require delete_list_form
package require message_form

oo::define App method on_list_new {} {
    if {[set lid [AddEditListForm show $Pldb]]} {
        my populate_listtree $lid
    }
}

oo::define App method on_list_edit {} {
    if {[set tlid [my get_tlid]] ne ""} {
        set lid [string range $tlid 1 end]
        if {[AddEditListForm show $Pldb $lid]} {
            my populate_listtree $lid
        }
    }
}

oo::define App method on_list_add_folder {} {
    if {[set tlid [my get_tlid]] ne ""} {
        puts on_list_add_folder ;# TODO
    }
}

oo::define App method on_list_add_tracks {} {
    if {[set tlid [my get_tlid]] ne ""} {
        puts on_list_add_tracks ;# TODO
    }
}

oo::define App method on_list_merge {} {
    if {[set tlid [my get_tlid]] ne ""} {
        puts on_list_merge ;# TODO
    }
}

oo::define App method on_list_delete {} {
    if {[set tlid [my get_tlid]] ne ""} {
        set lid [string range $tlid 1 end]
        if {!$lid} {
            MessageForm show "Delete List — [tk appname]" \
                "Cannot delete the “Unlisted” list from the\
                “Uncategorized” category." OK warning
            return
        }
        lassign [$Pldb list_info $lid] name cid category n
        switch [DeleteListForm show $name $cid $category $n] {
            1 {
                $Pldb list_update_category 0 $lid
                my populate_listtree $lid
            }
            2 {
                $Pldb list_delete $lid
                $Pldb history_delete $lid
                $Pldb bookmarks_delete $lid
                my populate_listtree
                my populate_history_menu
                my populate_bookmarks_menu
            }
        }
    }
}

# Returns "" if a category is selected rather than a list.
oo::define App method get_tlid {} {
    if {[string match L* [set tlid [$ListTree selection]]]} {
        return $tlid
    }
}
