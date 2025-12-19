# Copyright © 2025 Mark Summerfield. All rights reserved.

package require add_edit_list_form
package require delete_list_form
package require merge_list_form
package require message_form
package require misc
package require mplayer

oo::define App method on_list_new {} {
    if {[set lid [AddEditListForm show $Pldb]]} {
        my populate_listtree $lid
    }
}

oo::define App method on_list_edit {} {
    lassign [my get_tlid_and_lid] tlid lid
    if {$tlid ne ""} {
        if {[AddEditListForm show $Pldb $lid]} {
            my populate_listtree $lid
        }
    }
}

oo::define App method on_list_add_folder {} {
    lassign [my get_tlid_and_lid] tlid lid
    if {$tlid ne ""} {
        if {[set dir [tk_chooseDirectory -parent . -mustexist 1 \
                -title "Add Folder’s Tracks — [tk appname]" \
                -initialdir [get_music_dir]]] ne ""} {
            my AddTracks $lid [glob -directory $dir *.{mp3,ogg}]
        }
    }
}

oo::define App method on_list_add_tracks {} {
    lassign [my get_tlid_and_lid] tlid lid
    if {$tlid ne ""} {
        set filenames [tk_getOpenFile -title "Add Tracks — [tk appname]" \
            -multiple 1 -filetypes [Mplayer filetypes] \
            -initialdir [get_music_dir]]
        my AddTracks $lid $filenames
    }
}

oo::define App method AddTracks {lid filenames} {
    if {[llength $filenames]} {
        $Pldb list_insert_tracks $lid $filenames
        my populate_listtree $lid
    }
}

oo::define App method on_list_merge {} {
    lassign [my get_tlid_and_lid] tlid lid
    if {$tlid ne ""} {
        set data [$Pldb list_merge_data $lid]
        if {![llength $data]} {
            MessageForm show "Merge — [tk appname]" \
                "There are no nonempty lists to merge from." OK warning
            return
        }
        if {[MergeListForm show $Pldb $lid $data]} {
            my populate_listtree $lid
        }
    }
}

oo::define App method on_list_delete {} {
    lassign [my get_tlid_and_lid] tlid lid
    if {$tlid ne ""} {
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
                my populate_listtree
                my populate_history_menu
                my populate_bookmarks_menu
            }
        }
    }
}

# Returns {"" 0} if a category is selected rather than a list.
oo::define App method get_tlid_and_lid {} {
    if {[string match L* [set tlid [$ListTree selection]]]} {
        return [list $tlid [string range $tlid 1 end]]
    }
    list "" 0
}
