# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui

oo::class create MergeListForm {
    superclass AbstractForm

    variable Reply
    variable Pldb
    variable Lid
    variable Data
    variable DataCombo
}

oo::define MergeListForm classmethod show {pldb lid data} {
    set reply [Ref new 0]
    set form [MergeListForm new $reply $pldb $lid $data]
    tkwait window .merge_list_form
    $reply get
}

oo::define MergeListForm constructor {reply pldb lid data} {
    set Reply $reply
    set Pldb $pldb
    set Lid $lid
    set Data $data
    my make_widgets
    my make_layout
    my make_bindings
    next .merge_list_form [callback on_done 0]
    my show_modal ;# TODO
}

oo::define MergeListForm method make_widgets {} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .merge_list_form
    wm resizable .merge_list_form 0 0
    wm title .merge_list_form "Merge — [tk appname]"
    ttk::frame .merge_list_form.mf
    set name [$Pldb list_name $Lid]
    ttk::label .merge_list_form.mf.dataLabel \
        -text "Merge into list “$name” from list" -underline 1
    set items [list]
    foreach datum $Data {
        lassign $datum category_name list_name _
        lappend items "$list_name \[$category_name\]"
    }
    set DataCombo [ttk::combobox .merge_list_form.mf.dataCombo \
        -values $items]
    $DataCombo set [lindex $items 0]
    $DataCombo state readonly
    ttk::frame .merge_list_form.mf.bf
    ttk::button .merge_list_form.mf.bf.merge_button -text Merge \
        -underline 0 -compound left -command [callback on_done 1] \
        -image [ui::icon ok.svg $size]
    ttk::button .merge_list_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
}

oo::define MergeListForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .merge_list_form.mf.dataLabel -side top -anchor w {*}$opts
    pack $DataCombo -side top -fill x -expand 1 {*}$opts
    pack .merge_list_form.mf.bf -side bottom -fill x -expand 1 {*}$opts
    pack .merge_list_form.mf.bf.cancel_button -side right {*}$opts
    pack .merge_list_form.mf.bf.merge_button -side right {*}$opts
    pack .merge_list_form.mf -fill both -expand 1
}

oo::define MergeListForm method make_bindings {} {
    bind .merge_list_form <Escape> {
        .merge_list_form.mf.bf.cancel_button invoke}
    bind .merge_list_form <Return> {
        .merge_list_form.mf.bf.merge_button invoke}
    bind .merge_list_form <Alt-m> {
        .merge_list_form.mf.bf.merge_button invoke}
    bind .merge_list_form <Alt-c> {
        .merge_list_form.mf.bf.cancel_button invoke}
    bind .merge_list_form <Alt-e> {focus .merge_list_form.mf.dataCombo}
}

oo::define MergeListForm method on_done ok {
    if {$ok} {
        set txt [$DataCombo get]
        set i [string last "\[" $txt]
        set list_name [string trim [string range $txt 0 $i-1]]
        set category_name [string trim [string range $txt $i+1 end-1]]
        set cid [$Pldb cid_for_name $category_name]
        set lid [$Pldb lid_for_cid_and_name $cid $list_name]
        $Pldb list_merge $Lid $lid
    }
    $Reply set $ok
    my delete
}
