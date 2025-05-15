import os
import requests
import re
import json
import time
from bs4 import BeautifulSoup
from googlesearch import search


HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
}


def search_product_by_barcode(barcode):
    """
    Поиск продукта по штрихкоду с использованием Google Search
    """
    
    query = f"{barcode}"

    try:
        print(f"Поиск продукта с штрихкодом: {barcode}")

        
        search_results = list(search(query, num=5))

        if not search_results:
            print("Продукт не найден в результатах поиска")
            return None

        print(f"Найдено результатов: {len(search_results)}")
        for i, url in enumerate(search_results):
            print(f"{i + 1}. {url}")

        
        valid_results = []
        for url in search_results:
            retailer = identify_retailer(url)
            if retailer:
                valid_results.append((url, retailer))

        if not valid_results:
            print("Не найдено результатов на поддерживаемых сайтах ритейлеров")
            return None

        
        product_info = []
        for url, retailer in valid_results:
            print(f"\nОбработка URL: {url} (Ритейлер: {retailer})")

            try:
                if retailer == "green":
                    html_content = fetch_page(url)
                    if html_content:
                        
                        product_data = parse_green_product(html_content)

                        print(product_data)
                        product_info.append(product_data)
                elif retailer == "sosedi":
                    html_content = fetch_page(url)
                    if html_content:
                        
                        product_data = parse_sosedi_product(html_content)

                        print(product_data)
                        product_info.append(product_data)
                
                else:
                    print(f"Парсер для {retailer} еще не реализован")
            except Exception as e:
                print(f"Ошибка при обработке {url}: {str(e)}")

        return product_info

    except Exception as e:
        print(f"Ошибка при поиске: {str(e)}")
        return None


def identify_retailer(url):
    if "green-dostavka.by" in url:
        return "green"
    elif "evroopt.by" in url or "e-dostavka.by" in url:
        return "evroopt"
    elif "gippo.by" in url:
        return "gippo"
    elif "almi.by" in url:
        return "almi"
    elif "sosedi-dostavka.by" in url:
        return "sosedi"
    return None


def fetch_page(url):
    """
    Получение HTML-содержимого страницы
    """
    try:
        response = requests.get(url, headers=HEADERS, timeout=10)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"Ошибка при получении страницы {url}: {str(e)}")
        return None


def parse_green_product(html_content):
    """
    Парсит страницу продукта Green и возвращает словарь с унифицированными полями
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    product_data = {}

    try:
        
        product_title = soup.find('h1', class_='product-modal_productTitle__2Hyco')
        if product_title:
            product_data['name'] = product_title.text.strip()
        else:
            
            title_tag = soup.find('title')
            if title_tag:
                title_text = title_tag.text
                if "купить с доставкой" in title_text:
                    product_data['name'] = title_text.split("купить с доставкой")[0].strip()

        
        image_pattern = r'"image":"(https://io\.activecloud\.com/static-green-market/[^"]+?\.(?:jpg|png|jpeg)[^"]*)"'
        image_match = re.search(image_pattern, html_content)
        if image_match:
            
            product_data['image_url'] = image_match.group(1)

        if 'image_url' not in product_data:
            secondary_pattern = r'"filename":"([^"]+\.(?:jpg|png|jpeg))"'
            secondary_match = re.search(secondary_pattern, html_content)
            if secondary_match:
                filename = secondary_match.group(1)
                url = f"https://io.activecloud.com/static-green-market/{filename}"
                
                product_data['image_url'] = url

        
        if 'name' in product_data:
            escaped_name = re.escape(product_data['name'])
            pattern = f'\\\\"{escaped_name}\\\\",\\\\"unit\\\\":\\\\"piece\\\\",\\\\"volume\\\\'
            match = re.search(pattern, html_content)

            if not match:
                
                pattern = r'\\"([^"]+?)\\",\\"unit\\":\\"piece\\",\\"volume\\'
                matches = re.finditer(pattern, html_content)

                for m in matches:
                    if product_data['name'] in m.group(1):
                        match = m
                        break

            if match:
                
                end_pos = match.end()
                data_segment = html_content[end_pos:end_pos + 5000]

                
                volume_pattern = r'^":\\"(.*?)\\",\\"'
                volume_match = re.search(volume_pattern, data_segment)
                if volume_match:
                    product_data['weight'] = volume_match.group(1)
                else:
                    product_data['weight'] = ""

                
                nutrition_pattern = r'energyCost\\":\\"(.*?)(?:\\"|$)'
                nutrition_match = re.search(nutrition_pattern, data_segment)

                if nutrition_match:
                    
                    nutrition_text = nutrition_match.group(1).replace('\\r\\n', '\n').replace('\\\\', '')
                else:
                    
                    nutrition_text = data_segment

                
                protein_pattern = r'[Б|б]елки\s*[-:–]?\s*([\d,\.]+)\s*г'
                protein_match = re.search(protein_pattern, nutrition_text)
                if protein_match:
                    product_data['protein'] = protein_match.group(1).replace(',', '.') + ' г'
                else:
                    product_data['protein'] = ""

                
                fat_pattern = r'[Ж|ж]иры\s*[-:–]?\s*([\d,\.]+)\s*г'
                fat_match = re.search(fat_pattern, nutrition_text)
                if fat_match:
                    product_data['fat'] = fat_match.group(1).replace(',', '.') + ' г'
                else:
                    product_data['fat'] = ""

                
                carbs_pattern = r'[У|у]глеводы\s*[-:–]?\s*([\d,\.]+)\s*г'
                carbs_match = re.search(carbs_pattern, nutrition_text)
                if carbs_match:
                    product_data['carbs'] = carbs_match.group(1).replace(',', '.') + ' г'
                else:
                    product_data['carbs'] = ""

                
                calories_pattern = r'[Э|э]нергетическая\s*ценность\s*[-:,–]?\s*([\d,\.]+)\s*ккал'
                calories_match = re.search(calories_pattern, nutrition_text)
                if not calories_match:
                    
                    calories_pattern = r'калорийность\s*[-:,–]?\s*([\d,\.]+)\s*ккал'
                    calories_match = re.search(calories_pattern, nutrition_text)

                if calories_match:
                    product_data['calories'] = calories_match.group(1).replace(',', '.') + ' ккал'
                else:
                    product_data['calories'] = ""

                
                description_pattern = r'"description\\":\\"(.*?)\\",\\"manufacturer'
                description_match = re.search(description_pattern, data_segment)
                if description_match:
                    raw_desc = description_match.group(1)
                    
                    clean_desc = raw_desc.replace('\\\\', '').replace('\\"', '"')
                    
                    clean_desc = re.sub(r'\s+', ' ', clean_desc).strip()
                    product_data['ingredients'] = clean_desc
                else:
                    product_data['ingredients'] = ""
        else:
            
            product_data['weight'] = ""
            product_data['ingredients'] = ""
            product_data['protein'] = ""
            product_data['fat'] = ""
            product_data['carbs'] = ""
            product_data['calories'] = ""

        
        product_data['store'] = "green"

        print(f"Успешно извлечена информация о продукте: {product_data.get('name', 'Неизвестный продукт')}")
        return product_data

    except Exception as e:
        print(f"Ошибка при парсинге страницы Green: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def parse_sosedi_product(html_content):
    """
    Парсит страницу продукта Соседи и возвращает словарь с унифицированными полями
    """
    product_data = {}

    try:
        
        if html_content.strip().startswith('{') and html_content.strip().endswith('}'):
            
            server_data_str = html_content.strip()
        else:
            
            server_data_match = re.search(r'window\.SERVER_DATA=(\{.*?\})</script>', html_content, re.DOTALL)
            if not server_data_match:
                print("Не удалось найти SERVER_DATA на странице")
                return None
            server_data_str = server_data_match.group(1)

        
        try:
            
            server_data = json.loads(server_data_str)
        except json.JSONDecodeError:
            
            
            server_data_str = server_data_str.replace('\\\\', '\\')

            
            
            pattern = r':\s*"([^"]*)"([^"]*)"([^"]*)"'
            while re.search(pattern, server_data_str):
                server_data_str = re.sub(pattern, r':"\1\\"\2\\"\3"', server_data_str)

            
            
            server_data_str = re.sub(r'"([^"]*)"([^"]*)"', r'"\1\\"\2"', server_data_str)

            
            server_data_str = server_data_str.replace('\\"', '"').replace('\\\\"', '\\"')

        
        try:
            server_data = json.loads(server_data_str)
        except json.JSONDecodeError as e:
            
            print(f"Невозможно распарсить JSON: {str(e)}")
            return None

        
        if 'product' in server_data:
            product_json = server_data['product']

            
            if 'name' in product_json:
                product_data['name'] = product_json['name']
            else:
                product_data['name'] = ""

            if 'weight' in product_json:
                try:
                    weight_float = float(product_json['weight'])
                    if weight_float < 1:
                        product_data['weight'] = f"{int(weight_float * 1000)}г"
                    else:
                        product_data['weight'] = f"{product_json['weight']}кг"
                except:
                    product_data['weight'] = product_json['weight']
            else:
                product_data['weight'] = ""

            
            if 'composition' in product_json and product_json['composition']:
                product_data['ingredients'] = product_json['composition']
            elif 'compositionTranslate' in product_json and product_json['compositionTranslate']:
                product_data['ingredients'] = product_json['compositionTranslate']
            else:
                product_data['ingredients'] = ""

            
            if 'protein' in product_json and product_json['protein']:
                product_data['protein'] = product_json['protein']
            else:
                product_data['protein'] = ""

            if 'fat' in product_json and product_json['fat']:
                product_data['fat'] = product_json['fat']
            else:
                product_data['fat'] = ""

            if 'carbohydrate' in product_json and product_json['carbohydrate']:
                product_data['carbs'] = product_json['carbohydrate']
            else:
                product_data['carbs'] = ""

            if 'calorie' in product_json and product_json['calorie']:
                product_data['calories'] = product_json['calorie']
            else:
                product_data['calories'] = ""

            
            product_data['store'] = "sosedi"

            
            if 'img' in product_json and product_json['img']:
                product_data['image_url'] = "https://bazar-store.by/" + product_json['img']
            else:
                
                soup = BeautifulSoup(html_content, 'html.parser')
                img_element = soup.find('img', class_='no-js-079366')

                if img_element and 'src' in img_element.attrs:
                    product_data['image_url'] = "https://bazar-store.by/" + img_element['src']
                else:
                    
                    img_pattern = r'<img[^>]*?class="[^"]*?no-js-\d+"[^>]*?src="([^"]+)"'
                    img_match = re.search(img_pattern, html_content)
                    if img_match:
                        product_data['image_url'] = "https://bazar-store.by/" + img_match.group(1)
                    else:
                        product_data['image_url'] = ""

            print(f"Успешно извлечена информация о продукте: {product_data.get('name')}")
            return product_data
        else:
            print("Данные о продукте не найдены в SERVER_DATA")
            return None

    except Exception as e:
        print(f"Ошибка при парсинге данных Соседи: {str(e)}")
        import traceback
        traceback.print_exc()
        return None