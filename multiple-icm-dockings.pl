#!/usr/bin/perl
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

$projectName=$ARGV[0];
$ligandName=$ARGV[1];
$numberRuns=$ARGV[2];
$thoroughCount=$ARGV[3];
$threads=$ARGV[4];

$start=localtime();

if($threads=='') {
    $threads=1;
}

$icmLocation=$ENV{'ICMHOME'}.'/';
$dataLocation=$icmLocation.$projectName.'/'.$ligandName.'/';

print("Please make sure you have placed all your project files in the correct",
    "directory. \n This program will search the following directory for ",
    "project files: \n".$dataLocation."\n");
sleep 3;
print ("Continuing");
sleep 1;
print(".");
sleep 1;
print(".");
sleep 1;
print(".\n\n\n");

chdir $dataLocation;
#system("mkdir ./data.old && mv *.ob data.old/");

for($i=1; $i<=$numberRuns; $i++) {
    system("$icmLocation"."icm64 $icmLocation/_dockScan $projectName "
        ."input=$ligandName.mol -s confs=50 throrough=$thoroughCount "
        ."outdir=$dataLocation jobs=$threads");
    system("mv $projectName"."_$ligandName"."1.ob $ligandName"."_dock$i.ob");
    $dockingTimestamp=localtime();
    print("Docking $i complete on $dockingTimestamp\n");
}

open(ICM,'>',"$dataLocation"."run_script") || die("Project not found. 59. $!");
print ICM "#!$icmLocation"."icm64 -s\n";
print ICM "for i=1, $numberRuns\n";
print ICM "s_obname= \"$dataLocation$ligandName"."_dock\"+i+\".ob\";\n";
print ICM "s_sdfname= \"$data_home$ligandName"."_dock\"+i+\".sdf\";\n";
print ICM "read object s_obname"."\n";
print ICM "load stack a_"."\n";
print ICM "write Energy(stack) s_sdfname"."\n";
print ICM "endfor\n";
print ICM "quit\n";
close(ICM) || die $!;

system("$icmLocation"."/icm64 -s run_script");

open(W,'>',"temp.log") || die("Cannot write log file. Check permissions. $!");
for($i=1; $i<=$numberRuns; $i++) {
    open(Read,'<',$ligandName."_dock$i.sdf") || die("Cannot read sdf. $!");
    while($line=<Read>){
        chomp($line);
        foreach($line){
            s/^\s+//;
            s/\s+$//;
            s/\s+/ /g;
        }
        my @temp=split(' ',$line);
        $icmScore=$temp[0];
        close(Read) || die $!;
    }
    print W $ligand."_dock$i\t$icmScore\n";
}
close(W) || die $!;

system("sort -n -k2 temp.log > $projectName"."_".$ligandName.".log");
system("rm temp.log");

$end=localtime();
print("Start Process at $start\n");
print("End Process at $end \n\n\n");

$finishTimestamp=localtime();
print("Completed on $finishTimestamp\n");
