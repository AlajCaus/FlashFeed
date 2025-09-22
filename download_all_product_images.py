import os
import requests
from time import sleep

# Define all products with their Pexels URLs
products = [
    {'name': 'Äpfel', 'url': 'https://images.pexels.com/photos/347926/pexels-photo-347926.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'apfel.jpg'},
    {'name': 'Bio-Äpfel', 'url': 'https://images.pexels.com/photos/1510392/pexels-photo-1510392.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'bio_apfel.jpg'},
    {'name': 'Bananen', 'url': 'https://images.pexels.com/photos/2872755/pexels-photo-2872755.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'bananen.jpg'},
    {'name': 'Bio-Bananen', 'url': 'https://images.pexels.com/photos/4114143/pexels-photo-4114143.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'bio_bananen.jpg'},
    {'name': 'Tomaten', 'url': 'https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'tomaten.jpg'},
    {'name': 'Gurken', 'url': 'https://images.pexels.com/photos/2329440/pexels-photo-2329440.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'gurken.jpg'},
    {'name': 'Kartoffeln', 'url': 'https://images.pexels.com/photos/221540/pexels-photo-221540.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'kartoffeln.jpg'},
    {'name': 'Vollmilch', 'url': 'https://images.pexels.com/photos/248412/pexels-photo-248412.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'vollmilch.jpg'},
    {'name': 'Bio-Vollmilch', 'url': 'https://images.pexels.com/photos/1435272/pexels-photo-1435272.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'bio_vollmilch.jpg'},
    {'name': 'Butter', 'url': 'https://images.pexels.com/photos/531334/pexels-photo-531334.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'butter.jpg'},
    {'name': 'Gouda Käse', 'url': 'https://images.pexels.com/photos/821365/pexels-photo-821365.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'gouda.jpg'},
    {'name': 'Schnitzel', 'url': 'https://images.pexels.com/photos/1352270/pexels-photo-1352270.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'schnitzel.jpg'},
    {'name': 'Vollkornbrot', 'url': 'https://images.pexels.com/photos/1556674/pexels-photo-1556674.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'vollkornbrot.jpg'},
    {'name': 'Milchbrötchen', 'url': 'https://images.pexels.com/photos/2103949/pexels-photo-2103949.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'milchbroetchen.jpg'},
    {'name': 'Croissants', 'url': 'https://images.pexels.com/photos/3724/food-morning-breakfast-orange-juice.jpg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'croissants.jpg'},
    {'name': 'Mineralwasser', 'url': 'https://images.pexels.com/photos/1000084/pexels-photo-1000084.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'mineralwasser.jpg'},
    {'name': 'Apfelsaft', 'url': 'https://images.pexels.com/photos/1487511/pexels-photo-1487511.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'apfelsaft.jpg'},
    {'name': 'Cola', 'url': 'https://images.pexels.com/photos/50593/coca-cola-cold-drink-soft-drink-coke-50593.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'cola.jpg'},
]

# Create assets directory if it doesn't exist
os.makedirs('assets/images/products', exist_ok=True)

print("Downloading all product images...")
print("=" * 50)

success_count = 0
fail_count = 0
skip_count = 0

for product in products:
    filepath = f'assets/images/products/{product["filename"]}'

    # Skip if file already exists
    if os.path.exists(filepath):
        print(f"[SKIP] {product['filename']} already exists")
        skip_count += 1
        continue

    try:
        print(f"Downloading {product['name']}...", end="")
        response = requests.get(product['url'], timeout=10)

        if response.status_code == 200:
            with open(filepath, 'wb') as f:
                f.write(response.content)
            print(f" [OK] {product['filename']}")
            success_count += 1
        else:
            print(f" [FAIL] Status code: {response.status_code}")
            fail_count += 1

    except Exception as e:
        print(f" [ERROR] {str(e)}")
        fail_count += 1

    # Small delay to be polite to the server
    sleep(0.5)

print("\n" + "=" * 50)
print(f"Download complete!")
print(f"Successfully downloaded: {success_count}")
print(f"Already existed: {skip_count}")
print(f"Failed: {fail_count}")
print(f"Total products: {len(products)}")