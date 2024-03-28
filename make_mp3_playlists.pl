#!/usr/bin/perl -w

use 5.004;
use strict;
use English;

my  $debug          = 0;    # debug level
my  $fqscriptname   = $0;
    $_=$fqscriptname; m#(.*)/(.*)$#;
my  $callpfad       = $1;
my  $scriptname     = $2;
my  @args           = @ARGV;
    $|=1;

my  $pfad = $args[0] || $callpfad;
    $pfad =~ s#/$##;
    print "Erzeuge Playlisten beginnend ab Pfad:$pfad<\n";
    &getFileList_recursive ($pfad);
    print "\n";
exit ;

sub getFileList {
  my $pfad=shift;
  my  $ext=shift;
  my @files=glob("$pfad/*$ext");
  s#.*/## for @files; # remove part before last slash
  foreach (@files) {
    print "$_\n";
    }
  return @files;
}

sub getFileList_recursive{
  my $startdir = shift;
  my $pattern= "mp[e]3";
  my @dirlist=();
  my @filelist=();
  &search_file_in_dir($startdir);
}

sub search_file_in_dir(){
    my $dir=shift;
    my @array=();
    my @flist=();
    if (opendir(DIRH,"$dir")){
      @flist=readdir(DIRH);
      closedir DIRH;
      foreach (sort @flist){
        # ignore . and .. :
        next if ($_ eq "." || $_ eq "..");
        if (/mp3$/io){
          push (@array, "$dir/$_");
        }
        if (-d "$dir/$_" && ! -l "$dir/$_"){
          my @parray = &search_file_in_dir("$dir/$_") ;
          @array = (@array,@parray);
        }
        my  @tarray=@array;
        s#$dir## for @tarray;
        s#^/## for @tarray;
        &write_m3u ("$dir",@tarray);
      }
    }else{
      print "\nERROR: can not read directory $dir\n";
    }
    return @array;
}

sub write_m3u {
  my  $dir=shift;
  my  @array=@_;
  my  $m3u="";
  my  $fn="_playlist.m3u";
  my  $fqfn="$dir/$fn";
  foreach (sort @array){
    $m3u.="$_\n";
#    print "$_\n";
  }
  my  $ret=&writeFile($fqfn,$m3u);
  if ($ret==0){
    print "Playlist written: >$fn< to >$dir<\n" if $debug>0;
    print "." if $debug==0;
    print "\010"x100;
    print "\015";
    print "Playlist written: >$fn< to >$dir<";
  }else{
    print "\nERROR: Kann Playlist: >$fn< in die >$dir< nicht schreiben!!  \n";
  }
}

sub writeFile {                       # Datei schreiben
# Parameter: $FileName = Name der anzulegenden Datei
#            $Inhalt   = Der Text/Inhalt, der in die Datei rein soll
#
# Return:   0 wenn ok  / 1 wenn Fehler
  my  $FileName = shift;
  my  ($Inhalt) = @_;
  my  $error = 0;

#  return $error=1 if (-z $FileName || !-f $FileName);
  open DATEI, "> $FileName" or $error=1;
  if ($error==0)    # nur wenn der open geklappt hat
  {
    print DATEI $Inhalt;
    close DATEI;
  }
  return $error;
}

