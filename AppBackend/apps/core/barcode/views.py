

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
import logging
import time

from .parser import search_product_by_barcode
from .ai_helper import AIHelper
from ..models import IngredientType, Allergen


logger = logging.getLogger('apps.core.barcode')


@api_view(['GET'])
@permission_classes([AllowAny])
def get_product_by_barcode(request):
    """
    Получение информации о продукте по штрихкоду с классификацией
    """
    start_time = time.time()
    barcode = request.query_params.get('barcode')

    if not barcode:
        logger.warning("Запрос без штрихкода")
        return Response({
            "error": "Необходимо указать штрихкод продукта"
        }, status=status.HTTP_400_BAD_REQUEST)

    logger.info(f"Запрос информации по штрихкоду: {barcode}")

    
    products = search_product_by_barcode(barcode)

    if not products:
        logger.warning(f"Продукт с штрихкодом {barcode} не найден")
        return Response({
            "error": f"Продукт с штрихкодом {barcode} не найден"
        }, status=status.HTTP_404_NOT_FOUND)

    logger.info(f"Найден продукт по штрихкоду {barcode}: {products[0].get('name', 'Неизвестно')}")

    
    product = products[0]

    
    product['barcode'] = barcode

    
    ingredient_types = list(IngredientType.objects.all())
    allergens = list(Allergen.objects.all())

    logger.info(f"Получено {len(ingredient_types)} типов ингредиентов и {len(allergens)} аллергенов из БД")

    
    if not ingredient_types or not allergens:
        logger.warning("Нет данных о типах ингредиентов или аллергенах в БД, классификация невозможна")
        return Response({
            "barcode": barcode,
            "product": product,
            "warning": "Классификация невозможна из-за отсутствия данных в БД"
        })

    
    try:
        ai_helper = AIHelper()

        
        classification = ai_helper.classify_product(
            product, ingredient_types, allergens
        )

        
        product['classification'] = classification

    except Exception as e:
        logger.error(f"Ошибка при классификации продукта: {str(e)}")
        
        product['classification'] = {
            "ingredient_type_id": None,
            "allergen_ids": []
        }

    
    if product['classification']['ingredient_type_id'] is not None:
        ingredient_type_id = product['classification']['ingredient_type_id']
        for itype in ingredient_types:
            if itype.igt_id == ingredient_type_id:
                product['classification']['ingredient_type_name'] = itype.igt_name
                break

    
    if 'allergen_ids' in product['classification']:
        allergen_names = []
        for allergen in allergens:
            if allergen.alg_id in product['classification']['allergen_ids']:
                allergen_names.append(allergen.alg_name)
        product['classification']['allergen_names'] = allergen_names

    
    product['weight_formatted'] = _format_weight(product.get('weight', ''))

    
    _standardize_nutrient_format(product)

    
    logger.info(
        f"Успешно обработан запрос для штрихкода {barcode}, "
        f"время выполнения: {time.time() - start_time:.2f}s"
    )

    return Response({
        "barcode": barcode,
        "product": product
    })


def _format_weight(weight_str):
    """Форматирует строку веса в читаемый вид"""
    if not weight_str:
        return ""

    
    if not isinstance(weight_str, str):
        weight_str = str(weight_str)

    
    if 'г' in weight_str or 'кг' in weight_str or 'мл' in weight_str or 'л' in weight_str:
        return weight_str

    
    try:
        weight = float(weight_str.replace(',', '.'))

        
        if weight < 10:  
            return f"{weight} кг"
        else:
            return f"{weight} г"
    except:
        
        return weight_str


def _standardize_nutrient_format(product):
    """Стандартизирует формат информации о питательной ценности"""
    
    if 'calories' in product and product['calories']:
        if not isinstance(product['calories'], str) or 'ккал' not in product['calories']:
            product['calories'] = f"{product['calories']} ккал"

    
    if 'protein' in product and product['protein']:
        if not isinstance(product['protein'], str) or 'г' not in product['protein']:
            product['protein'] = f"{product['protein']} г"

    
    if 'fat' in product and product['fat']:
        if not isinstance(product['fat'], str) or 'г' not in product['fat']:
            product['fat'] = f"{product['fat']} г"

    
    if 'carbs' in product and product['carbs']:
        if not isinstance(product['carbs'], str) or 'г' not in product['carbs']:
            product['carbs'] = f"{product['carbs']} г"