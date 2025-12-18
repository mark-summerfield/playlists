# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui
package require util

oo::class create DeleteListForm {
    superclass AbstractForm

    variable Reply
}

# Reply is: 0 cancel or 1 move to Uncategorized or 2 delete
oo::define DeleteListForm classmethod show {name cid category n} {
    set reply [Ref new 0]
    set form [DeleteListForm new $reply $name $cid $category $n]
    tkwait window .delete_list_form
    $reply get
}

oo::define DeleteListForm constructor {reply name cid category n} {
    set Reply $reply
    my make_widgets $name $cid $category $n
    my make_layout $cid
    my make_bindings $cid
    next .delete_list_form [callback on_done 0]
    my show_modal .delete_list_form.mf.bf.cancel_button
}

oo::define DeleteListForm method make_widgets {name cid category n} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .delete_list_form
    wm resizable .delete_list_form 0 0
    wm title .delete_list_form "Delete List — [tk appname]"
    ttk::frame .delete_list_form.mf
    if {$cid} {
        set body "Delete list “$name” from category “$category”"
    } else {
        set body "Delete Uncategorized list “$name”"
    }
    if {$n} {
        lassign [util::n_s $n] n s
        set body "$body,\nand move its $n track$s into the Uncategorized\
            Unlisted list?"
    } else {
        set body "$body?"
    }
    if {$cid} {
        set body "$body\n\nOr, move list “$name” to Uncategorized?"
    }
    ttk::label .delete_list_form.mf.label -text $body\n
    ttk::frame .delete_list_form.mf.bf
    ttk::button .delete_list_form.mf.bf.delete_button -text Delete \
        -underline 0 -compound left -command [callback on_done 2] \
        -image [ui::icon list-delete.svg $size]
    if {$cid} {
        ttk::button .delete_list_form.mf.bf.move_button -text Move \
            -underline 0 -compound left -command [callback on_done 1] \
            -image [ui::icon list-move-to-category.svg $size]
    }
    ttk::button .delete_list_form.mf.bf.cancel_button -text Cancel \
        -underline 0 -compound left -command [callback on_done 0] \
        -image [ui::icon close.svg $size]
}

oo::define DeleteListForm method make_layout cid {
    set opts "-padx 3 -pady 3"
    pack .delete_list_form.mf.label -side top -fill both -expand 1 {*}$opts
    pack .delete_list_form.mf.bf -side bottom -fill x -expand 1 {*}$opts
    pack .delete_list_form.mf.bf.cancel_button -side right {*}$opts
    if {$cid} {
        pack .delete_list_form.mf.bf.move_button -side right {*}$opts
    }
    pack .delete_list_form.mf.bf.delete_button -side right {*}$opts
    pack .delete_list_form.mf -fill both -expand 1
}

oo::define DeleteListForm method make_bindings cid {
    bind .delete_list_form <Escape> {
        .delete_list_form.mf.bf.cancel_button invoke}
    bind .delete_list_form <Alt-c> {
        .delete_list_form.mf.bf.cancel_button invoke}
    bind .delete_list_form <Alt-d> {
        .delete_list_form.mf.bf.delete_button invoke}
    if {$cid} {
        bind .delete_list_form <Alt-m> {
            .delete_list_form.mf.bf.move_button invoke}
    }
}

oo::define DeleteListForm method on_done action {
    $Reply set $action
    my delete
}
