# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui

oo::class create ChooseListForm {
    superclass AbstractForm

    variable Reply
    variable Pldb
    variable Lid
    variable Data
    variable DataCombo
}

# Returns an lid or -1 on cancel; action should be Copy or Move or Merge
oo::define ChooseListForm classmethod show {action body pldb lid data} {
    set reply [Ref new -1]
    set form [ChooseListForm new $reply $action $body $pldb $lid $data]
    tkwait window .choose_list_form
    $reply get
}

oo::define ChooseListForm constructor {reply action body pldb lid data} {
    set Reply $reply
    set Pldb $pldb
    set Lid $lid
    set Data $data
    my make_widgets $action $body
    my make_layout
    my make_bindings
    next .choose_list_form [callback on_done 0]
    my show_modal $DataCombo
}

oo::define ChooseListForm method make_widgets {action body} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .choose_list_form
    wm resizable .choose_list_form 0 0
    wm title .choose_list_form "$action — [tk appname]"
    ttk::frame .choose_list_form.mf
    set name [$Pldb list_name $Lid]
    ttk::label .choose_list_form.mf.dataLabel -text $body
    set items [list]
    foreach datum $Data {
        lassign $datum category_name list_name _
        lappend items "$category_name · $list_name"
    }
    set DataCombo [ttk::combobox .choose_list_form.mf.dataCombo \
        -values $items]
    $DataCombo set [lindex $items 0]
    $DataCombo state readonly
    ttk::frame .choose_list_form.mf.bf
    ttk::button .choose_list_form.mf.bf.action_button -text $action \
        -underline 0 -compound left -command [callback on_done 1] \
        -image [ui::icon ok.svg $size]
    ttk::button .choose_list_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
}

oo::define ChooseListForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .choose_list_form.mf.dataLabel -side top -anchor w {*}$opts
    pack $DataCombo -side top -fill x -expand 1 {*}$opts
    pack .choose_list_form.mf.bf -side bottom -fill x -expand 1 {*}$opts
    pack .choose_list_form.mf.bf.cancel_button -side right {*}$opts
    pack .choose_list_form.mf.bf.action_button -side right {*}$opts
    pack .choose_list_form.mf -fill both -expand 1
}

oo::define ChooseListForm method make_bindings {} {
    bind .choose_list_form <Escape> {
        .choose_list_form.mf.bf.cancel_button invoke}
    bind .choose_list_form <Return> {
        .choose_list_form.mf.bf.action_button invoke}
    bind .choose_list_form <Alt-m> {
        .choose_list_form.mf.bf.action_button invoke}
    bind .choose_list_form <Alt-c> {
        .choose_list_form.mf.bf.cancel_button invoke}
    bind .choose_list_form <Alt-e> {focus .choose_list_form.mf.dataCombo}
}

oo::define ChooseListForm method on_done ok {
    if {$ok} {
        set txt [$DataCombo get]
        set i [string first · $txt]
        set list_name [string trim [string range $txt $i+1 end]]
        set category_name [string trim [string range $txt 0 $i-1]]
        set cid [$Pldb cid_for_name $category_name]
        $Reply set [$Pldb lid_for_cid_and_name $cid $list_name]
    }
    my delete
}
