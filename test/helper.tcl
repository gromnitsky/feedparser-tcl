if {[file tail [pwd]] != "test"} { cd "test" }

package require control
control::control assert enabled 1

tcl::tm::path add ../lib

if {[lsearch [namespace children] ::tcltest] == -1} {
	package require tcltest
	namespace import -force ::tcltest::*
}

encoding system utf-8
