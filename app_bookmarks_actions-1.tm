# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_bookmarks_add {} {
    puts on_bookmarks_add
    if {[set selection [$TrackTree selection]] ne ""} {
        # TODO use db
        # [Config new] add_bookmark [$selection]
        # my populate_bookmarks_menu
    }
}

oo::define App method on_bookmarks_remove {} {
    puts on_bookmarks_remove
    if {[set selection [$TrackTree selection]] ne ""} {
        # TODO use db
        # [Config new] remove_bookmark [$selection]
        # my populate_bookmarks_menu
    }
}
