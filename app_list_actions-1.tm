# Copyright © 2025 Mark Summerfield. All rights reserved.

package require add_edit_list_form
package require delete_list_form
package require merge_list_form
package require message_form
package require misc
package require mplayer
package require yes_no_form

oo::define App method on_list_new {} {
    if {[set lid [AddEditListForm show $Pldb]]} {
        my populate_listtree $lid
    }
}

oo::define App method on_list_edit {} {
    if {[set lid [my GetLid]] != -1} {
        if {[AddEditListForm show $Pldb $lid]} {
            my populate_listtree $lid
        }
    }
}

oo::define App method on_list_add_folder {} {
    if {[set lid [my GetLid]] != -1} {
        if {[set dir [tk_chooseDirectory -parent . -mustexist 1 \
                -title "Add Folder’s Tracks — [tk appname]" \
                -initialdir [get_music_dir]]] ne ""} {
            my AddTracks $lid [glob -directory $dir *.{mp3,ogg}]
        }
    }
}

oo::define App method on_list_add_tracks {} {
    if {[set lid [my GetLid]] != -1} {
        set filenames [tk_getOpenFile -title "Add Tracks — [tk appname]" \
            -multiple 1 -filetypes [Mplayer filetypes] \
            -initialdir [get_music_dir]]
        my AddTracks $lid $filenames
    }
}

oo::define App method AddTracks {lid filenames} {
    if {[llength $filenames]} {
        tk busy .
        try {
            $Pldb list_insert_tracks $lid $filenames
        } finally {
            tk busy forget .
        }
        my populate_listtree $lid
    }
}

oo::define App method on_list_merge {} {
    if {[set lid [my GetLid]] != -1} {
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
    if {[set lid [my GetLid]] != -1} {
        if {!$lid} {
            set title "Delete List — [tk appname]"
            set body "Cannot delete the “Unlisted” list from the\
                     “Uncategorized” category."
            lassign [$Pldb list_tracks_info $lid] n _
            if {$n} {
                set body "$body\nDelete all the Unlisted list’s tracks?"
                if {[YesNoForm show $title $body] eq "yes"} {
                    $Pldb list_delete_unlisted_tracks
                    my ListChanged
                }
            } else {
                MessageForm show $title $body OK warning
            }
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
                my ListChanged
            }
        }
    }
}

oo::define App method ListChanged {} {
    my populate_listtree
    my populate_history_menu
    my populate_bookmarks_menu
}

# Returns -1 if a category is selected rather than a list.
oo::define App method GetLid {} {
    if {![string match L* [set tlid [$ListTree selection]]]} { return -1 }
    string range $tlid 1 end
}
