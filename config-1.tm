# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::singleton create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable SashPos
    variable AutoPlayNext
    variable AutoCircle
    variable SkipBy
}

oo::define Config constructor {} {
    set Filename [util::get_ini_filename]
    set Blinking 1
    set Geometry ""
    set SashPos 0
    set AutoPlayNext 1
    set AutoCircle 1
    set SkipBy 5
    if {[file exists $Filename] && [file size $Filename]} {
        set ini [ini::open $Filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale [tk scaling]]
            if {![set Blinking [ini::value $ini General Blinking \
                    $Blinking]]} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            set Geometry [ini::value $ini General Geometry $Geometry]
            set SashPos [ini::value $ini General SashPos $SashPos]
            set AutoPlayNext [ini::value $ini General AutoPlayNext \
                $AutoPlayNext]
            set AutoCircle [ini::value $ini General AutoCircle $AutoCircle]
            set SkipBy [ini::value $ini General SkipBy $SkipBy]
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
        ini::set $ini General SashPos [my sashpos]
        ini::set $ini General AutoPlayNext [my auto_play_next]
        ini::set $ini General AutoCircle [my auto_circle]
        ini::set $ini General SkipBy [my skip_by]
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

oo::define Config method sashpos {} { return $SashPos }
oo::define Config method set_sashpos sashpos { set SashPos $sashpos }

oo::define Config method auto_play_next {} { return $AutoPlayNext }
oo::define Config method set_auto_play_next auto_play_next {
    set AutoPlayNext $auto_play_next
}

oo::define Config method auto_circle {} { return $AutoCircle }
oo::define Config method set_auto_circle auto_circle {
    set AutoCircle $auto_circle
}

oo::define Config method skip_by {} { return $SkipBy }
oo::define Config method set_skip_by skip_by { set SkipBy $skip_by }

oo::define Config method to_string {} {
    return "Config filename=$Filename blinking=$Blinking\
        scaling=[tk scaling] geometry=$Geometry sashpos=$SashPos\
        auto_play_next=$AutoPlayNext auto_circle=$AutoCircleskip_by=$SkipBy"
}
