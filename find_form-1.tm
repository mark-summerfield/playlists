# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require tooltip 2
package require ui

oo::class create FindForm {
    superclass AbstractForm

    variable Reply
    variable Artists
}

oo::define FindForm classmethod show {{what ""} {artists 0}} {
    set reply [Ref new [list $what $artists]]
    set form [FindForm new $reply $what $artists]
    tkwait window .find_form
    $reply get
}

oo::define FindForm constructor {reply what artists} {
    set Reply $reply
    set Artists $artists
    my make_widgets
    my make_layout
    my make_bindings
    next .find_form [callback on_done 0]
    if {$what ne ""} {
        .find_form.mf.tf.entry insert 0 $what
        .find_form.mf.tf.entry selection range 0 end
    }
    my show_modal .find_form.mf.tf.entry
}

oo::define FindForm method make_widgets {} {
    set tip tooltip::tooltip
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .find_form
    wm resizable .find_form 0 0
    wm title .find_form "Find — [tk appname]"
    ttk::frame .find_form.mf
    ttk::frame .find_form.mf.tf
    ttk::label .find_form.mf.tf.label -text "Find:" -underline 0
    ttk::entry .find_form.mf.tf.entry -validate key \
        -validatecommand [callback on_validate %P]
    ui::apply_edit_bindings .find_form.mf.tf.entry
    $tip .find_form.mf.tf.entry "The search is case-insensitive\nand\
        * and ? glob-style wildcards are supported.\nThe find text is\
        treated as “*findtext*”."
    ttk::checkbutton .find_form.mf.tf.checkbox -underline 0 \
        -text "Also search artists’ names" -variable [my varname Artists]
    ttk::frame .find_form.mf.bf
    ttk::button .find_form.mf.bf.ok_button -text OK \
        -underline 0 -compound left -command [callback on_done 1] \
        -image [ui::icon ok.svg $size] -state disabled
    ttk::button .find_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
}

oo::define FindForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    grid .find_form.mf.tf.label -row 0 -column 0 -sticky w {*}$opts
    grid .find_form.mf.tf.entry -row 0 -column 1 -sticky we {*}$opts
    grid .find_form.mf.tf.checkbox -row 1 -column 0 -columnspan 2 \
        -sticky w {*}$opts
    grid columnconfigure .find_form.mf.tf 1 -weight 1
    pack .find_form.mf.tf -fill both -expand 1
    pack .find_form.mf.bf.ok_button -side left {*}$opts
    pack .find_form.mf.bf.cancel_button -side right {*}$opts
    pack .find_form.mf.bf -side bottom -fill x -expand 1 {*}$opts
    pack .find_form.mf -fill both -expand 1
}

oo::define FindForm method make_bindings {} {
    bind .find_form <Escape> {.find_form.mf.bf.cancel_button invoke}
    bind .find_form <Return> {.find_form.mf.bf.ok_button invoke}
    bind .find_form <Alt-a> {.find_form.mf.tf.checkbox invoke}
    bind .find_form <Alt-o> {.find_form.mf.bf.ok_button invoke}
    bind .find_form <Alt-c> {.find_form.mf.bf.cancel_button invoke}
}

oo::define FindForm method on_validate txt {
    set txt [string tolower [string trim $txt]]
    if {$txt ne ""} {
        .find_form.mf.bf.ok_button configure -state normal
        .find_form.mf.tf.entry configure -foreground black
    } else {
        .find_form.mf.bf.ok_button configure -state disabled
        .find_form.mf.tf.entry configure -foreground red
    }
    return 1
}

oo::define FindForm method on_done ok {
    if {$ok} {
        set what [string trim [.find_form.mf.tf.entry get]]
        $Reply set [list $what $Artists]
    }
    my delete
}
