#!/usr/bin/perl -w
#
# Usage:   build_inetd_conf_ycp
#
# writes a inetd.conf in ycp notation to /tmp as inetd_conf.ycp
#	-v	verbose
#	-d	debug
#
# Author: Michael Hager <mike@suse.de>
#         Klaas Freitag <freitag@suse.de>

use strict;
use English;
use Getopt::Std;
use vars qw( $opt_v $opt_d );


# Global variables.

my $verbose		= 0;
my $debug		= 0;
my $tmp			= "$PID.tmp";
my $date                = "1.1.1900";

# Call the main function and exit.
# DO NOT enter any other code outside a sub!
#
# This is not just to satisfy C programmers - rather, this is intended
# to keep global things like the variables above apart from main
# program (local) variables. It is just too easy to mix things up; one
# simple 'i' variable in the main program might too easily be mixed up
# with a function's forgotten 'i' declaration.

main();
exit 0;


#-----------------------------------------------------------------------------


# Main program.

sub main()
{
    my $file;

    # Extract command line options.
    # This will set a variable opt_? for any option,
    # e.g. opt_v if option '-v' is passed on the command line.

    getopts('vd');

    $verbose	= 1 if $opt_v;
    $debug	= 1 if $opt_d;

    
    # set globale variables:
    # - new packagename
    # - maintainer
    # - email adress from maintainer
    # - the target dir and create it
    # - the date
 
    $date = system("date");

    my ( $src ) = @_;
    my $line;
    my $target;

   
    #    # check if the filname has to be changed
    #    # The inetd will re-read this file whenever it gets that signal.
    #    #
    #    # <service_name> <sock_type> <proto> <flags> <user> <server_path> <args>
    #    #
    #    # echo  dgram   udp     wait    root    internal
    #    # discard       stream  tcp     nowait  root    internal
    #    ftp     stream  tcp     nowait  root    /usr/sbin/tcpd  in.ftpd
    # 
    ##### to
    #
    #	[ $[ `status:`active,    "service":"time", "type":"dgram" "protocol":"udp", "flags":"wait", "servargs":"internal", "user":"root", "line_number":1 ],
    #	  $[ `status:`inactive,  "service":"time", "type":"dgram" "protocol":"udp", "flags":"wait", "servargs":"internal", "user":"root", "line_number":2 ],
    #	  $[ `status:`comment, "comment":" If you make changes to this file, ", "line_number"=3 ],


    open ( SRC,     "/etc/inetd.conf"      ) or die "EXITING cause:: Can't open: $!";
    open ( TARGET, ">/tmp/inetd_conf.ycp"  ) or die "EXITING cause:: Can't open: $!";
    my $res;
    my $first = 1;
    my $linecount = 0;

    print TARGET "[ "; 
    while (my $l =  <SRC> )
    {
      my @linc = ();
      # print "$l";
      $linecount++;
      if ( $l =~ /^\#.*/ ) 
      {
         # Comment-Handling
         my $line = $l;
	 $line =~ s/"/\\"/g;
         @linc = split( /\s+/, $line );  

	 my $anz = @linc;
	 my ($commentsign, $du1, $prot)  = @linc;

	 shift @linc;

	 if( defined $prot && ($prot eq "dgram" || $prot eq "stream" || 
             $prot eq "raw" || $prot eq "rdm" || $prot eq "seqpacket" ))
         {
	 print "DE $anz <$prot> $linecount\n";
	     $res = sprintf( '$[ `status:`inactive, "service":"%s", "type":"%s", "protocol":"%s", "flags":"%s", "user":"%s", "servargs":"%s", "line_number": %d ] ',
		    shift @linc, shift@ linc, shift @ linc, shift @linc, 
                    shift @linc, join( " ", @linc ), $linecount );
	 }
         else
         {
	     $res = sprintf( '$[ `status:`comment, "comment":"%s", "line_number": %d ]', join( " ", @linc ), $linecount);
	 }
      }
      else 
      {  
	 @linc = split( /\s+/, $l );
	 $res = sprintf( '$[ `status:`active, "service":"%s", "type":"%s", "protocol":"%s", "flags":"%s", "user":"%s", "servargs":"%s", "line_number": %d ] ',
			shift @linc, shift@ linc, shift @ linc, 
                        shift @linc, shift @linc, join( " ", @linc ), $linecount );
      }

      if( $first )
	{
	  print TARGET "$res";
	  $first  = 0;
	}
      else
	{
	  print TARGET ",\n $res";
	}
    }

    print TARGET " ]\n";

    close ( TARGET );
    close ( SRC );
}




#-----------------------------------------------------------------------------


# Log a message to stderr.
#
# Parameters:
#	Messages to write (any number).

sub warning()
{
    my $msg;

    foreach $msg ( @_ )
    {
	print STDERR $msg . " ";
    }

    print STDERR "\n";
}


#-----------------------------------------------------------------------------


# Log a message to stdout if verbose mode is set
# (command line option '-v').
#
# Parameters:
#	Messages to write (any number).

sub logf()
{
    my $msg;

    if ( $verbose )
    {
	foreach $msg ( @_ )
	{
	    print $msg . " ";
	}

	print "\n";
    }
}


#-----------------------------------------------------------------------------


# Log a debugging message to stdout if debug mode is set
# (command line option '-d').
#
# Parameters:
#	Messages to write (any number).

sub deb()
{
    my $msg;

    if ( $debug )
    {
	print '   DEB> ';

	foreach $msg ( @_ )
	{
	    print $msg . " ";
	}

	print "\n";
    }
}


#-----------------------------------------------------------------------------


# Print usage message and abort program.
#
# Parameters:
#	---

sub usage()
{
    die "\n\nUsage: $0 [-vd] <new package name> <maintainer> <email>\n\n";
}

# EOF
