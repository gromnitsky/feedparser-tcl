A small Atom/RSS parser in Tcl 8.5+.

Run `bin/feedparser` to test parsing of `test/data/feeds/*` files.

This is a more clean version of ancient parser shipped with pr2nntp (I
don't like that program).

A basic usage of the API:

	tcl::tm::path add /path/to/lib/files
	package require feedparser
	
	encoding system utf-8

	set xml [feedparser::u::readXML "my/file.xml"]
	set feed [feedparser::dom::parse $xml]

	puts [$feed headline title]
	puts [$feed entry 1 description]
	puts [$feed entryWhole 1]

	puts [$feed size]
	puts [$feed headlines]
	puts [$feed entries]

	# if you don't need the parsing object anymore
	$feed objDelete


__TODO:__

* xml namespaces as plugins
* more tests on shady feeds
