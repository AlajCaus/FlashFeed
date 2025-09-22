#!/usr/bin/env python3
"""
Download product images for FlashFeed app
Downloads appropriate images from Pexels (free stock photos)
"""

import os
import time
import requests
from urllib.parse import quote

# Directory to save images
IMAGE_DIR = "assets/images/products"

# Create directory if it doesn't exist
if not os.path.exists(IMAGE_DIR):
    os.makedirs(IMAGE_DIR)

# Product list from MockDataService
products = [
    # Obst & Gemüse
    {'name': 'Äpfel 1kg', 'search': 'red apples fresh', 'filename': 'apfel.jpg'},
    {'name': 'Bananen 1kg', 'search': 'yellow bananas bunch', 'filename': 'bananen.jpg'},
    {'name': 'Bio-Äpfel Braeburn 1kg', 'search': 'organic apples', 'filename': 'bio_apfel.jpg'},
    {'name': 'Bio-Bananen 1kg', 'search': 'organic bananas', 'filename': 'bio_bananen.jpg'},
    {'name': 'Tomaten 500g', 'search': 'fresh tomatoes red', 'filename': 'tomaten.jpg'},
    {'name': 'Gurken 1 Stück', 'search': 'cucumber fresh green', 'filename': 'gurken.jpg'},
    {'name': 'Kartoffeln 2.5kg', 'search': 'potatoes fresh raw', 'filename': 'kartoffeln.jpg'},

    # Milchprodukte
    {'name': 'Vollmilch 1L', 'search': 'milk bottle glass', 'filename': 'vollmilch.jpg'},
    {'name': 'Bio-Vollmilch 1L', 'search': 'organic milk bottle', 'filename': 'bio_vollmilch.jpg'},
    {'name': 'Joghurt Natur 500g', 'search': 'yogurt plain white', 'filename': 'joghurt.jpg'},
    {'name': 'Butter 250g', 'search': 'butter block dairy', 'filename': 'butter.jpg'},
    {'name': 'Käse Gouda 200g', 'search': 'gouda cheese yellow', 'filename': 'gouda.jpg'},
    {'name': 'Quark 500g', 'search': 'cottage cheese white', 'filename': 'quark.jpg'},

    # Fleisch & Wurst
    {'name': 'Hähnchenbrust 1kg', 'search': 'chicken breast raw meat', 'filename': 'haehnchen.jpg'},
    {'name': 'Rinderhack 500g', 'search': 'ground beef mince', 'filename': 'rinderhack.jpg'},
    {'name': 'Bratwurst 4 Stück', 'search': 'bratwurst sausages', 'filename': 'bratwurst.jpg'},
    {'name': 'Schnitzel 400g', 'search': 'schnitzel pork cutlet', 'filename': 'schnitzel.jpg'},

    # Brot & Backwaren
    {'name': 'Vollkornbrot 500g', 'search': 'whole grain bread loaf', 'filename': 'vollkornbrot.jpg'},
    {'name': 'Brötchen 6 Stück', 'search': 'bread rolls buns', 'filename': 'broetchen.jpg'},
    {'name': 'Milchbrötchen 4 Stück', 'search': 'sweet bread rolls', 'filename': 'milchbroetchen.jpg'},
    {'name': 'Croissants 4 Stück', 'search': 'croissants french pastry', 'filename': 'croissants.jpg'},

    # Getränke
    {'name': 'Mineralwasser 12x1L', 'search': 'mineral water bottles', 'filename': 'mineralwasser.jpg'},
    {'name': 'Apfelsaft 1L', 'search': 'apple juice bottle', 'filename': 'apfelsaft.jpg'},
    {'name': 'Cola 1.5L', 'search': 'cola soda bottle', 'filename': 'cola.jpg'},
]

# Pexels API (free, no key required for basic use)
# We'll use Lorem Picsum for reliable free images
def download_image(search_term, filename):
    """Download an image from Lorem Picsum (food category)"""

    # Map products to specific Lorem Picsum IDs that look like food
    food_image_ids = {
        'apfel.jpg': '1080',  # Apples
        'bananen.jpg': '1081',  # Bananas
        'bio_apfel.jpg': '429',  # More apples
        'bio_bananen.jpg': '1093',  # Organic bananas
        'tomaten.jpg': '1327',  # Tomatoes
        'gurken.jpg': '1425',  # Vegetables
        'kartoffeln.jpg': '1376',  # Potatoes
        'vollmilch.jpg': '674',  # Milk
        'bio_vollmilch.jpg': '674',  # Milk
        'joghurt.jpg': '674',  # Dairy
        'butter.jpg': '674',  # Dairy
        'gouda.jpg': '674',  # Cheese
        'quark.jpg': '674',  # Dairy
        'haehnchen.jpg': '996',  # Food/meat
        'rinderhack.jpg': '996',  # Meat
        'bratwurst.jpg': '996',  # Sausage
        'schnitzel.jpg': '996',  # Meat
        'vollkornbrot.jpg': '1775',  # Bread
        'broetchen.jpg': '1775',  # Bread rolls
        'milchbroetchen.jpg': '1775',  # Sweet rolls
        'croissants.jpg': '835',  # Pastry
        'mineralwasser.jpg': '564',  # Water bottles
        'apfelsaft.jpg': '434',  # Juice
        'cola.jpg': '436',  # Soda
    }

    try:
        # Use Lorem Picsum for reliable images
        image_id = food_image_ids.get(filename, '326')  # Default to food image
        url = f'https://picsum.photos/id/{image_id}/400/400'

        response = requests.get(url)
        if response.status_code == 200:
            filepath = os.path.join(IMAGE_DIR, filename)
            with open(filepath, 'wb') as f:
                f.write(response.content)
            print(f"[OK] Downloaded: {filename}")
            return True
        else:
            print(f"[FAIL] Failed to download {filename}: Status {response.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] Error downloading {filename}: {e}")
        return False

# Download all product images
print("Starting download of product images...")
print(f"Saving to: {os.path.abspath(IMAGE_DIR)}")
print("-" * 50)

successful = 0
failed = 0

for product in products:
    if download_image(product['search'], product['filename']):
        successful += 1
    else:
        failed += 1
    time.sleep(0.5)  # Be polite to the server

print("-" * 50)
print(f"Download complete!")
print(f"[OK] Successful: {successful}")
print(f"[FAIL] Failed: {failed}")
print(f"Images saved in: {os.path.abspath(IMAGE_DIR)}")