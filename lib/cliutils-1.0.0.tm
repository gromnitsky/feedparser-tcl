# -*-tcl-*-

namespace eval cliutils {
	# Preferable exit codes. See sysexits(3) in FreeBSD.
	variable EX_OK 0
	variable EX_USAGE 64
	variable EX_DATAERR 65
	variable EX_NOINPUT 66
	variable EX_NOUSER 67
	variable EX_NOHOST 68
	variable EX_UNAVAILABLE 69
	variable EX_SOFTWARE 70
	variable EX_OSERR 71
	variable EX_OSFILE 72
	variable EX_CANTCREAT 73
	variable EX_IOERR 74
	variable EX_TEMPFAIL 75
	variable EX_PROTOCOL 76
	variable EX_NOPERM 77
	variable EX_CONFIG 78

	# Global verbosity level for errx, warns, veputs, etc
	variable verbose 0
	# veputs uses this to decide to put a newline or not.
	variable NNL_MARK "__NNL__"
}

proc cliutils::debug {} {
	variable verbose
	expr { verbose >= 2 }
}

proc cliutils::errx { exit_code msg {level 0} } {
	variable verbose
	if {$verbose >= $level} {
		puts stderr "[file tail $::argv0] error: $msg"
	}
	if { $exit_code > 0 } { exit $exit_code }
}

proc cliutils::warnx { msg {level 0} } {
	variable verbose
	if {$verbose >= $level} {
		puts stderr "[file tail $::argv0] warning: $msg"
	}
}

proc cliutils::veputs { level msg } {
	variable verbose
	variable NNL_MARK
	
	set nnl false
	if {[regexp -- $NNL_MARK $msg]} {
		regsub -- $NNL_MARK $msg "" msg
		set nnl true
	}

	if {$verbose >= $level} {
		puts [expr {$nnl ? "-nonewline" : "stdout"}] $msg
		flush stdout
	}
}
