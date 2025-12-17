# Copyright © 2025 Mark Summerfield. All rights reserved.

package require add_edit_list_form

oo::define App method on_list_new {} {
    AddEditListForm show $Pldb
}

oo::define App method on_list_edit {} {
    if {[set tlid [my get_tlid]] ne ""} {
        AddEditListForm show $Pldb [string range $tlid 1 end]
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
        # TODO # Offer (*) Move to Uncategorized ( ) Permanently Delete
        puts on_list_delete ;# TODO
    }
}

# Returns "" if a category is selected rather than a list.
oo::define App method get_tlid {} {
    if {[string match L* [set tlid [$ListTree selection]]]} {
        return $tlid
    }
}
