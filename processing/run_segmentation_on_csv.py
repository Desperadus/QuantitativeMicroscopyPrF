import pandas as pd
import os
from cellpose import models, io
import numpy as np
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Configuration ---
csv_file_path = "../data/BBBC021_v1_image_smaller.csv"
relative_path_to_data = "../data/"
output_dir = "outputs"


def process_image(model, image_path, output_base_name):
    """
    Loads an image, runs Cellpose, and saves the segmentation results.
    
    Args:
        model: Initialized Cellpose model.
        image_path (str): Full path to the input image file.
        output_base_name (str): Base path and name for the output _seg.npy file 
                                (without the .npy extension).
    """
    if not os.path.exists(image_path):
        logger.warning(f"Image file not found, skipping: {image_path}")
        return

    logger.info(f"Processing image: {image_path}")
    try:
        # 1. Load image
        img = io.imread(image_path)
        
        # Check if image loading was successful and if the image has content
        if img is None:
            logger.error(f"Failed to load image or image is empty: {image_path}")
            return
        if img.size == 0:
             logger.error(f"Image loaded but is empty (size 0): {image_path}")
             return
             
        # Ensure image is 2D if it's grayscale
        if img.ndim > 2:
           # Assuming the first channel is the one of interest if it's multi-channel grayscale
           logger.warning(f"Image {os.path.basename(image_path)} has {img.ndim} dimensions. Using first channel.")
           img = img[0] 
        # Or handle specific multi-channel logic if needed, e.g.:
        # img = img[channel_index] 

        masks, flows, styles = model.eval(
            img,
            diameter=None,  # Set to None to let the model estimate the diameter
        )
        
        # Note: diams from model.eval is often a single estimated diameter 
        # if diameter=None was used. io.masks_flows_to_seg expects a list of diameters,
        # one per image.

        # 3. Save results to _seg.npy file
        # io.masks_flows_to_seg expects lists for images, masks, flows, diams.
        io.masks_flows_to_seg(
            images=[img],         # List containing the single image
            masks=[masks],        # List containing the masks array
            flows=[flows],        # List containing the flows array
            file_names=[output_base_name], # List containing the output base name
        )
        logger.info(f"Saved segmentation to: {output_base_name}_seg.npy")

    except Exception as e:
        logger.error(f"Error processing image {image_path}: {e}", exc_info=True)

def main():
    """
    Main function to read CSV, initialize Cellpose, and process images.
    """
    if not os.path.exists(csv_file_path):
        logger.error(f"CSV file not found: {csv_file_path}")
        return

    try:
        df = pd.read_csv(csv_file_path)
        logger.info(f"Successfully loaded CSV file: {csv_file_path}")
    except Exception as e:
        logger.error(f"Error reading CSV file {csv_file_path}: {e}")
        return


    model = models.CellposeModel(gpu=True)


    # --- Image Processing Loop ---
    logger.info("Starting image processing...")
    for index, row in df.iterrows():
        logger.info(f"Processing row {index+1}/{len(df)}")
        
        # Process DAPI image
        dapi_filename = row.get('Image_FileName_DAPI')
        dapi_pathname = row.get('Image_PathName_DAPI')
        if pd.notna(dapi_filename) and pd.notna(dapi_pathname):
            dapi_full_path = os.path.join(relative_path_to_data,os.path.join(dapi_pathname, dapi_filename))
            dapi_base = os.path.splitext(dapi_filename)[0]
            # Determine output path
            if output_dir:
                os.makedirs(output_dir, exist_ok=True) # Ensure output dir exists
                dapi_output_base = os.path.join(output_dir, dapi_base)
            else: # Save next to original image
                dapi_output_base = os.path.join(dapi_pathname, dapi_base)
            
            process_image(model, dapi_full_path, dapi_output_base)
        else:
            logger.warning(f"Row {index+1}: Missing DAPI filename or path.")

        # Process Actin image
        actin_filename = row.get('Image_FileName_Actin')
        actin_pathname = row.get('Image_PathName_Actin')
        if pd.notna(actin_filename) and pd.notna(actin_pathname):
            actin_full_path =  os.path.join(relative_path_to_data, os.path.join(actin_pathname, actin_filename))
            actin_base = os.path.splitext(actin_filename)[0]
             # Determine output path
            if output_dir:
                 # Output directory already created or checked above
                actin_output_base = os.path.join(output_dir, actin_base)
            else: # Save next to original image
                actin_output_base = os.path.join(actin_pathname, actin_base)
                
            process_image(model, actin_full_path, actin_output_base)
        else:
            logger.warning(f"Row {index+1}: Missing Actin filename or path.")

    logger.info("Finished processing all images.")

if __name__ == "__main__":
    main()