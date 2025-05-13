import os
import requests
import re
import json
import time
from bs4 import BeautifulSoup
from googlesearch import search
from openai import AzureOpenAI

# Настройки Azure OpenAI
AZURE_OPENAI_KEY = "626b7cd3f01e4369bdd95568b4b4d8b0"
AZURE_OPENAI_ENDPOINT = "https://flowprompt-useast.openai.azure.com/"

# Инициализация Azure OpenAI клиента
client = AzureOpenAI(
    api_key=AZURE_OPENAI_KEY,  
    api_version="2023-05-15",
    azure_endpoint=AZURE_OPENAI_ENDPOINT
)

# Заголовки для HTTP-запросов
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
}

def search_product_by_barcode(barcode):
    """
    Поиск продукта по штрихкоду с использованием Google Search
    """
    # Формируем поисковый запрос с указанием белорусских ритейлеров
    query = f"{barcode}"
    
    try:
        print(f"Поиск продукта с штрихкодом: {barcode}")
        
        # Получаем результаты поиска (первые 5)
        search_results = list(search(query, num_results=5))
        
        if not search_results:
            print("Продукт не найден в результатах поиска")
            return None
        
        print(f"Найдено результатов: {len(search_results)}")
        for i, url in enumerate(search_results):
            print(f"{i+1}. {url}")
        
        # Фильтруем результаты, оставляя только поддерживаемые сайты
        valid_results = []
        for url in search_results:
            retailer = identify_retailer(url)
            if retailer:
                valid_results.append((url, retailer))
        
        if not valid_results:
            print("Не найдено результатов на поддерживаемых сайтах ритейлеров")
            return None
        
        # Для каждого валидного результата пытаемся получить информацию о продукте
        product_info = []
        for url, retailer in valid_results:
            print(f"\nОбработка URL: {url} (Ритейлер: {retailer})")
            
            try:
                if retailer == "green":
                    html_content = fetch_page(url)
                    if html_content:
                        # Сначала используем специализированный парсер для конкретного ритейлера
                        product_data = parse_green_product(html_content)
                        
                        print(product_data)
                        product_info.append(product_data)
                elif retailer == "sosedi":
                    html_content = fetch_page(url)
                    if html_content:
                    # Используем парсер для Соседи
                        product_data = parse_sosedi_product(html_content)
                        
                        print(product_data)
                        product_info.append(product_data)
                # Здесь будут добавлены другие ритейлеры аналогично
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

def parse_sosedi_product(html_content):
    """
    Парсинг страницы продукта Соседи через JSON-данные из SERVER_DATA
    """
    product_data = {}
    
    try:
        # Пробуем найти SERVER_DATA в HTML
        server_data_match = re.search(r'window\.SERVER_DATA=(\{.*?\})</script>', html_content, re.DOTALL)
        if not server_data_match:
            # Проверяем, если получен непосредственно JSON-объект (для тестирования)
            if html_content.strip().startswith('{') and html_content.strip().endswith('}'):
                server_data_str = html_content
            else:
                print("Не удалось найти SERVER_DATA на странице")
                return None
        else:
            server_data_str = server_data_match.group(1)
        
        # Исправляем проблемы с JSON перед парсингом
        # 1. Заменяем неэкранированные кавычки внутри строк
        server_data_str = re.sub(r':\s*"([^"]*)"([^"]*)"([^"]*)"', r':"\1\\"\2\\"\3"', server_data_str)
        
        # 2. Заменяем экранированные обратные слеши
        server_data_str = server_data_str.replace('\\\\', '\\')
        
        # 3. Имеем дело с экранированными кавычками
        server_data_str = server_data_str.replace('\\"', '"')
        
        # 4. Заменяем неэкранированные кавычки снова для большей надежности
        server_data_str = re.sub(r':\s*"([^"]*)("Клубника со вкусом сливок")([^"]*)"', 
                                 r':"\1\\"Клубника со вкусом сливок\\"\3"', server_data_str)
        
        # Преобразуем в словарь Python
        server_data = json.loads(server_data_str)
        
        # Извлекаем данные о продукте
        if 'product' in server_data:
            product_json = server_data['product']
            
            # Основная информация
            if 'name' in product_json:
                product_data['name'] = product_json['name']
            
            if 'cod' in product_json:
                product_data['barcode'] = product_json['cod']
            
            if 'weight' in product_json:
                try:
                    weight_float = float(product_json['weight'])
                    if weight_float < 1:
                        product_data['weight'] = f"{int(weight_float * 1000)}г"
                    else:
                        product_data['weight'] = f"{product_json['weight']}кг"
                except:
                    product_data['weight'] = product_json['weight']
            
            if 'price' in product_json:
                product_data['price'] = f"{product_json['price']} {product_json.get('currency', 'р')}"
            
            if 'pricePerKg' in product_json:
                product_data['price_per_kg'] = f"{product_json['pricePerKg']} {product_json.get('currency', 'р')}/кг"
            
            if 'description' in product_json:
                product_data['description'] = product_json['description']
            
            if 'manufacturer' in product_json:
                product_data['manufacturer'] = product_json['manufacturer']
            
            if 'country' in product_json:
                product_data['country'] = product_json['country']
            
            if 'img' in product_json:
                product_data['image_url'] = product_json['img']
            
            # Информация о питательной ценности
            if 'protein' in product_json and product_json['protein']:
                product_data['protein'] = product_json['protein']
            
            if 'fat' in product_json and product_json['fat']:
                product_data['fat'] = product_json['fat']
            
            if 'carbohydrate' in product_json and product_json['carbohydrate']:
                product_data['carbs'] = product_json['carbohydrate']
            
            if 'calorie' in product_json and product_json['calorie']:
                product_data['calories'] = product_json['calorie']
            
            # Состав продукта
            if 'composition' in product_json:
                product_data['ingredients'] = product_json['composition']
            
            # Категория
            category_id = product_json.get('categoryId')
            if category_id:
                product_data['category_id'] = category_id
                
                # Определяем категорию на основе названия
                name_lower = product_data.get('name', '').lower()
                if 'сырок' in name_lower or 'творож' in name_lower:
                    product_data['category'] = 'Молочные продукты'
                elif 'хлеб' in name_lower or 'булк' in name_lower:
                    product_data['category'] = 'Хлебобулочные изделия'  
            
            # Искусственно получаем процент жирности из названия
            if 'name' in product_data:
                fat_percent_match = re.search(r'(\d+(?:[.,]\d+)?)%', product_data['name'])
                if fat_percent_match:
                    product_data['fat_percentage'] = fat_percent_match.group(1) + '%'
            
            print(f"Успешно извлечена информация о продукте: {product_data.get('name')}")
            return product_data
        else:
            print("Данные о продукте не найдены в SERVER_DATA")
            return None
        
    except json.JSONDecodeError as e:
        print(f"Ошибка декодирования JSON: {str(e)}")
        print(f"Проблемный фрагмент JSON находится примерно здесь: {server_data_str[max(0, int(str(e).split('char ')[-1]) - 50):min(len(server_data_str), int(str(e).split('char ')[-1]) + 50)]}")
        return None
    except Exception as e:
        print(f"Ошибка при парсинге данных Соседи: {str(e)}")
        return None
    
def parse_green_product(html_content):
    """
    Парсит страницу продукта Green: название и картинку извлекает проверенным методом,
    остальное через срез после строки с названием
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    product_data = {}
    
    try:
        # 1. Извлекаем название продукта ПРОВЕРЕННЫМ МЕТОДОМ
        product_title = soup.find('h1', class_='product-modal_productTitle__2Hyco')
        if product_title:
            product_data['name'] = product_title.text.strip()
        else:
            # Запасной метод - поиск в title
            title_tag = soup.find('title')
            if title_tag:
                title_text = title_tag.text
                if "купить с доставкой" in title_text:
                    product_data['name'] = title_text.split("купить с доставкой")[0].strip()
        
        # 2. Извлекаем URL изображения ПРОВЕРЕННЫМ МЕТОДОМ
        image_pattern = r'"image":"(https://io\.activecloud\.com/static-green-market/[^"]+?\.(?:jpg|png|jpeg)[^"]*)"'
        image_match = re.search(image_pattern, html_content)
        if image_match:
            product_data['image_url'] = image_match.group(1)
        
        if 'image_url' not in product_data:
            secondary_pattern = r'"filename":"([^"]+\.(?:jpg|png|jpeg))"'
            secondary_match = re.search(secondary_pattern, html_content)
            if secondary_match:
                filename = secondary_match.group(1)
                product_data['image_url'] = f"https://io.activecloud.com/static-green-market/{filename}"
        
        # 3. НАХОДИМ СТРОКУ С НАЗВАНИЕМ ПРОДУКТА ДЛЯ ВЫПОЛНЕНИЯ СРЕЗА
        if 'name' in product_data:
            escaped_name = re.escape(product_data['name'])
            pattern = f'\\\\"{escaped_name}\\\\",\\\\"unit\\\\":\\\\"piece\\\\",\\\\"volume\\\\'
            match = re.search(pattern, html_content)
            
            if not match:
                # Запасной вариант - ищем похожую строку
                pattern = r'\\"([^"]+?)\\",\\"unit\\":\\"piece\\",\\"volume\\'
                matches = re.finditer(pattern, html_content)
                
                for m in matches:
                    if product_data['name'] in m.group(1):
                        match = m
                        break
            
            if match:
                # 4. ДЕЛАЕМ СРЕЗ ПОСЛЕ ОКОНЧАНИЯ СТРОКИ
                end_pos = match.end()
                data_segment = html_content[end_pos:end_pos + 5000]
                
                # 5. ИСПРАВЛЕНО: Извлекаем вес продукта (правильно извлекаем из поля volume)
                volume_pattern = r'^":\\"(.*?)\\",\\"'
                volume_match = re.search(volume_pattern, data_segment)
                if volume_match:
                    product_data['weight'] = volume_match.group(1)
                
                # 6. ИСПРАВЛЕНО: Упрощенное извлечение БЖУ и калорий напрямую из data_segment
                # Извлекаем белки
                nutrition_pattern = r'energyCost\\":\\"(.*?)(?:\\"|$)'
                nutrition_match = re.search(nutrition_pattern, data_segment)

                if nutrition_match:
                    # Если нашли блок с информацией о питательной ценности
                    nutrition_text = nutrition_match.group(1).replace('\\r\\n', '\n').replace('\\\\', '')
                else:
                    # Если специальный блок не найден, используем весь сегмент данных
                    nutrition_text = data_segment

                # Извлекаем белки с учетом разных форматов
                protein_pattern = r'[Б|б]елки\s*[-:–]?\s*([\d,\.]+)\s*г'
                protein_match = re.search(protein_pattern, nutrition_text)
                if protein_match:
                    product_data['protein'] = protein_match.group(1).replace(',', '.') + ' г'

                # Извлекаем жиры с учетом разных форматов
                fat_pattern = r'[Ж|ж]иры\s*[-:–]?\s*([\d,\.]+)\s*г'
                fat_match = re.search(fat_pattern, nutrition_text)
                if fat_match:
                    product_data['fat'] = fat_match.group(1).replace(',', '.') + ' г'

                # Извлекаем углеводы с учетом разных форматов
                carbs_pattern = r'[У|у]глеводы\s*[-:–]?\s*([\d,\.]+)\s*г'
                carbs_match = re.search(carbs_pattern, nutrition_text)
                if carbs_match:
                    product_data['carbs'] = carbs_match.group(1).replace(',', '.') + ' г'

                # Извлекаем калории с учетом разных форматов
                calories_pattern = r'[Э|э]нергетическая\s*ценность\s*[-:,–]?\s*([\d,\.]+)\s*ккал'
                calories_match = re.search(calories_pattern, nutrition_text)
                if not calories_match:
                    # Пробуем другой формат записи калорий
                    calories_pattern = r'калорийность\s*[-:,–]?\s*([\d,\.]+)\s*ккал'
                    calories_match = re.search(calories_pattern, nutrition_text)

                if calories_match:
                    product_data['calories'] = calories_match.group(1).replace(',', '.') + ' ккал'
                
                # 7. Извлекаем штрихкод
                barcode_pattern = r'"code\\":\\"(\d+?)\\"'
                barcode_match = re.search(barcode_pattern, data_segment)
                if barcode_match:
                    product_data['barcode'] = barcode_match.group(1)
                
                # 8. Извлекаем состав/описание
                description_pattern = r'"description\\":\\"(.*?)\\",\\"manufacturer'
                description_match = re.search(description_pattern, data_segment)
                if description_match:
                    raw_desc = description_match.group(1)
                    # Очистка от экранирования
                    clean_desc = raw_desc.replace('\\\\', '').replace('\\"', '"')
                    # Убираем лишние пробелы
                    clean_desc = re.sub(r'\s+', ' ', clean_desc).strip()
                    product_data['ingredients'] = clean_desc
                
                # 9. Извлекаем страну производства
                country_pattern = r'"producingCountry\\":\\"([^"]+?)\\"'
                country_match = re.search(country_pattern, data_segment)
                if country_match:
                    product_data['country'] = country_match.group(1)
                
                # 10. Извлекаем производителя
                producer_pattern = r'"producer\\":\\"([^"]+?)\\"'
                producer_match = re.search(producer_pattern, data_segment)
                if producer_match:
                    product_data['manufacturer'] = producer_match.group(1).replace('\\\\', '')
        
        print(f"Успешно извлечена информация о продукте: {product_data.get('name', 'Неизвестный продукт')}")
        return product_data
        
    except Exception as e:
        print(f"Ошибка при парсинге страницы Green: {str(e)}")
        import traceback
        traceback.print_exc()
        return None
    
    

def main():
    """
    Основная функция программы
    """
    print("🔎 Программа поиска информации о продуктах по штрихкоду")
    print("🇧🇾 Оптимизировано для рынка Республики Беларусь")
    print("💻 Введите штрихкод или 'выход' для завершения")
    
    
    barcode = '4810319002130'
    #barcode = '4620004250926'
    #barcode = '4607001413349'
    product_info = search_product_by_barcode(barcode)

main()



