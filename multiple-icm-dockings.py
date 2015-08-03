#!/usr/bin/env python2
#
# Multiple ICM docking. This program allows the user to dock a single ligand
# molecule to a protein with the ICM-Pro molecular modelling software. Although
# the ICM-Pro software is distributed under a proprietary licence, the author
# of this program has distributed this script under the GNU GPLv2 license and
# hopes the developers of ICM-Pro will release their programs as free software
# as well.
#
# Copyright (C) 2015 Dennis Chen <barracks510@gmail.com>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#


def get_options():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "PROJECT",
        help="project name")
    parser.add_argument(
        "LIGAND",
        help="target ligand")
    parser.add_argument(
        "-p", "--pdb",
        help="build ICM project from PDB")
    parser.add_argument(
        "-n", "--number",
        type=int,
        default=1,
        help="run NUMBER docks on the project")
    parser.add_argument(
        "-j", "--spawn",
        type=int,
        default=1,
        help="create process with SPAWN threads")
    parser.add_argument(
        "-c", "--confs",
        type=int,
        default=50,
        help="generate CONFS number of conformations each dock")
    parser.add_argument(
        "-t", "--thorough",
        type=int,
        default=1,
        help="extend the length of each dock by this factor")
    parser.add_argument(
        "-o", "--output",
        help="use OUTPUT directory for resulting files")
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="display additional output")
    parser.add_argument(
        "-s", "--save",
        action="store_true",
        help="save a receipt of the script run information")
    return parser.parse_args()


def get_icmenv():
    import os
    if "ICMHOME" in os.environ:
        return os.environ["ICMHOME"]
    else:
        print "\'ICMHOME\' environment variable is not set. "
        from distutils.spawn import find_executable
        icm_bin = find_executable("icm") or find_executable("icm64")
        if icm_bin:
            os.environ["ICMHOME"] = os.path.dirname(icm_bin)
            print "ICM has been found in this directory: "
            print os.environ["ICMHOME"]
            return os.environ["ICMHOME"]
        else:
            print "Assuming default ICM location. "
            os.environ["ICMHOME"] = "/usr/share/icm"
            return os.environ["ICMHOME"]


import os
import sys
import subprocess
import datetime
import shutil

# Parse Command Line Options
args = get_options()

# Get the location of ICM through it's environment variable.
icm_location = get_icmenv()
# Use HOME as data location if OUTPUT flag is not specified.
location_top = args.output or os.environ["HOME"]
location_project = os.path.join(location_top, args.PROJECT, args.LIGAND)

print "This program will output all data to the following directory: "
print location_project

# Cache locations for binaries
icm_bin = os.path.join(icm_location, "icm64")
dockScan_bin = os.path.join(icm_location, "_dockScan")
icm_dockScan = [
    icm_bin,
    dockScan_bin,
    os.path.join(location_top, args.PROJECT, args.PROJECT),
    "input=" + os.path.join(location_project, args.LIGAND + ".mol"),
    "-s",
    "confs=" + str(args.confs),
    "thorough=" + str(args.thorough),
    "outdir=" + location_project,
    "jobs=" + str(args.spawn)]

# Start the timer for DOCKINGS
time_start = datetime.datetime.now()
print "Dockings Started on %s" % time_start

# Run the dockings
for i in range(args.number):
    if args.verbose:
        try:
            print subprocess.check_output(icm_dockScan)
        except subprocess.CalledProcessError:
            print "Something is wrong with your current configuration."
            sys.exit()
    else:
        if not subprocess.call(icm_dockScan):
            print "Something is wrong with your current configuration."
            sys.exit()
    print "Dock %s was completed on %s" % (i, datetime.datetime.now())
    ob_src = os.path.join(
        location_project,
        args.PROJECT + "_" + args.LIGAND + "1.ob")
    ob_dest = os.path.join(
        location_project,
        args.LIGAND + "_dock" + i + ".ob")
    shutil.move(ob_src, ob_dest)

# Write ICM Script to grab best 50 confs onto disk
print "Writing temporary script to disk...",
with open(os.path.join(location_top, "icm_script"), "w") as icm_script:
    icm_script.write("#!%s\n" % icm_bin)
    icm_script.write("for i=1, %i\n" % args.number)
    location_ligand = os.path.join(location_project, args.LIGAND)
    icm_script.write("s_obname= \"%s_dock\"+i+\".ob\";\n" % location_ligand)
    icm_script.write("s_sdfname= \"%s_dock\"+i+\".sdf\"\n" % location_ligand)
    icm_script.write("read object s_obname\n")
    icm_script.write("load stack a_\n")
    icm_script.write("write Energy(stack) s_sdfname\n")
    icm_script.write("endfor\n")
    icm_script.write("quit\n")
print "DONE"

# Have ICM run the ICM Script
print "Gathering 50 best confs from each docking...",
icm_icm_script = [
    icm_bin,
    "-s",
    os.path.join(location_top, "icm_script")]
if args.verbose:
    try:
        print subprocess.check_output(icm_icm_script)
    except subprocess.CalledProcessError:
        print "ERROR"
        sys.exit()
else:
    if not subprocess.call(icm_icm_script):
        print "ERROR"
        sys.exit()
    print "DONE"
