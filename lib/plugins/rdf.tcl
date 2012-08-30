# RDF 1.0 content:encoded

namespace eval ::feedparser::p::rdf {
	variable xmlns {
		rdf "http://purl.org/rss/1.0/modules/content/"
	}
}

proc ::feedparser::p::rdf::hookStart {} {
	variable ::feedparser::validEntry
	variable ::feedparser::validHeadline
	
}

proc ::feedparser::p::rdf::hookHeadline { node Result } {
	upvar $Result r

}

proc ::feedparser::p::rdf::hookEntry { node Result } {
	upvar $Result r
	variable xmlns

	set ce [lindex [::feedparser::dom::nodesGetAsText $node $xmlns "encoded"] 0]
	if {[string length $ce] > [string length $r(description)]} {
		set r(description) $ce
	}
}
