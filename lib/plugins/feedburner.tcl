# Restore original link in feedburner proxy feeds.
# https://developers.google.com/feedburner/feedburner_namespace_reference

namespace eval ::feedparser::p::feedburner {
	variable xmlns {
		feedburner "http://rssnamespace.org/feedburner/ext/1.0"
	}
}

proc ::feedparser::p::feedburner::hookStart {} {
	variable ::feedparser::validEntry
	variable ::feedparser::validHeadline
	
}

proc ::feedparser::p::feedburner::hookHeadline { node Result } {
	upvar $Result r

}

proc ::feedparser::p::feedburner::hookEntry { node Result } {
	upvar $Result r
	variable xmlns

	set origlink [lindex [::feedparser::dom::nodesGetAsText $node $xmlns "origLink"] 0]
	if {$origlink != ""} {
		set r(link) $origlink
	}
}
