# Copyright © 2025 Mark Summerfield. All rights reserved.

package require entry_form
package require message_form

oo::define App method on_category_new {} {
    if {[set name [EntryForm show "New Category — [tk appname]" \
            "Enter a new category name" [$Pldb category_names 1]]] ne ""} {
        set cid [$Pldb category_insert $name]
        my populate_listtree
        after idle [my select_category $cid]
    }
}

oo::define App method on_category_rename {} {
    if {[string match L* [set tcid [$ListTree selection]]]} {
        set tcid [$ListTree parent $tcid]
    }
    if {$tcid eq "C0"} {
        MessageForm show "Rename Category — [tk appname]" \
            "Cannot rename the Uncategorized category." OK warning
        return
    }
    if {[string match C* $tcid]} {
        set name [$ListTree item $tcid -text]
        if {[set name [EntryForm show "Rename Category — [tk appname]" \
                "Enter a new category name to replace:\n$name" \
                [$Pldb category_names 1] $name]] ne ""} {
            puts "newname=$name"
            # TODO
            # - call (new method) $Pldb category_update $cid $name
            # my populate_listtree
            # after idle [my select_category $cid]
            puts on_category_rename ;# TODO
        }
    }
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
