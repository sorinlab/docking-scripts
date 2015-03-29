#! /usr/bin/perl
#
#Multiple ICM docking. This program allows the user to dock a single ligand
#molecule to a protein with the ICM-Pro molecular modelling software. Although
#the ICM-Pro software is distributed under a proprietary licence, the author
#of this program has distributed this script under the GNU GPLv2 license and
#hopes the developers of ICM-Pro will release their programs as free software
#as well.
#
#Copyright (C) 2015 Dennis Chen <barracks510>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

$projectname = $ARGV[0];
$max_run = $ARGV[1];
$thorough = $ARGV[2];
$script_home = $ENV{'PWD'};
$results =$ENV{'PWD'}.'/'.$projectname.'/';

%ligand = (1 => "DAPPpM", 2 => "MMPP", 3 => "Trial_DMPPmp", 4 => "TMPP" );

$NoLigand = scalar(keys %ligand);

for($j=1;$j<=$NoLigand;$j++)
{
   chdir $script_home;
   $command= "perl multiple-icm-dockings.pl $projectname $ligand{$j} $max_run $thorough";
   system($command);
}

open(W,'>',$results."Total_Results.log") || die "Please give me output filename $!";

for($f=1;$f<=$NoLigand;$f++)
{  

   open(Readlog,'<', "$results$ligand{$f}".'/'.$projectname.'_'.$ligand{$f}.'.log') || die $!;
   while($line=<Readlog>)
   {
      chomp($line);
      foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
      my @temp=split(' ',$line);
      $ICMscore = $temp[1];
      close(Readlog)||die $!;
   }
   printf W "%-15s\t%15s\n",$ligand{$f},$ICMscore;
   
}
close(W)||die $!;


