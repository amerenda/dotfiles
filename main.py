import cv2
import numpy as np
from PIL import Image
import sys
import matplotlib.pyplot as plt
import matplotlib
import numpy as np
import os


matplotlib.use('TkAgg')
high_res = cv2.imread('assets/30000×17078.jpg')
med_res = cv2.imread('assets/2560x1457.jpg')
low_res = cv2.imread('assets/1280x729.jpg')

test_res = (256, 256)
pc_res = (1920, 1080)
phone_res = (3120, 1440)

black_border_threshold = 2
resolution = test_res
res_string = "{}x{}".format(resolution[0], resolution[1])


def remove_horizontal_lines(image, line_color, line_thickness=20, threshold=2):
    """
    Removes horizontal lines from an image.
    
    Parameters:
        image (numpy.ndarray): The input image.
        line_color (tuple): BGR values of the line to be removed.
        line_thickness (int): Expected thickness of the line to be removed.
        threshold (int): Threshold value for color comparison.
    
    Returns:
        numpy.ndarray: The processed image.
    """

    # Convert to grayscale for easier processing
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Threshold the image to keep only the lines
    _, thresh = cv2.threshold(gray, threshold, 255, cv2.THRESH_BINARY_INV)
    
    # Define a horizontal kernel
    horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (line_thickness, 1))
    
    # Apply morphological opening to remove horizontal lines
    detected_lines = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, horizontal_kernel, iterations=2)
    
    # Find contours of the lines
    contours, _ = cv2.findContours(detected_lines, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Loop over the contours
    for contour in contours:
        # Get bounding box of the line
        x, y, w, h = cv2.boundingRect(contour)
        
        # Check whether the found contour is of a horizontal line
        if w > 1.5*h:
            # Replace line area with the background color
            cv2.rectangle(image, (x, y), (x+w, y+h), line_color, -1)
            
    return image


def get_content_coordinates(image, threshold=255):
    # Convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Threshold the image
    _, thresh = cv2.threshold(gray, threshold, 255, cv2.THRESH_BINARY)
    
    # Find contours in the threshold image
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Get the bounding box of the largest contour
    max_area = 0
    best_box = (0, 0, image.shape[1], image.shape[0]) # default to whole image if no contours found
    
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        area = w * h
        if area > max_area:
            max_area = area
            best_box = (x, y, x + w, y + h)
    
    return best_box

def draw_grid_adjusted(image, slices_coordinates):
    colors = [(0, 255, 0), (255, 0, 0), (0, 0, 255), (255, 255, 0)]
    color_idx = 0
    
    for coordinates in slices_coordinates:
        x1, y1, x2, y2 = coordinates
        
        # Get color
        color = colors[color_idx]
        color_idx = (color_idx + 1) % len(colors)  # Move to the next color
        
        # Draw horizontal and vertical lines using OpenCV
        cv2.line(image, (x1, y1), (x2, y1), color, 1)  # Horizontal top line
        cv2.line(image, (x1, y2), (x2, y2), color, 1)  # Horizontal bottom line
        cv2.line(image, (x1, y1), (x1, y2), color, 1)  # Vertical left line
        cv2.line(image, (x2, y1), (x2, y2), color, 1)  # Vertical right line
    
    cv2.imshow("Grid Overlay", image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


def slice_image_fixed_size(image, resolution):
    """
    Slices an image into pieces of specified resolution with possible overlap.
    
    :param image: Numpy array of the image.
    :param resolution: Tuple (width, height) specifying the desired resolution of slices.
    :return: List of slices with specified resolution.
    """
    img_height, img_width, _ = image.shape
    slice_width, slice_height = resolution
    
    slices = []
    y = 0
    while y < img_height:
        x = 0
        while x < img_width:
            # Ensure the slicing does not exceed image boundaries
            y_end = min(y + slice_height, img_height)
            x_end = min(x + slice_width, img_width)
            
            # Check if the slice does not meet the desired resolution and adjust
            if y_end - y < slice_height:
                y_start = img_height - slice_height  # Start slice at the boundary to maintain resolution
            else:
                y_start = y
                
            if x_end - x < slice_width:
                x_start = img_width - slice_width  # Start slice at the boundary to maintain resolution
            else:
                x_start = x
                
            # Crop the image to extract the desired slice
            slice_ = image[y_start:y_end, x_start:x_end]
            slices.append(slice_)
            
            x += slice_width  # Adjust the step size horizontally
        y += slice_height  # Adjust the step size vertically
    
    return slices


def draw_slices_on_image(image, resolution, border_threshold):
    slices_coordinates = []
    img_height, img_width, _ = image.shape
    slice_width, slice_height = resolution
    
    x_step = slice_width // 2  # Half the slice width
    y_step = slice_height // 2  # Half the slice height
    
    y = 0
    while y < img_height - slice_height + 1:  # Ensuring the window stays within image bounds
        x = 0
        while x < img_width - slice_width + 1:  # Ensuring the window stays within image bounds
            # Extract the current slice
            slice_coordinates = (x, y, x + slice_width, y + slice_height)
            sliced_img = image[y:y + slice_height, x:x + slice_width]
            
            # Get the content coordinates of the slice
            content_coordinates = get_content_coordinates(sliced_img, border_threshold)
            
            # Adjust the content coordinates relative to the original image
            content_coordinates_adjusted = (
                content_coordinates[0] + x,
                content_coordinates[1] + y,
                content_coordinates[2] + x,
                content_coordinates[3] + y
            )
            
            slices_coordinates.append(content_coordinates_adjusted)
            x += x_step  # Move to the next slice horizontally
        y += y_step  # Move to the next slice vertically
    
    draw_grid_adjusted(image, slices_coordinates)

def slices_sequentially(slices, action, border_threshold=2, remove_lines=False, line_color=(0, 0, 0), line_thickness=5, resolution=(256, 256)):
    """
    Displays slices of an image sequentially.
    
    Parameters:
        slices (list): List of image slices.
        ...
        resolution (tuple): Desired resolution of slices.
    """
    for i, slice_ in enumerate(slices):
        content_coordinates = get_content_coordinates(slice_, threshold=border_threshold)
        cropped_slice = slice_[content_coordinates[1]:content_coordinates[3], 
                               content_coordinates[0]:content_coordinates[2]]
        
        # Ensure the slice is resized to the desired resolution
        resized_slice = cv2.resize(cropped_slice, resolution)
        
        if remove_lines:
            resized_slice = remove_horizontal_lines(
                resized_slice, line_color, line_thickness=line_thickness
            )
        
        if action.lower() == "show":        
            cv2.imshow(f"Slice {i+1}", resized_slice)
            cv2.waitKey(0)
            cv2.destroyAllWindows()
        elif action.lower() == "save":
            if not os.path.exists("output"):
                os.makedirs("output")
            cv2.imwrite(f"output/{res_string}_{i+1}.png", resized_slice)


def draw_updated_slices_on_image(image, slices, resolution, action, content_stddev_threshold=2):
    """
    Overlays an image with updated slices, drawing a grid around each slice.

    :param image: Original image.
    :param slices: Slices that may have undergone some processing.
    :param resolution: Tuple (width, height) specifying the desired resolution of slices.
    :param action: "show" or "save"
    :param content_stddev_threshold: standard deviation threshold to check if the slice has content.
    :return: Image with overlay of updated slices.
    """
    overlay = image.copy()
    
    img_height, img_width, _ = image.shape
    slice_width, slice_height = resolution
    
    y = 0
    while y < img_height:
        x = 0
        while x < img_width:
            if slices:  # Just to be safe and not get an index out of range
                slice_ = slices.pop(0)  # Pop the first slice
                
                # Check whether the slice contains meaningful content
                if np.std(slice_) > content_stddev_threshold:
                    # Determine the height and width of the slice to overlay
                    overlay_height = min(slice_height, img_height - y)
                    overlay_width = min(slice_width, img_width - x)
                    
                    # Overlay the updated slice onto the original image
                    overlay[y:y+overlay_height, x:x+overlay_width] = slice_[:overlay_height, :overlay_width]
                
                    # Draw rectangle around the slice
                    cv2.rectangle(overlay, (x, y), (x + overlay_width, y + overlay_height), (0, 255, 0), 2)
                
            x += slice_width
        y += slice_height
    
    if action.lower() == "show":        
        cv2.imshow("Updated Overlay", overlay)
        cv2.waitKey(0)  # Wait indefinitely until a key is pressed
        cv2.destroyAllWindows()
    elif action.lower() == "save":        
        cv2.imwrite(f"output/overlay.jpg", overlay)


def slice(image, action):
    slices = slice_image_fixed_size(image, resolution)

    # To display slices with horizontal lines removed, set remove_lines to True
    slices_sequentially(slices, action, border_threshold=black_border_threshold, remove_lines=True, line_color=(0, 0, 0), line_thickness=5, action=action)


def show_slices_on_image(image, action):
    slices = slice_image_fixed_size(image, resolution)

    # Perform any processing you want on the slices here
    processed_slices = []
    for slice_ in slices:
        content_coordinates = get_content_coordinates(slice_, threshold=black_border_threshold)
        cropped_slice = slice_[content_coordinates[1]:content_coordinates[3], 
                               content_coordinates[0]:content_coordinates[2]]
        
        # Resize the cropped slice back to the original resolution
        resized_slice = cv2.resize(cropped_slice, (resolution[0], resolution[1]))

        # Add any additional processing steps for each slice if needed
        processed_slices.append(resized_slice)

    # Overlay the original image with the processed slices
    draw_updated_slices_on_image(image, processed_slices, resolution, action)

def slice_and_process(image, action, resolution):
    # Slice image into defined resolution with overlaps
    slices = slice_image_fixed_size(image, resolution)
    
    # Optionally display each slice with removed horizontal lines
    slices_sequentially(slices, action, 
                        border_threshold=black_border_threshold,
                        remove_lines=True, line_color=(0, 0, 0), 
                        line_thickness=5)
    
    # Further processing on slices, if desired, should be added here
    
    # Example: Overlays the original image with the processed slices
    draw_updated_slices_on_image(image, slices, resolution, action)

# Invoke the function to slice and process

slice_and_process(low_res, action="save", resolution=test_res)