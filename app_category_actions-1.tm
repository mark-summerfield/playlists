# Copyright © 2025 Mark Summerfield. All rights reserved.

package require entry_form
package require message_form
package require util
package require yes_no_form

oo::define App method on_category_new {} {
    if {[set name [EntryForm show "New Category — [tk appname]" \
            "Enter a name for a new category" [$Pldb category_names 1]]] \
            ne ""} {
        set cid [$Pldb category_insert $name]
        my populate_listtree
        after idle [my select_category $cid]
    }
}

oo::define App method on_category_rename {} {
    set tcid [my get_tcid]
    if {$tcid eq "C0"} {
        MessageForm show "Rename Category — [tk appname]" \
            "Cannot rename the “Uncategorized” category." OK warning
        return
    }
    if {[string match C* $tcid]} {
        set name [$ListTree item $tcid -text]
        if {[set name [EntryForm show "Rename Category — [tk appname]" \
                "Enter a new name for category\n“$name”" \
                [$Pldb category_names 1] $name]] ne ""} {
            set cid [string range $tcid 1 end]
            $Pldb category_update $cid $name
            my populate_listtree
            after idle [my select_category $cid]
        }
    }
}

oo::define App method on_category_delete {} {
    set tcid [my get_tcid]
    if {$tcid eq "C0"} {
        MessageForm show "Delete Category — [tk appname]" \
            "Cannot delete the “Uncategorized” category." OK warning
        return
    }
    if {[string match C* $tcid]} {
        set cid [string range $tcid 1 end]
        lassign [$Pldb category_info $cid] name n
        set body "Delete category “$name”"
        if {$n} {
            lassign [util::n_s $n] size s
            set body "$body\nand move its $size list$s to Uncategorized"
        }
        set body $body?
        if {[YesNoForm show "Delete Category — [tk appname]" $body] \
                eq "yes"} {
            $Pldb category_delete $cid
            my populate_listtree
            after idle [my select_category $cid]
        }
    }
}

oo::define App method get_tcid {} {
    if {[string match L* [set tcid [$ListTree selection]]]} {
        set tcid [$ListTree parent $tcid]
    }
    return $tcid
}

oo::define App method select_category cid {
    foreach tcid [$ListTree children {}] {
        if {$tcid eq "C$cid"} {
            select_tree_item $ListTree $tcid
            break
        }
    }
}
