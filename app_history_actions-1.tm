# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_history_remove {} {
    puts on_history_remove
    if {[set selection [$TrackTree selection]] ne ""} {
        # TODO use db
        #[Config new] remove_history [$selection]
        #my populate_history_menu
    }
}
