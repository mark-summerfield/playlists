# Copyright © 2025 Mark Summerfield. All rights reserved.

package require entry_form
package require message_form

oo::define App method on_category_new {} {
    if {[set name [EntryForm show "New Category — [tk appname]" \
            "Enter a new category name"]] ne ""} {
        foreach pair [$Pldb categories] {
            lassign $pair _ category
            if {[string equal -nocase $name $category]} {
                MessageForm show "Existing Category — [tk appname]" \
                    "Category $name already exists." OK warning
                return
            }
        }
        set cid [$Pldb category_insert $name]
        my populate_listtree
        after idle [my select_category $cid]
    }
}

oo::define App method on_category_rename {} {
    puts on_category_rename ;# TODO
}

oo::define App method on_category_delete {} {
    puts on_category_delete ;# TODO
}

oo::define App method select_category cid {
    foreach tcid [$ListTree children {}] {
        if {$tcid eq "C$cid"} {
            select_tree_item $ListTree $tcid
            break
        }
    }
}
