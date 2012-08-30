# A small subset of DCMES 1.1 http://dublincore.org/documents/dces/

namespace eval ::feedparser::p::dcmes {
	variable xmlns {
		dublinCore "http://purl.org/dc/elements/1.1/"
	}
}

proc ::feedparser::p::dcmes::hookStart {} {
	variable ::feedparser::validEntry
	variable ::feedparser::validHeadline
	
}

proc ::feedparser::p::dcmes::hookHeadline { node Result } {
	upvar $Result r

}

proc ::feedparser::p::dcmes::hookEntry { node Result } {
	upvar $Result r
	variable xmlns

	array set dc_entry {
		creator author
		title title
	}
	foreach {dcTag entryTag} [array get dc_entry] {
		if {$r($entryTag) == ""} {
			set val [::feedparser::dom::nodesGetAsText $node $xmlns $dcTag]
			if {[llength $val] > 0} {
				set r($entryTag) [lindex $val 0]
			}
		}
	}

	# description
	set desc [lindex [::feedparser::dom::nodesGetAsText $node $xmlns "description"] 0]
	if {[string length $desc] > [string length $r(description)]} {
		set r(description) $desc
	}

	# date
	if {$r(pubDate) == ""} {
		set date [::feedparser::dom::nodesGetAsText $node $xmlns "date"]
		if {[set pubDate [::feedparser::dom::parseDate [lindex $date 0]]] != -1} {
			set r(pubDate) $pubDate
		}
	}
	
}
