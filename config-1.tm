# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::singleton create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable LastTrack
    variable AutoPlayNext
    variable History
    variable Bookmarks
}

oo::define Config constructor {} {
    set Filename [util::get_ini_filename]
    set Blinking 1
    set Geometry ""
    set LastTrack ""
    set AutoPlayNext 1
    set History [list]
    set Bookmarks [list]
    if {[file exists $Filename] && [file size $Filename]} {
        set ini [ini::open $Filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale 1.0]
            if {![set Blinking [ini::value $ini General Blinking \
                    $Blinking]]} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            set Geometry [ini::value $ini General Geometry $Geometry]
            set AutoPlayNext [ini::value $ini General AutoPlayNext \
                $AutoPlayNext]
            set LastTrack [ini::value $ini General LastTrack $LastTrack]
            catch {
                foreach i [lseq 1 26] {
                    if {[set a_history [ini::value $ini History \
                            Hist$i ""]] ne ""} {
                        lappend History $a_history
                    }
                }
            }
            catch {
                foreach i [lseq 1 26] {
                    if {[set a_bookmark [ini::value $ini Bookmarks \
                            Mark$i ""]] ne ""} {
                        lappend Bookmarks $a_bookmark
                    }
                }
            }
        } on error err {
            puts "invalid config in '$Filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Blinking [my blinking]
        ini::set $ini General Geometry [wm geometry .]
        ini::set $ini General AutoPlayNext [my auto_play_next]
        ini::set $ini General LastTrack [my last_track]
        set i 0
        foreach a_history [lrange $History 0 25] {
            ini::set $ini History Hist[incr i] $a_history
        }
        set i 0
        foreach a_bookmark [lrange $Bookmarks 0 25] {
            ini::set $ini Bookmarks Mark[incr i] $a_bookmark
        }
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method blinking {} { return $Blinking }
oo::define Config method set_blinking blinking { set Blinking $blinking }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method last_track {} { return $LastTrack }
oo::define Config method set_last_track last_track {
    set LastTrack $last_track
}

oo::define Config method auto_play_next {} { return $AutoPlayNext }
oo::define Config method set_auto_play_next auto_play_next {
    set AutoPlayNext $auto_play_next
}

oo::define Config method history {} { return $History }
oo::define Config method set_history history { set History $history }

oo::define Config method bookmarks {} { return $Bookmarks }
oo::define Config method set_bookmarks bookmarks {
    set Bookmarks $bookmarks
}

oo::define Config method to_string {} {
    return "Config filename=$Filename blinking=$Blinking\
        scaling=[tk scaling] geometry=$Geometry last_track=$LastTrack\
        auto_play_next=$AutoPlayNext history=[join $History :]\
        bookmarks=[join $Bookmarks :]"
}
