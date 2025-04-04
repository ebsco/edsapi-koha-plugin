#!/usr/bin/env python3

## USAGE:
    # Update parameter within version.json
    # Run build.py
    # Commit code

import json
import datetime
import os
now = datetime.datetime.now()

##### Get json settings #####
with open('version.json') as f:
    data = json.load(f)

majorVersion = data["MajorVersion"]
minorVersion = data["MinorVersion"]
releaseNotes = data["ReleaseNotes"]
shaAdd = data["ShaAdd"]

##############################

##### Update EDS.pm #####
with open('Koha/Plugin/EDS.pm', 'r') as file :
    filedata = file.readlines()

# find and replace version
for line in range(len(filedata)):
    templine = filedata[line].rstrip()

    # Set major version
    if ("our $MAJOR_VERSION" in templine):
        filedata[line] = 'our $MAJOR_VERSION = "' + majorVersion + '";\n'

    # Set sub version
    if ("our $SUB_VERSION" in templine):
        filedata[line] = 'our $SUB_VERSION = "' + minorVersion + '";\n'

    # Set sha address
    if ("our $SHA_ADD" in templine):
        filedata[line] = 'our $SHA_ADD = "' + shaAdd + '";\n'

    # Set date
    if ("our $DATE_UPDATE" in templine):
        filedata[line] = 'our $DATE_UPDATE = \'' + str(now.year) + "-" + str('%02d' % now.month) + "-" + str('%02d' % now.day) + '\';\n'

# write updated array to file
wfile = open('Koha/Plugin/EDS.pm', 'w')
for item in filedata:
    wfile.write(item)

#########################



##### Update EDSScript.js #####
with open('Koha/Plugin/EDS/js/EDSScript.tt', 'r') as file :
    filedata = file.readlines()



# find and replace version
for line in range(len(filedata)):
    templine = filedata[line].rstrip()

    # Set version
    if ("var versionEDSKoha =" in templine):
        filedata[line] = 'var versionEDSKoha = "' + majorVersion + minorVersion + '";\n'

# write updated array to file
wfile = open('Koha/Plugin/EDS/js/EDSScript.tt', 'w')
for item in filedata:
    wfile.write(item)



#########################


##### update release_notes.xml #####

with open('Koha/Plugin/EDS/admin/release_notes.xml', 'r') as file :
    filedata = file.readlines()

noted = False

# find and replace version
for line in range(len(filedata)):
    templine = filedata[line].rstrip()

    # Set version
    if ("<release version" in templine):
        filedata[line] = '\t\t<release version="' + majorVersion + "." + minorVersion + '" date="' + str(now.year) + "/" + str('%02d' % now.month) + "/" + str('%02d' % now.day) + '">\n'

    # Set version
    if ("<latestversion>" in templine):
        filedata[line] = '\t<latestversion>' + majorVersion + "." + minorVersion + '</latestversion>\n'

    # Set date
    if ("<lastupdated>" in templine):
        filedata[line] = '\t<lastupdated>' + str(now.year) + "/" + str('%02d' % now.month) + "/" + str('%02d' % now.day) + '</lastupdated>\n'

    # add notes
    if ("<note id" in templine):
        if (noted):
            filedata[line] = ''
        else:
            noted = True
            i = 0
            superString = ""
            for node in releaseNotes:
                i+=1
                superString+= '\t\t\t<note id="' + str(i) + '" author="' + node["author"] + '">' + node["note"] + '</note>\n'
            filedata[line] = superString

# write updated array to file
wfile = open('Koha/Plugin/EDS/admin/release_notes.xml', 'w')
for item in filedata:
    wfile.write(item)

#########################

## Update kpz
os.system("rm *.kpz")
os.system("zip -r eds_plugin_" + majorVersion + minorVersion +  ".kpz Koha")