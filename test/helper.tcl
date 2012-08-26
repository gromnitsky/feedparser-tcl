if {[file dirname [pwd]] != "test"} { cd "test" }

package require control
control::control assert enabled 1

tcl::tm::path add ../lib

package require tcltest
namespace import -force ::tcltest::*

encoding system utf-8

