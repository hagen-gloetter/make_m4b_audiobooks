#!/usr/bin/perl -w

use 5.004;
use strict;
use CGI qw(:standard);
use English;
use POSIX qw(strftime);
use lib "/home/hagen/cgi-bin_www/";
#use mu_makros;
use MP3::Info;
my $i=0;
my %flds = (
            	TITLE => 'tt',
            	ARTIST => 'ta',
            	ALBUM => 'tl',
            	YEAR => 'ty',
            	COMMENT => 'tc',
            	GENRE => 'tg',
            	TRACKNUM => 'tn'
    	);
my $sd;
my $dd;

  $sd="/audio/Hoerspiele/Die\ drei\ Fragezeichen"; #ohne / am ende
  $dd="/store/appz/wand/ddf";
  &main();

  $sd="/audio/Hoerspiele/Douglas Adams - Per Anhalter Ins All Hörspiel"; #ohne / am ende
  $dd="/store/appz/wand/Anhalter";
  &main();

#  $sd="/audio/Hoerspiele/Perry Rhodan 1-12 + 6 Sonderfolgen";
#  $dd="/store/appz/wand/Perry";
#  &main();

exit;


sub main {
  my $fqsd =$sd;
     $fqsd =~ s/ /\\ /g;    # mask spaces
  my @fq= glob("$fqsd/*mp3");
  my $f;
  foreach $f (@fq)
  {
    print "$i ";
    $i++;
    my $res = get_sample_rate($f);
    print "Skipping: $f \n" if ($res==0);
    next if ($res==0);
    convert ($f);
  }
}

sub get_sample_rate {
    my $fn = shift;
    my %info = %{get_mp3info ($fn)}; # reference nach hash casten
#      foreach (keys %info){
#        print "$_ = $info{$_}\n";
#      }
    my $frq= $info{"FREQUENCY"};
    my $vbr= $info{"VBR"};
    $frq=$frq*1000;
    print "\nFRQ=$frq\tVBR=$vbr\n";
    return 0 if ($frq <= 22050);
    return 0 if ($vbr > 0 && $frq == 22050 );
    return 1 ;
}

sub convert {
   my $src = shift ;
   my $dst=$src;
   $dst=~ s/$sd/$dd/;
    my $s = "lame \"${src}\" " . &makeid3args( $src ) . " \"$dst\" --resample 22.05 -mj --vbr-new -V3";
    print "[${s}]\n";
    system( $s );
}

sub makeid3args( $ )
{
	my $s;
	if ( my $tag = get_mp3tag( @_->[ 0 ] ) )
	{
		for ( keys %flds )
		{
			if ( $tag->{ $_ } )
			{
				$s .= sprintf( "--%s \"%s\" ", %flds->{ $_ }, $tag->{ $_ } );
			}
		}
	}
	return $s || "";
}

