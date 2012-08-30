# Support for various non-standard hacks used by dumb feed generators.

namespace eval ::feedparser::p::nonstandard {}

proc ::feedparser::p::nonstandard::hookStart {} {
	variable ::feedparser::validEntry
	variable ::feedparser::validHeadline
	
}

proc ::feedparser::p::nonstandard::hookHeadline { node Result } {
	upvar $Result r

}

proc ::feedparser::p::nonstandard::hookEntry { node Result } {
	upvar $Result r
	variable xmlns

	# Many Ukrainian news agents add to items of their rss/2.0 feeds a
	# 'fulltext' element without supplying a proper namespace for it.
	#
	# That element contains a text that is bigger than a text
	# in 'description' element. I don't know why the fuck is that & who
	# is to blame.
	::feedparser::dom::set_child_text $node fulltext
	if {[string length $fulltext] > [string length $r(description)]} {
		set r(description) $fulltext
	}
}
