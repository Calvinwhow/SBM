#!/bin/bash
# This script processes brain imaging data within a a BIDS directory that was mounted to a Dockerfile.

ROOTDIR="/data" 
FWHM=6

# Tell freesurfer where the subjects are
export SUBJECTS_DIR=/data

# Place FSAverage5 with the subjects
if [ ! -d "$ROOTDIR/fsaverage5" ]; then
    cp -r /opt/freesurfer-6.0.1/subjects/fsaverage5 $ROOTDIR/fsaverage5
fi

for dir in $ROOTDIR/*; do
    if [ -d "$dir" ]; then
        sub=$(basename "$dir")  # Assign subject identifier from the first field of the line
        # Skip the fsaverage5 directory
        if [ "$sub" == "fsaverage5" ]; then
            continue
        fi
        echo "Processing subject: $sub"

        # Loop over hemispheres (left and right)
        for hemi in lh rh; do
            #Assess for file
            if ! test -f "$ROOTDIR/$sub/surf/$hemi.thickness"; then
                echo "DOES NOT EXIST: $ROOTDIR/$sub/surf/$hemi.thickness"
            fi

            #Assess if has already been run
            if test -f "$ROOTDIR/$sub/surf/$hemi.${sub}.thickness.s${FWHM}.fs5.mgh"; then
                echo "$ROOTDIR/$sub/surf/$hemi.${sub}.thickness.s${FWHM}.fs5.mgh"
                continue
            else
                # Process thickness data for the subject and hemisphere using mri_surf2surf. Can take a --fwhm parameter defining FWHM as int in mm. 
                mri_surf2surf \
                --srcsubject $sub \
                --srcsurfval $ROOTDIR/$sub/surf/$hemi.thickness \
                --trgsubject fsaverage5 \
                --trgsurfval $ROOTDIR/$sub/surf/$hemi.${sub}.thickness.s${FWHM}.fs5.mgh \
                --hemi $hemi \
                --fwhm $FWHM
            fi
        done
    fi
done