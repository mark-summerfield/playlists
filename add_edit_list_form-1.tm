# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui

oo::class create AddEditListForm {
    superclass AbstractForm

    variable Pldb
    variable Lid
}

# lid 0 → new ; else edit
oo::define AddEditListForm classmethod show {pldb {lid 0}} {
    set form [AddEditListForm new $pldb $lid]
    tkwait window .add_edit_list_form
}

oo::define AddEditListForm constructor {pldb lid} {
    set Pldb $pldb
    set Lid $lid
    my make_widgets
    my make_layout
    my make_bindings
    next .add_edit_list_form [callback on_done 0]
    set widget [expr {$Lid ? ".add_edit_list_form.mf.listEntry" \
                           : ".add_edit_list_form.mf.categoryCombo"}]
    my show_modal $widget
}

oo::define AddEditListForm method make_widgets {} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .add_edit_list_form
    wm resizable .add_edit_list_form 0 0
    set what [expr {$Lid ? "Edit" : "New"}]
    wm title .add_edit_list_form "$what List — [tk appname]"
    ttk::frame .add_edit_list_form.mf
    ttk::label .add_edit_list_form.mf.categoryLabel -text Category \
        -underline 1
    set categories [lmap category [$Pldb categories] {lindex $category 1}]
    ttk::combobox .add_edit_list_form.mf.categoryCombo -values $categories
    .add_edit_list_form.mf.categoryCombo state readonly
    ttk::label .add_edit_list_form.mf.listLabel -text "List Name" \
        -underline 0
    ttk::entry .add_edit_list_form.mf.listEntry -validate key \
        -validatecommand [callback on_validate %P]
    ui::apply_edit_bindings .add_edit_list_form.mf.listEntry
    ttk::frame .add_edit_list_form.mf.bf
    ttk::button .add_edit_list_form.mf.bf.ok_button -text OK \
        -underline 0 -compound left -command [callback on_done 1] \
        -image [ui::icon ok.svg $size] -state disabled
    ttk::button .add_edit_list_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
    if {$Lid} {
        lassign [$Pldb list_info $Lid] name cid category
        if {$cid} {
            .add_edit_list_form.mf.categoryCombo set $category
            .add_edit_list_form.mf.listEntry insert 0 $name
            .add_edit_list_form.mf.listEntry selection range 0 end
        }
    } else {
        .add_edit_list_form.mf.categoryCombo set Uncategorized
    }
}

oo::define AddEditListForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    grid .add_edit_list_form.mf.categoryLabel -row 0 -column 0 {*}$opts
    grid .add_edit_list_form.mf.categoryCombo -row 0 -column 1 -sticky we \
        {*}$opts
    grid .add_edit_list_form.mf.listLabel -row 1 -column 0 {*}$opts
    grid .add_edit_list_form.mf.listEntry -row 1 -column 1 -sticky we \
        {*}$opts
    grid .add_edit_list_form.mf.bf -row 2 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid columnconfigure .add_edit_list_form.mf 1 -weight 1
    pack .add_edit_list_form.mf.bf.ok_button -side left {*}$opts
    pack .add_edit_list_form.mf.bf.cancel_button -side right {*}$opts
    pack .add_edit_list_form.mf -fill both -expand 1
}

oo::define AddEditListForm method make_bindings {} {
    bind .add_edit_list_form <a> {
        focus .add_edit_list_form.mf.categoryCombo}
    bind .add_edit_list_form <l> {focus .add_edit_list_form.mf.listEntry}
    bind .add_edit_list_form <Escape> {
        .add_edit_list_form.mf.bf.cancel_button invoke}
    bind .add_edit_list_form <Return> {
        .add_edit_list_form.mf.bf.ok_button invoke}
    bind .add_edit_list_form <Alt-o> {
        .add_edit_list_form.mf.bf.ok_button invoke}
    bind .add_edit_list_form <Alt-c> {
        .add_edit_list_form.mf.bf.cancel_button invoke}
}

oo::define AddEditListForm method on_validate name {
    set name [string tolower [string trim $name]]
    # TODO
    set disallowed {}
    if {$name ne "" && $name ni $disallowed} {
        .add_edit_list_form.mf.bf.ok_button configure -state normal
        .add_edit_list_form.mf.listEntry configure -foreground black
    } else {
        .add_edit_list_form.mf.bf.ok_button configure -state disabled
        .add_edit_list_form.mf.listEntry configure -foreground red
    }
    return 1
}

oo::define AddEditListForm method on_done ok {
    if {$ok} {
        puts "add/edit name & category" 
    }
    my delete
}
