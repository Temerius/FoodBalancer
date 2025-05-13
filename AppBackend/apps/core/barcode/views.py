# AppBackend/apps/core/barcode/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
import logging
import time
import json

from .parser import search_product_by_barcode
from .ai_helper import AIHelper
from ..models import IngredientType, Allergen

# Создаем логгер для модуля
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

    # Вызываем функцию поиска продукта
    products = search_product_by_barcode(barcode)

    if not products:
        logger.warning(f"Продукт с штрихкодом {barcode} не найден")
        return Response({
            "error": f"Продукт с штрихкодом {barcode} не найден"
        }, status=status.HTTP_404_NOT_FOUND)

    logger.info(f"Найден продукт по штрихкоду {barcode}: {products[0].get('name', 'Неизвестно')}")

    # Получаем первый найденный продукт
    product = products[0]

    # Получаем типы ингредиентов и аллергены из БД
    ingredient_types = list(IngredientType.objects.all())
    allergens = list(Allergen.objects.all())

    logger.info(f"Получено {len(ingredient_types)} типов ингредиентов и {len(allergens)} аллергенов из БД")

    # Если в БД нет данных, возвращаем продукт без классификации
    if not ingredient_types or not allergens:
        logger.warning("Нет данных о типах ингредиентов или аллергенах в БД, классификация невозможна")
        return Response({
            "barcode": barcode,
            "product": product,
            "warning": "Классификация невозможна из-за отсутствия данных в БД"
        })

    # Инициализируем AI помощника
    ai_helper = AIHelper()

    # Классифицируем продукт
    classification = ai_helper.classify_product(
        product, ingredient_types, allergens
    )

    # Добавляем классификацию к продукту
    product_with_classification = {
        **product,
        "classification": classification
    }

    # Логируем результат
    logger.info(
        f"Успешно обработан запрос для штрихкода {barcode}, "
        f"время выполнения: {time.time() - start_time:.2f}s"
    )

    return Response({
        "barcode": barcode,
        "product": product_with_classification
    })