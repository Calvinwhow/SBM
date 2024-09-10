#!/bin/bash
# This script processes brain imaging data using FreeSurfer's recon-all within a BIDS directory mounted to a Dockerfile.
# To use this script, make sure the BIDS directory is mounted to :/data, and then simply run the script. 
# example) docker run -v "my_scripts_here:/scripts" -v "my/bids/dir:/data" calvinwhow/freesurfer:latest /scripts/run_reconall.sh

# Root directory for BIDS dataset
ROOTDIR="/data"
# Full Width Half Maximum (FWHM) for surface smoothing
FWHM=6

# Tell FreeSurfer where the subjects are
export SUBJECTS_DIR=$ROOTDIR

# Ensure fsaverage5 is available
if [ ! -d "$ROOTDIR/fsaverage5" ]; then
    echo "Copying fsaverage5 to the subjects directory..."
    cp -r /opt/freesurfer/subjects/fsaverage5 $ROOTDIR/fsaverage5
fi

# Loop through all directories in the root directory (assuming they are subjects)
for dir in $ROOTDIR/*; do
    if [ -d "$dir" ]; then
        sub=$(basename "$dir")  # Get the subject identifier
        # Skip the fsaverage5 directory
        if [ "$sub" == "fsaverage5" ]; then
            continue
        fi
        echo "Processing subject: $sub"

        # Run recon-all for anatomical processing if necessary
        if [ ! -f "$ROOTDIR/$sub/scripts/recon-all.done" ]; then
            echo "Running recon-all for subject $sub..."
            recon-all -i $ROOTDIR/$sub/anat/${sub}_T1w.nii.gz -s $sub -all
            if [ $? -eq 0 ]; then
                echo "Recon-all completed for $sub"
                touch "$ROOTDIR/$sub/scripts/recon-all.done"
            else
                echo "Recon-all failed for $sub"
                continue
            fi
        else
            echo "Recon-all already completed for subject $sub"
        fi

        # Process surface data with mri_surf2surf
        for hemi in lh rh; do
            if [ -f "$ROOTDIR/$sub/surf/$hemi.thickness" ]; then
                echo "Processing thickness data for $sub hemisphere $hemi..."
                mri_surf2surf \
                    --srcsubject $sub \
                    --srcsurfval $ROOTDIR/$sub/surf/$hemi.thickness \
                    --trgsubject fsaverage5 \
                    --trgsurfval $ROOTDIR/$sub/surf/$hemi.${sub}_thickness.s${FWHM}.fs5.mgh \
                    --hemi $hemi \
                    --fwhm $FWHM
            else
                echo "No thickness file found for $sub hemisphere $hemi."
            fi
        done
    fi
done
