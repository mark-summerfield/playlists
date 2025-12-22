# Copyright © 2025 Mark Summerfield. All rights reserved.

package require add_edit_list_form
package require choose_list_form
package require message_form
package require misc
package require mplayer
package require util
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
        } else {
            set name [$Pldb list_name $lid]
            if {[set from_lid [ChooseListForm show Merge \
                    "Merge into list\n“$name”\nfrom list:" $Pldb $lid \
                    $data]] != -1} {
                $Pldb list_merge $lid $from_lid
                my populate_listtree $lid
            }
        }
    }
}

oo::define App method on_list_delete {} {
    if {[set lid [my GetLid]] != -1} {
        set title "Delete List — [tk appname]"
        if {!$lid} {
            set body "Cannot delete the “Unlisted” list from\
                     the\n“Uncategorized” category."
            lassign [$Pldb list_tracks_info $lid] n _
            if {$n} {
                set body "$body\nDelete all the Unlisted list’s tracks?"
                if {[YesNoForm show $title $body no] eq "yes"} {
                    $Pldb list_delete_unlisted_tracks
                    my ListChanged
                }
            } else {
                MessageForm show $title $body OK warning
            }
        } else {
            lassign [$Pldb list_info $lid] name cid category n
            set body "Delete category\n“$category”’s\n“$name”\nlist"
            if {$n} {
                lassign [util::n_s $n] n s
                set body "$body and its $n track$s?"
            } else {
                set body $body?
            }
            if {[YesNoForm show $title $body no] eq "yes"} {
                $Pldb list_delete $lid
                my ListChanged
            }
        }
    }
}

oo::define App method on_list_context_menu {x y} {
    if {[set anid [$ListTree identify item $x $y]] ne ""} {
        $ListTree selection set $anid
        $ListTreeContextMenu delete 0 end
        if {[string match L* $anid]} {
            set lid [string range $anid 1 end]
            lassign [$Pldb list_info $lid] name _ list_category n
            set categories [$Pldb category_names]
            $ListTreeContextMenu add command -label New… \
                -command [callback on_list_new]
            $ListTreeContextMenu add command -label Edit… \
                -command [callback on_list_edit]
            $ListTreeContextMenu add separator
            foreach category $categories {
                if {!$n} { break }
                if {$category eq $list_category} { continue }
                $ListTreeContextMenu add command \
                    -label "Move to $category" \
                    -command [callback ListMoveTo $lid $category]
                incr i
                incr n -1
            }
            tk_popup $ListTreeContextMenu \
                    [expr {[winfo rootx $ListTree] + $x + 3}] $y
        }
    }
}

oo::define App method ListChanged {} {
    my populate_listtree
    my populate_history_menu
    my populate_bookmarks_menu
}

oo::define App method ListMoveTo {lid category} {
    set cid [$Pldb cid_for_name $category]
    $Pldb list_update_category $cid $lid
    my ListChanged
}

# Returns -1 if a category is selected rather than a list.
oo::define App method GetLid {} {
    if {![string match L* [set tlid [$ListTree selection]]]} { return -1 }
    string range $tlid 1 end
}
