# -*-tcl-*-

package require tdom

package require cliutils
package require htmlhug

# set feed [feedparser::u::parse $xml]
# puts [$feed headline title]
# puts [$feed headlines]
# puts [$feed entry 12 description]
# puts [$feed entryWhole 12]
# puts [$feed size]
# puts [$feed entries]
namespace eval ::feedparser {
	variable objCount 0

	# list of lists: managingEditor
	# list: webMaster
	variable validHeadline \
		[list copyright description generator link managingEditor webMaster \
			 title]

	# list of lists: author, enclosure
	# list: category
	variable validEntry \
		[list author comments description guid link pubDate title \
			 category enclosure]

	# plugins
	variable pluginsList [list]
	variable pluginsDir [file dirname [info script]]/plugins

	# load all
	foreach idx [glob $pluginsDir/*.tcl] {
		source $idx
		lappend pluginsList [regsub -- {\.tcl$} [file tail $idx] ""]
	}

	# execute hookStart for each plugin
	foreach idx $pluginsList {
		::feedparser::p::${idx}::hookStart
	}
}

# Constructor
proc ::feedparser::objNew {} {
	variable objCount
	
	set self [namespace current]
	namespace eval [incr objCount] {
		variable d [dict create]
		dict set d f [dict create]
		foreach i $::feedparser::validHeadline { dict set d f $i {} }
		dict set d e [dict create]
	}

	interp alias {} ${self}::$objCount {} ${self}::dispatch $objCount
	return ${self}::$objCount
}

# Method dispatcher
proc ::feedparser::dispatch {this cmd args} {
	eval $cmd $this $args
}

# Destructor (invoked by dispatch as every other 'instance method')
proc ::feedparser::objDelete {this} {
	namespace delete $this
    interp alias {} [namespace current]::$this {}	
}

# Getter
proc ::feedparser::headline { this param } {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d f $param]} {
		dict get $d f $param
	} else {
		return ""
	}
}

# Return all headlines
proc ::feedparser::headlines { this } {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	dict get $d f
}

# Setter
proc ::feedparser::headlineSet { this param val } {
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
proc ::feedparser::size {this} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	dict size [dict get $d e]
}

# Getter
proc ::feedparser::entry {this n param} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d e $n $param]} {
		dict get $d e $n $param
	} else {
		return ""
	}
}

# Getter
proc ::feedparser::entryWhole {this n} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]

	if {[dict exists $d e $n]} {
		dict get $d e $n
	} else {
		return ""
	}
}

# Setter
proc ::feedparser::entrySet {this n param val} {
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

# Setter
proc ::feedparser::entryWholeSet {this n vals} {
	foreach {key val} $vals {
		entrySet $this $n $key $val
	}
}

# Return all entries
proc ::feedparser::entries {this} {
	# ::feedparser::NUMBER::d
	set d [set ${this}::d]
	
	dict get $d e
}


namespace eval ::feedparser::u {
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

proc ::feedparser::u::iana2tcl {iana} {
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
proc ::feedparser::u::getEncoding { filename } {
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

# Return a xml string
proc ::feedparser::u::readXML { filename } {
	set enc [getEncoding $filename]
	set fd [open $filename]
	fconfigure $fd -encoding $enc
	set xml [read $fd]
	close $fd

	return $xml
}

# Return a ::feedparser::NUMBER object
proc ::feedparser::u::parse { filename } {
	set xml [readXML $filename]
	return [::feedparser::dom::parse $xml]
}

proc ::feedparser::u::pluginsRun {hook node Result} {
	upvar $Result r
	variable ::feedparser::pluginsList

	foreach idx $::feedparser::pluginsList {
		::feedparser::p::${idx}::${hook} $node r
	}
}

namespace eval ::feedparser::dom {}

proc ::feedparser::dom::parse { xml } {
	# pre-process xml to remove any processing instruction
	regsub {<\?xml\s[^\?]+\?>} $xml {<?xml version="1.0"?>} xml

	set doc [dom parse $xml]
	set doc_node [$doc documentElement]
	set node_name [$doc_node nodeName]
	
	# feed is the doc-node name for atom
	if { [lsearch {rdf RDF rdf:RDF rss feed} $node_name] == -1 } {
		error "XML is not rdf, RDF, rdf:RDF, rss or atom"
	}

	set feed [::feedparser::objNew]
	if {$node_name != "feed"} {
		# looks like rss/rdf
		set doc_node [$doc_node getElementsByTagName channel]
	}

	# get headline
	foreach {key val} [parseHeadline $doc_node] {
		$feed headlineSet $key $val
	}

	# get entries
	set enum 0
	foreach idx [parseEntries $doc_node] {
		$feed entryWholeSet $enum $idx
		incr enum
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
proc ::feedparser::dom::set_child_text {node child} {
	if { $node == "" || ![$node hasChildNodes] } return

	set child_nodes ""
	foreach i [$node selectNodes "*"] {
		if {[$i nodeName] == $child} {
			set child_nodes $i
			break
		}
	}
		
	upvar $child var
	if { [llength $child_nodes] >= 1 } {
		set child_node [lindex $child_nodes 0]
		set var [string trim [$child_node text]]
	} else {
		set var ""
	}
}

proc ::feedparser::dom::parseHeadline { node } {
	variable ::feedparser::validHeadline

	array set r {}
	foreach idx $validHeadline { set r($idx) ""	}

	foreach idx [array names r] {
		set_child_text $node $idx
		if {[info exists $idx]} { set r($idx) [set $idx] }
	}
	
	# atom
	if {[$node nodeName] == "feed"} {
		# link
		set r(link) [parseAtomLink $node]
		
		# author
		set r(webMaster) ""; # not in atom spec
		set r(managingEditor) [parseAtomAuthor $node]

		# copyright
		set_child_text $node rights
		set r(copyright) $rights
	} else {
		# many
		set m [::feedparser::u::parseRssPerson $r(managingEditor)]
		set r(managingEditor) [expr {$m != "" ? [list $m] : [list]} ]
		# one
		set r(webMaster) [::feedparser::u::parseRssPerson $r(webMaster)]
	}
	
	# run plugins
	::feedparser::u::pluginsRun hookHeadline $node r

	return [array get r]
}

# Return {author email} list
proc ::feedparser::u::parseRssPerson { rawValue } {
	set r [list]

	# possible values:
	#
	# john@example.com (John Doe)
	# John Doe <john@example.com>

	set mailRegexp \
		{[a-zA-Z0-9#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9\[:_.-]*[a-zA-Z0-9\]]}
	
	if {[regexp -- $mailRegexp $rawValue email]} {
		regsub -- $mailRegexp $rawValue "" name
		set name [string trim $name " \t()<>"]
		set r [list $name $email]
	} else {
		if {$rawValue != "" } {
			set r [list [string trim $rawValue] {}]
		}
	}

	return $r
}

proc ::feedparser::dom::parseRssPerson {node nodeName} {
	set r [list]
	if {$node == "" || $nodeName == ""} { return $r }

	# as I understand only 1 node of person constructs is allowed for
	# rss feeds.
	set_child_text $node $nodeName
	::feedparser::u::parseRssPerson [set $nodeName]
}

# Return:
# big system-dependent integer value -- okay
# -1 -- error
proc ::feedparser::dom::parseDate { date } {
	# In the past we were removing timezone, so any date was right only
	# if it was in GMT. Now with the power of Tcl 8.5 clock command we
	# can construct a proper parameter for -format option.

	if {[regexp -- {^[A-Z][a-z]{2}, \d} $date]} {
		# suppose the date is in rfc822 format
		# (for example, Sun, 04 Nov 2007 18:08:00 +0200)
		set f "%a, %e %b %Y %T"
		if {[regexp -- {^[A-Z][a-z]{2}, \d+ \S+ \d+ \d\d:\d\d[^:]} $date]} {
			# some feed (de)generators don't want to include seconds
			# in the date
			set f "%a, %e %b %Y %H:%M"
		}
		lappend f "$f %z"
	} else {
		# suppose the date is in ISO8601 format,
		# see http://en.wikipedia.org/wiki/ISO8601
		set f "%Y-%m-%dT%T"
		if {[regexp -- {^\d+-\d+-\d+T\d+:\d+:\d+(\.\d+)} $date match ms]} {
			# blogger.com form
			set f "%Y-%m-%dT%T${ms}"
		}
		lappend f "${f}%z"
	}

	foreach i $f {
		if {![catch {clock scan $date -format $i -timezone :UTC} result]} {
			return $result
		}
	}

	# a final try
	if {$date != "" && ![catch {clock scan $date -timezone :UTC} result]} {
		return $result
	}
		
	return -1
}

proc ::feedparser::dom::parseEntries { node } {
	set r []
	set entries [$node selectNodes {//*[local-name()='item' or local-name()='entry']}]

	foreach idx $entries {
		lappend r [parseEntry $idx]
	}
	
	return $r
}

proc ::feedparser::dom::parseEntry { node } {
	variable ::feedparser::validEntry

	array set r {}
	foreach idx $validEntry { set $idx "" }
	
	set_child_text $node title
	set_child_text $node link
	set_child_text $node guid
	set_child_text $node comments; # rss
	set_child_text $node pubDate;  # rss

	# a small hack with date
	if {$pubDate == ""} {
		foreach idx {updated published} {
			::feedparser::dom::set_child_text $node $idx
			if {[set pubDate [set $idx]] != ""} break
		}
	}
	if {[set pubDate [parseDate $pubDate]] == -1} { set pubDate "" }

	set maybe_atom_p 0

	# try to handle atom link
	if {$link == ""} {
		if {[set link [parseAtomLink $node]] != ""} {
			set maybe_atom_p 1
		}
	}

	if {$link == "" && $guid != ""} { set link $guid }
	
	# try to handle atom guid
	if {$guid == ""} {
		set_child_text $node id
		if {$id != ""} {
			set guid $id
			set maybe_atom_p 1
		}
	}

	set category [parseCategory $node $maybe_atom_p]
	set enclosure [parseEnclosure $node $maybe_atom_p]
	set description [parseDescription $node $maybe_atom_p]

	set author [parseAuthor $node $maybe_atom_p]

	foreach idx $::feedparser::validEntry {
		set r($idx) [set $idx]
	}

	# run plugins
	::feedparser::u::pluginsRun hookEntry $node r

	# remove unsafe html
	set r(description) [htmlhug::tagsRemoveUnsafe $r(description)]

	return [array get r]
}

# Return text values of all nodes names nodeName. Return an empty list
# for non-existing nodeName.
#
# node -- a node to start search with
# xmlns -- a list {namespace1 uri namespace2 uri ...}
# nodeName -- a local node name, without a namespace prefix
proc ::feedparser::dom::nodesGetAsText { node xmlns nodeName } {
	if {$node == "" || $xmlns == "" || $nodeName == ""} { return [list] }
	
	set n [$node selectNodes -namespaces $xmlns \
			   [format {*[local-name()='%s']} $nodeName] ]
	if {[llength $n] > 0} {
		set r [list]
		foreach idx $n { lappend r [string trim [$idx text]] }
		return $r
	}
	
	return [list]
}

proc ::feedparser::dom::parseCategory { node isAtom } {
	if {$node == ""} { return [list] }
	
	set r [list]
	
	if {$isAtom} {
		# prefer 'term'
		foreach idx {term label} {
			set cats [$node selectNodes \
						  [format {*[local-name()='category']/@%s} $idx] ]
			foreach c $cats {
				# c is "term {value}"
				lappend r [string trim [lindex $c 1]]
			}
			break
		}
	} else {
		set cats [$node selectNodes {*[local-name()='category']} ]
		foreach c $cats {
			lappend r [string trim [$c text]]
		}
	}

	return $r
}

proc ::feedparser::dom::parseEnclosure { node isAtom } {
	if {$node == ""} { return [list] }
	
	set r [list]
	
	if {$isAtom} {
		foreach idx [$node selectNodes {*[local-name()='link' and @rel='enclosure']} ] {
			lappend r [list [string trim [$idx getAttribute type ""]] \
						   [string trim [$idx getAttribute length 0]] \
						   [string trim [$idx getAttribute href ""]] ]
		}
	} else {
		foreach idx [$node selectNodes {*[local-name()='enclosure']}] {
			lappend r [list [string trim [$idx getAttribute type ""]] \
						   [string trim [$idx getAttribute length 0]] \
						   [string trim [$idx getAttribute url ""]] ]
		}
	}

	return $r
}

# Return a list {author author_email]
proc ::feedparser::dom::parseAuthor { node isAtom } {
	set r [list]
	if {$node == ""} { return $r }
	
	if {$isAtom} {
		set r [parseAtomAuthor $node]
	} else {
		set a [parseRssPerson $node "author"]
		set r [expr {$a != "" ? [list $a] : [list]} ]
	}

	return $r
}

proc ::feedparser::dom::parseAtomAuthor { node } {
	set r [list]
	if {$node == ""} { return $r }

	foreach idx [$node selectNodes {*[local-name()='author']}] {
		set_child_text $idx name
		set_child_text $idx email
		lappend r [list $name $email]
	}

	return $r
}

proc ::feedparser::dom::parseDescription { node isAtom } {
	if {$node == ""} { return "" }
	
	set r ""
	
	if {$isAtom} {
		# atom:entry elements MUST NOT contain more than one
		# atom:content or atom:summary element.
		#
		# there is no descruption but summary & content; we will use the
		# bigger one as the description.
		set_child_text $node summary
		set r $summary
		
		set_child_text $node content
		if {[string length $content] > [string length $summary]} {
			set r $content
		}
	} else {
		set_child_text $node description
		set r $description
	}

	return $r
}

proc ::feedparser::dom::parseAtomLink { node } {
	if {$node == ""} { return "" }

	set r ""
	# If the "rel" attribute is not present, the link element
	# MUST be interpreted as if the link relation type is
	# "alternate".
	foreach idx [$node selectNodes {*[local-name()='link']} ] {
		set isRel [string trim [$idx getAttribute rel ""]]
		
		if {$isRel == "" || $isRel eq "alternate"} {
			set r [string trim [$idx getAttribute href ""]]
			break
		}
	}
	
	return $r
}
