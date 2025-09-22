import os
import requests
from time import sleep

# Define ONLY the 9 products that need fixing
products_to_fix = [
    {'name': 'Vollmilch', 'url': 'https://images.pexels.com/photos/1435272/pexels-photo-1435272.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'vollmilch.jpg'},
    {'name': 'Bratwurst', 'url': 'https://images.pexels.com/photos/410648/pexels-photo-410648.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'bratwurst.jpg'},
    {'name': 'Vollkornbrot', 'url': 'https://images.pexels.com/photos/209206/pexels-photo-209206.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'vollkornbrot.jpg'},
    {'name': 'Milchbrötchen', 'url': 'https://images.pexels.com/photos/298217/pexels-photo-298217.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'milchbroetchen.jpg'},
    {'name': 'Brötchen', 'url': 'https://images.pexels.com/photos/1775043/pexels-photo-1775043.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'broetchen.jpg'},
    {'name': 'Rinderhack', 'url': 'https://images.pexels.com/photos/618773/pexels-photo-618773.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'rinderhack.jpg'},
    {'name': 'Joghurt', 'url': 'https://images.pexels.com/photos/414262/pexels-photo-414262.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'joghurt.jpg'},
    {'name': 'Butter', 'url': 'https://images.pexels.com/photos/94443/pexels-photo-94443.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'butter.jpg'},
    {'name': 'Apfelsaft', 'url': 'https://images.pexels.com/photos/3679974/pexels-photo-3679974.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'filename': 'apfelsaft.jpg'},
]

print("Fixing 9 specific product images...")
print("=" * 50)

success_count = 0
fail_count = 0

for product in products_to_fix:
    filepath = f'assets/images/products/{product["filename"]}'

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
print(f"Fix complete!")
print(f"Successfully fixed: {success_count}")
print(f"Failed: {fail_count}")
print(f"Total to fix: {len(products_to_fix)}")