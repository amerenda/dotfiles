import cv2
import numpy as np
from PIL import Image
import sys
import matplotlib.pyplot as plt
import matplotlib
import numpy as np
from PIL import Image


matplotlib.use('TkAgg')
high_res = cv2.imread('assets/30000×17078.jpg')
med_res = cv2.imread('assets/2560x1457.jpg')
low_res = cv2.imread('assets/1280x729.jpg')

def slice_image(image_array, rows, cols):
    """
    Slices an image into a grid of (rows x cols) sub-images.
    
    :param image_array: Numpy array of the image.
    :param rows: Number of rows in the grid.
    :param cols: Number of columns in the grid.
    :return: 2D list of numpy array objects representing the slices.
    """
    # Convert numpy array to PIL Image
    image = Image.fromarray(image_array)
    
    img_width, img_height = image.size
    slice_width = img_width // cols
    slice_height = img_height // rows
    
    slices = []
    for i in range(rows):
        row_slices = []
        for j in range(cols):
            left = j * slice_width
            upper = i * slice_height
            right = (j + 1) * slice_width
            lower = (i + 1) * slice_height
            
            # Crop the image to extract the desired slice
            slice_ = image.crop((left, upper, right, lower))
            
            # Optionally, convert the PIL Image slice back to a numpy array
            slice_array = np.array(slice_)
            
            row_slices.append(slice_array)
        slices.append(row_slices)
    
    return slices


def display_slices(slices):
    rows = len(slices)
    cols = len(slices[0])
    
    fig, axes = plt.subplots(rows, cols)
    
    for i in range(rows):
        for j in range(cols):
            # Convert BGR to RGB before displaying
            rgb_slice = cv2.cvtColor(slices[i][j], cv2.COLOR_BGR2RGB)
            axes[i, j].imshow(rgb_slice)
            axes[i, j].axis("off")
    
    plt.show()


def get_content_coordinates_adaptive(image, block_size=501, c=-10):
    # Convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Adaptive Thresholding
    thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C,
                                   cv2.THRESH_BINARY_INV, block_size, c)
    
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    max_area = 0
    best_box = (0, 0, image.shape[1], image.shape[0]) # default to whole image if no contours found
    
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        area = w * h
        if area > max_area:
            max_area = area
            best_box = (x, y, x + w, y + h)
    
    return best_box

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

def remove_black_border(image, threshold=255):
    # Get content coordinates from the grayscale version
    x1, y1, x2, y2 = get_content_coordinates(image, threshold)
    
    # Crop the original, colored image
    cropped_image = image[y1:y2, x1:x2]
    
    return cropped_image, (x1, y1, x2, y2)

def draw_grid_adjusted(image, slices_coordinates):
    for coordinates in slices_coordinates:
        x1, y1, x2, y2 = coordinates
        
        # Draw horizontal and vertical lines using OpenCV
        cv2.line(image, (x1, y1), (x2, y1), (0, 255, 0), 1)  # Horizontal top line
        cv2.line(image, (x1, y2), (x2, y2), (0, 255, 0), 1)  # Horizontal bottom line
        cv2.line(image, (x1, y1), (x1, y2), (0, 255, 0), 1)  # Vertical left line
        cv2.line(image, (x2, y1), (x2, y2), (0, 255, 0), 1)  # Vertical right line
    
    cv2.imshow("Grid Overlay", image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


# Example usage:
image = low_res
rows = 4  # Number of rows
cols = 3  # Number of columns
slices = slice_image(image, rows, cols)

slices_coordinates = []

for i, row_slices in enumerate(slices):
    for j, slice_img in enumerate(row_slices):
        cropped_slice, coords = remove_black_border(slice_img)
        
        # Adjusting coordinates relative to the original image
        x_offset = j * (image.shape[1] // cols)
        y_offset = i * (image.shape[0] // rows)
        adjusted_coords = (
            coords[0] + x_offset, 
            coords[1] + y_offset, 
            coords[2] + x_offset, 
            coords[3] + y_offset
        )
        
        slices_coordinates.append(adjusted_coords)
        
        # Displaying the cropped slice
        #plt.imshow(cv2.cvtColor(cropped_slice, cv2.COLOR_BGR2RGB))
        #plt.show()

draw_grid_adjusted(image, slices_coordinates)