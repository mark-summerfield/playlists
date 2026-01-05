# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require tooltip 2
package require ui

oo::class create ConfigForm {
    superclass AbstractForm

    variable Ok
    variable Pldb
    variable DebugRef
    variable Debug
    variable Blinking
    variable AutoPlayNext
}

oo::define ConfigForm constructor {ok pldb debug} {
    set Ok $ok
    set Pldb $pldb
    set DebugRef $debug
    set Debug [$DebugRef get]
    set config [Config new]
    set Blinking [$config blinking]
    set AutoPlayNext [$config auto_play_next]
    my make_widgets 
    my make_layout
    my make_bindings
    next .configForm [callback on_cancel]
    my show_modal .configForm.mf.scaleSpinbox
}

oo::define ConfigForm method make_widgets {} {
    set config [Config new]
    tk::toplevel .configForm
    wm resizable .configForm 0 0
    wm title .configForm "[tk appname] — Options"
    ttk::frame .configForm.mf
    set tip tooltip::tooltip
    ttk::label .configForm.mf.scaleLabel -text "Application Scale" \
        -underline 12
    ttk::spinbox .configForm.mf.scaleSpinbox -format %.2f -from 1.0 \
        -to 10.0 -increment 0.1
    ui::apply_edit_bindings .configForm.mf.scaleSpinbox
    $tip .configForm.mf.scaleSpinbox "Application’s scale factor.\n\
        Restart to apply."
    .configForm.mf.scaleSpinbox set [format %.2f [tk scaling]]
    ttk::checkbutton .configForm.mf.blinkCheckbutton \
        -text "Cursor Blink" -underline 7 \
        -variable [my varname Blinking]
    if {$Blinking} { .configForm.mf.blinkCheckbutton state selected }
    $tip .configForm.mf.blinkCheckbutton \
        "Whether the text cursor should blink."
    ttk::checkbutton .configForm.mf.autoPlayCheckbutton \
        -text "Auto Play Next" -underline 0 \
        -variable [my varname AutoPlayNext]
    if {$AutoPlayNext} { .configForm.mf.autoPlayCheckbutton state selected }
    $tip .configForm.mf.autoPlayCheckbutton \
        "Whether to automatically play the next track after the current\
        one finishes."
    ttk::label .configForm.mf.skipLabel -text "Skip by (seconds)" \
        -underline 1
    ttk::spinbox .configForm.mf.skipSpinbox -format %.0f -from 1.0 \
        -to 10.0 -increment 1.0
    ui::apply_edit_bindings .configForm.mf.skipSpinbox
    $tip .configForm.mf.skipSpinbox "How many seconds to skip backwards\
        or forwards by."
    .configForm.mf.skipSpinbox set [$config skip_by]
    ttk::checkbutton .configForm.mf.debugCheckbutton \
        -text Debug -underline 0 -variable [my varname Debug]
    if {$Debug} { .configForm.mf.debugCheckbutton state selected }
    $tip .configForm.mf.debugCheckbutton \
        "Whether to print debug info to stdout."
    set opts "-compound left -width 15"
    ttk::label .configForm.mf.playlistsFileLabel -foreground gray25 \
        -text "Playlists file (v[$Pldb version])"
    ttk::label .configForm.mf.playlistsFilenameLabel -foreground gray25 \
        -text [$Pldb filename] -relief sunken
    ttk::label .configForm.mf.configFileLabel -foreground gray25 \
        -text "Config file"
    ttk::label .configForm.mf.configFilenameLabel -foreground gray25 \
        -text [$config filename] -relief sunken
    ttk::frame .configForm.mf.buttons
    ttk::button .configForm.mf.buttons.okButton -text OK -underline 0 \
        -compound left -image [ui::icon ok.svg $::ICON_SIZE] \
        -command [callback on_ok]
    ttk::button .configForm.mf.buttons.cancelButton -text Cancel \
        -compound left -command [callback on_cancel] \
        -image [ui::icon gtk-cancel.svg $::ICON_SIZE]
}

oo::define ConfigForm method make_layout {} {
    const opts "-padx 3 -pady 3"
    grid .configForm.mf.scaleLabel -row 0 -column 0 -sticky w {*}$opts
    grid .configForm.mf.scaleSpinbox -row 0 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .configForm.mf.blinkCheckbutton -row 2 -column 1 -sticky we
    grid .configForm.mf.autoPlayCheckbutton -row 3 -column 1 -sticky we
    grid .configForm.mf.skipLabel -row 4 -column 0 -sticky w {*}$opts
    grid .configForm.mf.skipSpinbox -row 4 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .configForm.mf.debugCheckbutton -row 5 -column 1 -sticky we
    grid .configForm.mf.playlistsFileLabel -row 7 -column 0 -sticky we \
        {*}$opts
    grid .configForm.mf.playlistsFilenameLabel -row 7 -column 1 \
        -columnspan 2 -sticky we {*}$opts
    grid .configForm.mf.configFileLabel -row 8 -column 0 -sticky we \
        {*}$opts
    grid .configForm.mf.configFilenameLabel -row 8 -column 1 \
        -columnspan 2 -sticky we {*}$opts
    grid .configForm.mf.buttons -row 9 -column 0 -columnspan 3 \
        -sticky we
    pack [ttk::frame .configForm.mf.buttons.pad1] -side left -expand 1
    pack .configForm.mf.buttons.okButton -side left {*}$opts
    pack .configForm.mf.buttons.cancelButton -side left {*}$opts
    pack [ttk::frame .configForm.mf.buttons.pad2] -side right -expand 1
    grid columnconfigure .configForm.mf 1 -weight 1
    pack .configForm.mf -fill both -expand 1
}

oo::define ConfigForm method make_bindings {} {
    bind .configForm <Escape> [callback on_cancel]
    bind .configForm <Return> [callback on_ok]
    bind .configForm <Alt-a> {.configForm.mf.autoPlayCheckbutton invoke}
    bind .configForm <Alt-b> {.configForm.mf.blinkCheckbutton invoke}
    bind .configForm <Alt-d> {.configForm.mf.debugCheckbutton invoke}
    bind .configForm <Alt-k> {focus .configForm.mf.skipSpinbox}
    bind .configForm <Alt-o> [callback on_ok]
    bind .configForm <Alt-s> {focus .configForm.mf.scaleSpinbox}
}

oo::define ConfigForm method on_ok {} {
    set config [Config new]
    tk scaling [.configForm.mf.scaleSpinbox get]
    $config set_blinking $Blinking
    $config set_auto_play_next $AutoPlayNext
    $config set_skip_by [.configForm.mf.skipSpinbox get]
    $DebugRef set $Debug
    $Ok set 1
    my delete
}

oo::define ConfigForm method on_cancel {} { my delete }
