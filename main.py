import cv2
import numpy as np
from PIL import Image
import sys
import matplotlib.pyplot as plt
import matplotlib
import numpy as np
from PIL import Image


matplotlib.use('TkAgg')

# Load image using OpenCV
def saliencyRender():
    high_res = cv2.imread('assets/30000×17078.jpg')
    med_res = cv2.imread('assets/2560x1457.jpg')
    low_res = cv2.imread('assets/1280x729.jpg')
    output_size = (1920, 1080)
    image = low_res

    # Convert image to RGB (OpenCV uses BGR)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Initialize Static Saliency Spectral Residual detector
    saliency = cv2.saliency.StaticSaliencySpectralResidual_create()
    (success, saliencyMap) = saliency.computeSaliency(image)

    threshMap = cv2.threshold(saliencyMap.astype("uint8"), 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]

    saliencyMap = (saliencyMap * 255).astype("uint8")
    threshMap = (threshMap * 10).astype("uint8")

    # Sailency map output

    # Convert saliencyMap to uint8 (if not already)
    saliencyMap_uint8 = (saliencyMap * 255).astype(np.uint8)

    # 1. Binarize the saliency map
    _, binarizedMap = cv2.threshold(saliencyMap_uint8, 127, 255, cv2.THRESH_BINARY)

    # Apply morphological operations (Optional: to remove noise or small regions)
    kernel = np.ones((5,5),np.uint8) 
    #binarizedMap = cv2.morphologyEx(binarizedMap, cv2.MORPH_OPEN, kernel)



    # 2. Find contours
    (contours, _) = cv2.findContours(binarizedMap, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    print(len(contours))
    # Draw contours on a copy of the original image or saliency map
    image_copy = image.copy()
    cv2.drawContours(image_copy, contours, -1, (0, 255, 0), 2)

    plt.imshow(image_copy)
    plt.savefig("output.png")
    plt.show()

    sys.exit()
    for contour in contours:
        # 3. Extract bounding boxes
        x, y, w, h = cv2.boundingRect(contour)

        # Optionally: Filter bounding boxes by size
        if w > 50 and h > 50: # Adjust size criteria as needed
            # 4. Crop original image
            cropped_region = image[y:y+h, x:x+w]
            #plt.imshow(cropped_region)
            #plt.show()

            # Resize while maintaining aspect ratio
            aspect_ratio = w/h
            target_w, target_h = output_size
            if aspect_ratio > target_w/target_h:
                new_w = target_w
                new_h = int(new_w / aspect_ratio)
            else:
                new_h = target_h
                new_w = int(new_h * aspect_ratio)

            resized_region = cv2.resize(cropped_region, (new_w, new_h))

            # Create an empty image of the desired size
            output_image = np.zeros((target_h, target_w, 3), dtype=np.uint8)

            # Paste the resized crop into the center of the image
            x_offset = (target_w - new_w) // 2
            y_offset = (target_h - new_h) // 2
            output_image[y_offset:y_offset+new_h, x_offset:x_offset+new_w] = resized_region

            # Convert to PIL Image and save or display
            #output_image_pil = Image.fromarray(output_image)
            #output_image_pil.show()


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

def remove_black_border(image, threshold=10):
    # Get content coordinates from the grayscale version
    x1, y1, x2, y2 = get_content_coordinates(image, threshold)
    
    # Crop the original, colored image
    cropped_image = image[y1:y2, x1:x2]
    
    return cropped_image

high_res = cv2.imread('assets/30000×17078.jpg')
med_res = cv2.imread('assets/2560x1457.jpg')
low_res = cv2.imread('assets/1280x729.jpg')
image_path = med_res
rows = 3  # number of rows in the grid
cols = 4  # number of columns in the grid

# Example usage:
slices = slice_image(image_path, rows, cols)

# Assuming `slices` is a 2D list of your image slices
for i, row_slices in enumerate(slices):
    for j, slice_img in enumerate(row_slices):
        cropped_slice = remove_black_border(slice_img)
        # Now, `cropped_slice` retains the original color
        plt.imshow(cv2.cvtColor(cropped_slice, cv2.COLOR_BGR2RGB))
        plt.show()

