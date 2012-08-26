# -*-tcl-*-

package require tdom

package require cliutils

# set feed [feedparser::parse $xml]
# puts [$feed feed title]
# puts [$feed entry 12 description]
# puts [$feed size]
# puts [$feed entries]
namespace eval feedparser {
	variable objCount 0

	variable validHeadline \
		[list copyright description generator link managingEditor title]
	variable validEntry \
		[list author author_email comments description guid link pubDate title]
}

# Constructor
proc feedparser::objNew {} {
	variable objCount
	
	set self [namespace current]
	namespace eval [incr objCount] {
		variable d [dict create]
		dict set d f [dict create]
		foreach i $feedparser::validHeadline { dict set d f $i {} }
		dict set d e []
	}

	interp alias {} ${self}::$objCount {} ${self}::dispatch $objCount
	return ${self}::$objCount
}

# Method dispatcher
proc feedparser::dispatch {this cmd args} {
	eval $cmd $this $args
}

# Destructor (invoked by dispatch as every other 'instance method')
proc feedparser::objDelete {this} {
	namespace delete $this
    interp alias {} [namespace current]::$this {}	
}

# Getter
proc feedparser::headline { this param } {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d f $param]} {
		dict get $d f $param
	} else {
		return ""
	}
}

# Return all headlines
proc feedparser::headlines { this } {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	dict get $d f
}

# Setter
proc feedparser::headlineSet { this param val } {
	variable validHeadline
	
	# $d == ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d f $param]} {
		dict set ${this}::d f $param $val
	} else {
		error "invalid feed parameter '$param': must be [join $validHeadline ", "]"
	}
}

# Return length of feed entries
proc feedparser::size {this} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]
	
	dict size [dict get $d e]
}

# Getter
proc feedparser::entry {this n param} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d e $n $param]} {
		dict get $d e $n $param
	} else {
		return ""
	}
}

# Setter
proc feedparser::entrySet {this n param val} {
	variable validEntry
	
	if {[lsearch $validEntry $param] == -1} {
		error "invalid entry parameter '$param': must be [join $validEntry {, }]"
	}
	
	set d [set ${this}::d]
	if {![dict exists $d e $n]} {
		dict set ${this}::d e $n [dict create]
	}

	dict set ${this}::d e $n $param $val
}

# Return all entries
proc feedparser::entries {this} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]
	
	dict get $d e
}


namespace eval feedparser::u {
    # iana_charsets -> tcl_charset_names
    array set enc {
		us-ascii ascii
		utf-8 utf-8
		utf-16 unicode
		iso-8859-1 iso8859-1
		iso-8859-2 iso8859-2
		iso-8859-3 iso8859-3
		iso-8859-4 iso8859-4
		iso-8859-5 iso8859-5
		iso-8859-6 iso8859-6
		iso-8859-7 iso8859-7
		iso-8859-8 iso8859-8
		iso-8859-9 iso8859-9
		iso-8859-10 iso8859-10
		iso-8859-13 iso8859-13
		iso-8859-14 iso8859-14
		iso-8859-15 iso8859-15
		iso-8859-16 iso8859-16
		iso-2022-kr iso2022-kr
		euc-kr euc-kr
		iso-2022-jp iso2022-jp
		koi8-r koi8-r
		koi8-u koi8-u
		shift_jis shiftjis
		euc-jp euc-jp
		gb2312 gb2312
		big5 big5
		cp866 cp866
		cp1250 cp1250
		cp1253 cp1253
		cp1254 cp1254
		cp1255 cp1255
		cp1256 cp1256
		cp1257 cp1257

		windows-1251 cp1251
		cp1251 cp1251

		windows-1252 cp1252
		cp1252 cp1252

		iso_8859-1:1987 iso8859-1
		iso-ir-100 iso8859-1
		iso_8859-1 iso8859-1
		latin1 iso8859-1
		l1 iso8859-1
		ibm819 iso8859-1
		cp819 iso8859-1
		csisolatin1 iso8859-1

		iso_8859-2:1987 iso8859-2
		iso-ir-101 iso8859-2
		iso_8859-2 iso8859-2
		iso-8859-2 iso8859-2
		latin2 iso8859-2
		l2 iso8859-2
		csisolatin2 iso8859-2

		iso_8859-5:1988 iso8859-5
		iso-ir-144 iso8859-5
		iso_8859-5 iso8859-5
		iso-8859-5 iso8859-5
		cyrillic iso8859-5
		csisolatincyrillic iso8859-5

		ms_kanji shiftjis
		csshiftjis shiftjis

		csiso2022kr iso2022-kr

		ibm866 cp866
		csibm866 cp866
    }
}

proc feedparser::u::iana2tcl {iana} {
	variable enc

	set iana [string tolower $iana]
	if {[info exists enc($iana)]} { return $enc($iana) }
	return ""
}

# filename -- XML file
#
# Return: an encoding name or "utf-8" if encoding wasn't found.
#
# Side effects:
# * i/o errors
# * stderr warning if encoding wasn't found
proc feedparser::u::getEncoding { filename } {
	set enc "utf-8"
	
	set fd [open $filename]
	fconfigure $fd -encoding binary -translation binary
	set bytes [read $fd 1024]
	close $fd

	if {[regexp {<\?xml[^>]+encoding=["']([^\"']*)["']} $bytes match e] } {
		if {[set e [iana2tcl $e]] != ""} {
			set enc $e
		} else {
			cliutils::warnx "[file tail $filename]: unknown encoding" 1
		}
	} else {
		cliutils::warnx "[file tail $filename]: no encoding specified" 1
	}
	
	return $enc
}


namespace eval feedparser::dom {}

proc feedparser::dom::parse { xml } {
	# pre-process xml to remove any processing instruction
	regsub {^<\?xml [^\?]+\?>} $xml {<?xml version="1.0"?>} xml

	set doc [dom parse $xml]
	set doc_node [$doc documentElement]
	set node_name [$doc_node nodeName]
	
	# feed is the doc-node name for atom
	if { [lsearch {rdf RDF rdf:RDF rss feed} $node_name] == -1 } {
		error "XML is not rdf, RDF, rdf:RDF, rss or atom"
	}

	set feed [feedparser::objNew]
	if {$node_name != "feed"} {
		# looks like rss/rdf
		set doc_node [$doc_node getElementsByTagName channel]
	}

	foreach {key val} [parseHeadline $doc_node] {
		$feed headlineSet $key $val
	}
	
	$doc delete
	return $feed
}

# If node contains a child node named child, the variable child is set
# to the text of that node in the caller's stack frame. If the node
# doesn't exist, set the text to an emptry string in the caller's stack
# frame.
#
# param node: A tDOM node which is supposed to contain the child
# param child: The name of the child
# return: Nothing
proc feedparser::dom::set_child_text {node child} {
	if { $node == "" || ![$node hasChildNodes] } return

	set child_nodes ""
	foreach i [$node selectNodes "*"] {
		if {[$i nodeName] == $child} {
			set child_nodes $i
			break
		}
	}
		
	upvar $child var
	if { [llength $child_nodes] == 1 } {
		set child_node [lindex $child_nodes 0]
		set var [string trim [$child_node text]]
	} else {
		set var ""
	}
}

proc feedparser::dom::parseHeadline { node } {
	variable ::feedparser::validHeadline

	array set r {}
	foreach i $validHeadline { set r($i) ""	}

	foreach idx [array names r] {
		feedparser::dom::set_child_text $node $idx
		if {[info exists $idx]} { set r($idx) [set $idx] }
	}
	
	if {$r(managingEditor) != ""} {
		if {[regexp -- {(\S+@\S+\.\S+)(\s+\(.+\))?} $r(managingEditor) match email name]} {
			set r(managingEditor) $email
			if {[regexp -- {\w+} $name]} {
				append r(managingEditor) " [string trim $name]"
			}
		} else {
			# invalid, clear it
			set r(managingEditor) ""
		}
	}
	
	# do weird stuff for atom
	if {[$node nodeName] == "feed"} {
		# link
		if {$r(link) == ""} {
			# link is in a href
			set link_node [$node selectNodes {*[local-name()='link' and @rel = 'alternate' and @type = 'text/html']/@href}]
			if { [llength $link_node] >= 1 } {
				set link_node [lindex $link_node 0]
				set r(link) [lindex $link_node 1]
			}
		}
		
		# author
		set author_node [$node selectNodes {*[local-name()='author']}]
		if { [llength $author_node] == 1 } {
			set author_node [lindex $author_node 0]
			feedparser::dom::set_child_text $author_node name
			feedparser::dom::set_child_text $author_node email
			if {[regexp -- {\S+@\S+\.\S+} $email match]} {
				set r(managingEditor) $match
				if {[regexp -- {\w+} $name]} {
					append r(managingEditor) " ([string trim $name])"
				}
			}
		}
	}
	

	return [array get r]
}
