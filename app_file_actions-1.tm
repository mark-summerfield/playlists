# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config_form
package require db
package require ref
package require util

oo::define App method on_file_export {} {
    if {[set filename [tk_getSaveFile -parent . \
            -title "Export Database — [tk appname]" \
            -filetypes {{{SQL Files} {.sql}}}]] ne ""} {
        db::dump [$Pldb db] $filename
        my update_status "Exported database to [file tail $filename]"
    }
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new 0]
    set debug [Ref new [$Player debug]]
    set form [ConfigForm new $ok $Pldb $debug]
    tkwait window [$form form]
    if {[$ok get]} {
        $Player set_debug [$debug get]
    }
}

oo::define App method on_about {} {
    lassign [$Pldb info] categories lists tracks secs
    set scategories [expr {$categories == 1 ? "y" : "ies"}]
    set ncategories [commas $categories]
    lassign [util::n_s $lists 1] nlists slists
    lassign [util::n_s $tracks 1] ntracks stracks
    set secs [humanize_secs $secs]
    set desc "Play tracks and manage playlists.\n$ncategories\
        categor$scategories · $nlists list$slists · $ntracks\
        track$stracks · $secs"
    AboutForm new $desc https://github.com/mark-summerfield/playlists
}

oo::define App method on_quit {} {
    $Player close 
    set config [Config new]
    $config set_sashpos [.mf.pw sashpos 0]
    $config save
    exit
}
