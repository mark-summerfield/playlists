# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui

oo::class create AddEditListForm {
    superclass AbstractForm

    variable Reply
    variable Pldb
    variable Lid
    variable CategoryCombo
    variable ListNameEntry
}

# lid 0 → new ; else edit • Returns 0 on Cancel or New|Edited lid on OK
oo::define AddEditListForm classmethod show {pldb {lid 0}} {
    set reply [Ref new 0]
    set form [AddEditListForm new $reply $pldb $lid]
    tkwait window .add_edit_list_form
    $reply get
}

oo::define AddEditListForm constructor {reply pldb lid} {
    set Reply $reply
    set Pldb $pldb
    set Lid $lid
    my make_widgets
    my prepare
    my make_layout
    my make_bindings
    next .add_edit_list_form [callback on_done 0]
    my show_modal [expr {$Lid ? $ListNameEntry : $CategoryCombo}]
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
    set CategoryCombo [ttk::combobox .add_edit_list_form.mf.categoryCombo \
        -values [$Pldb category_names]]
    $CategoryCombo state readonly
    ttk::label .add_edit_list_form.mf.listLabel -text "List Name" \
        -underline 0
    set ListNameEntry [ttk::entry .add_edit_list_form.mf.listNameEntry \
        -validate key -validatecommand [callback on_validate %P]]
    ui::apply_edit_bindings $ListNameEntry
    ttk::frame .add_edit_list_form.mf.bf
    ttk::button .add_edit_list_form.mf.bf.ok_button -text OK \
        -underline 0 -compound left -command [callback on_done 1] \
        -image [ui::icon ok.svg $size] -state disabled
    ttk::button .add_edit_list_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
}

oo::define AddEditListForm method prepare {} {
    if {$Lid} {
        lassign [$Pldb list_info $Lid] name cid category _
        $CategoryCombo set $category
        $ListNameEntry insert 0 $name
        $ListNameEntry selection range 0 end
    } else {
        $CategoryCombo set Uncategorized
    }
}

oo::define AddEditListForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    grid .add_edit_list_form.mf.categoryLabel -row 0 -column 0 {*}$opts
    grid $CategoryCombo -row 0 -column 1 -sticky we {*}$opts
    grid .add_edit_list_form.mf.listLabel -row 1 -column 0 {*}$opts
    grid $ListNameEntry -row 1 -column 1 -sticky we {*}$opts
    grid .add_edit_list_form.mf.bf -row 2 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid columnconfigure .add_edit_list_form.mf 1 -weight 1
    pack .add_edit_list_form.mf.bf.ok_button -side right {*}$opts
    pack .add_edit_list_form.mf.bf.cancel_button -side right {*}$opts
    pack .add_edit_list_form.mf -fill both -expand 1
}

oo::define AddEditListForm method make_bindings {} {
    bind $CategoryCombo <<ComboboxSelected>> \
        [callback on_validate [.add_edit_list_form.mf.listNameEntry get]]
    bind .add_edit_list_form <a> {
        focus .add_edit_list_form.mf.categoryCombo}
    bind .add_edit_list_form <l> {
        focus .add_edit_list_form.mf.listNameEntry}
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
    set cid [$Pldb cid_for_name [$CategoryCombo get]]
    set disallowed [$Pldb category_list_names $cid 1]
    if {$name ne "" && $name ni $disallowed} {
        .add_edit_list_form.mf.bf.ok_button configure -state normal
        $ListNameEntry configure -foreground black
    } else {
        .add_edit_list_form.mf.bf.ok_button configure -state disabled
        $ListNameEntry configure -foreground red
        focus $ListNameEntry
    }
    return 1
}

oo::define AddEditListForm method on_done ok {
    if {$ok} {
        set cid [$Pldb cid_for_name [$CategoryCombo get]]
        set name [string trim [$ListNameEntry get]]
        if {!$Lid} {
            set Lid [$Pldb list_insert $cid $name]
        } else {
            $Pldb list_update $cid $Lid $name
        }
        $Reply set $Lid
    } else {
        $Reply set 0
    }
    my delete
}
