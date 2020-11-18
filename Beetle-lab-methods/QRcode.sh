#!/bin/bash

################################################################################
#    Copyright (C) 2020  Matthew E. Wolak

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

################################################################################

# Need Linux command line programs: `qrencode` and `ImageMagick`
## If qrencode not installed run `sudo apt install qrencode` on linux
## If Image Magick not installed run `sudo apt install imagemagick`
## on Mac can substitute `brew` for `sudo apt`

DATE="_"`date +"%Y%m%d_%H%M%S"`


# First get some information about what IDs to generate
read -p $'\nEnter number of IDs to generate: ' N

if [[ $N = "" ]]; then
    echo '  No value entered, assuming one ID (N=1)'
    N=1
  else
    echo "  Making '$N' IDs"
  fi
  

read -p $'\nWhat color? Must be exactly `black` (press <ENTER> for default), `red`, `green`, or `blue`: ' CLR

  if [[ $CLR = "" ]]; then
      CLR="black"
    fi
  COLOR=$CLR'_'
  
  
# Turned OFF prefix selection: Give every ID prefix of `qrID`  
#read -p $'\nType in a prefix for each ID or press <ENTER> for qrID: ' PRE

#if [[ $PRE = "" ]]; then
#    echo '  You pressed enter, prepending IDs with QRid_'
    PREFIX="qrID_"
#  else
#    echo "  Prepending IDs with '$PRE _'"  
#    PREFIX=$PRE'_'
#  fi
  
  
  

read -p $'\nType in a suffix for each ID or press <ENTER> for none: ' SUF

if [[ $SUF = "" ]]; then
    echo '  You pressed enter, no suffix to add to IDs'
    SUFFIX=""
  else
    echo "  Appending IDs with '_$SUF'"  
    SUFFIX='_'$SUF
  fi




# Make temporary directory to hold images before stitching them together in pdf
mkdir ./tmpQR



# Iterate through IDs to create a QR code PNG and store in temporary directory
for ((i=1; i<=N; i++))
  do
# QRcode tutorial:
## https://www.linux-magazine.com/Online/Features/Generating-QR-Codes-in-Linux

# Alternatives/Options:
## -l Error correction level (H > Q > M > L) (default L)
## -s specifies size of dot (pixel) (for PNG format only?) (default 3)
## -m increases white on edge by size of/relative to QR dots (default 4)
## -d/--dpi defines dpi/quality (Default is 72)
## -t EPS for EPS file format (change filename too)

#TODO ccould use --foreground=RRGGBB[AA] notation for color instead of imageMagick
##XXX However `convert` allows color to be specified as, for example, "purple" and
### matched by plain words and not RGB color format specification
    qrencode -l H -s 2 -m 5 --dpi 300 -o ./tmpQR/$PREFIX$COLOR$i$SUFFIX$DATE.png $PREFIX$COLOR$i$SUFFIX$DATE

#    if [[ $CLR = "red" ]] || [[ $CLR = "blue" ]] || [[ $CLR = "green" ]]; then
    if [[ $CLR != "black" ]]; then
         convert ./tmpQR/$PREFIX$COLOR$i$SUFFIX$DATE.png -fill $CLR -opaque black ./tmpQR/$PREFIX$COLOR$i$SUFFIX$DATE.png
    fi
    
      
done


# ImageMagick
## could do ./tmpQR/$PREFIX[1-18]$SUFFIX.png 
### where [x-x] is UNIX shorthand, not image Magick
## Assume 8.5 x 11 page is 2550x3300 pixels
### -tile takes a COLUMN by ROW value 
montage ./tmpQR/$PREFIX$COLOR*$SUFFIX$DATE.png -tile 9x12 -geometry 62x $PREFIX$COLOR$SUF$DATE"p"%d.pdf

# Cleanup temporary directory
rm -r ./tmpQR

