# AppBackend/apps/core/barcode/ai_helper.py

import json
import os
import logging
import time
import re
from openai import AzureOpenAI
from django.conf import settings
from .prompts import PRODUCT_CLASSIFICATION_PROMPT

# Создаем логгер для модуля
logger = logging.getLogger('apps.core.barcode')


class AIHelper:
    """Класс для работы с Azure OpenAI"""

    def __init__(self):
        """Инициализация клиента OpenAI"""
        start_time = time.time()

        # Получаем параметры из .env через settings
        self.api_key = settings.AZURE_OPENAI_KEY
        self.endpoint = settings.AZURE_OPENAI_ENDPOINT

        logger.info(f"Инициализация AIHelper с endpoint: {self.endpoint}")

        # Создаем клиента с исправленными параметрами
        try:
            self.client = AzureOpenAI(
                azure_endpoint=self.endpoint,
                api_key=self.api_key,
                api_version="2024-02-01"  # Используем актуальную версию API
            )
            logger.info(f"Клиент OpenAI успешно инициализирован, время: {time.time() - start_time:.2f}s")
        except Exception as e:
            logger.error(f"Ошибка инициализации OpenAI клиента: {str(e)}")
            raise

    def _extract_json_from_markdown(self, text):
        """
        Извлекает JSON из ответа, который может содержать Markdown-форматирование
        """
        # Попытка найти JSON между маркерами кода
        json_pattern = r'```(?:json)?\s*([\s\S]*?)```'
        match = re.search(json_pattern, text)

        if match:
            # Если нашли JSON в блоке кода, используем его
            json_str = match.group(1).strip()
            logger.debug(f"Извлеченный JSON из блока кода: {json_str}")
            return json_str

        # Если не нашли маркеры кода, пытаемся найти что-то похожее на JSON объект
        json_pattern = r'\{[\s\S]*?\}'
        match = re.search(json_pattern, text)
        if match:
            json_str = match.group(0).strip()
            logger.debug(f"Извлеченный JSON из текста: {json_str}")
            return json_str

        # Если ничего не нашли, возвращаем исходный текст
        logger.warning(f"Не удалось извлечь JSON из ответа: {text}")
        return text

    def classify_product(self, product_data, ingredient_types, allergens):
        """
        Классифицирует продукт с помощью OpenAI

        Args:
            product_data (dict): Данные о продукте
            ingredient_types (list): Список доступных типов ингредиентов
            allergens (list): Список доступных аллергенов

        Returns:
            dict: Классификация продукта с типом и аллергенами
        """
        start_time = time.time()

        product_name = product_data.get('name', 'Неизвестно')
        logger.info(f"Начало классификации продукта: '{product_name}'")

        try:
            # Логируем списки типов и аллергенов
            ingredient_types_list = [
                {"id": type_data.igt_id, "name": type_data.igt_name}
                for type_data in ingredient_types
            ]
            allergens_list = [
                {"id": allergen_data.alg_id, "name": allergen_data.alg_name}
                for allergen_data in allergens
            ]

            logger.debug(f"Доступные типы ингредиентов: {json.dumps(ingredient_types_list, ensure_ascii=False)}")
            logger.debug(f"Доступные аллергены: {json.dumps(allergens_list, ensure_ascii=False)}")

            # Подготовка информации о типах продуктов
            ingredient_types_info = "\n".join([
                f"ID: {type_data.igt_id}, Название: {type_data.igt_name}"
                for type_data in ingredient_types
            ])

            # Подготовка информации об аллергенах
            allergens_info = "\n".join([
                f"ID: {allergen_data.alg_id}, Название: {allergen_data.alg_name}"
                for allergen_data in allergens
            ])

            # Заполняем промпт
            prompt = PRODUCT_CLASSIFICATION_PROMPT.format(
                name=product_data.get('name', 'Неизвестно'),
                ingredients=product_data.get('ingredients', 'Неизвестно'),
                ingredient_types=ingredient_types_info,
                allergens=allergens_info
            )

            logger.debug(f"Отправка запроса в OpenAI для продукта '{product_name}'")

            # Создаем сообщения для запроса
            messages = [
                {"role": "system", "content": "Ты эксперт в классификации продуктов питания."},
                {"role": "user", "content": prompt}
            ]

            # Вызываем API с исправленными параметрами
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",  # Используем доступную модель
                messages=messages,
                max_tokens=800  # Ограничиваем длину ответа
            )

            # Получаем ответ
            raw_result = response.choices[0].message.content
            logger.debug(f"Получен сырой ответ от OpenAI: {raw_result}")

            # Извлекаем JSON из возможного Markdown-ответа
            json_str = self._extract_json_from_markdown(raw_result)

            # Парсим JSON из ответа
            try:
                classification = json.loads(json_str)
                logger.debug(f"Успешно распарсили JSON: {classification}")
            except json.JSONDecodeError as e:
                logger.error(f"Ошибка парсинга JSON: {str(e)}, сырой JSON: {json_str}")
                # Возвращаем пустую классификацию в случае ошибки
                return {
                    "ingredient_type_id": None,
                    "allergen_ids": []
                }

            # Логируем результат классификации
            ingredient_type_id = classification.get('ingredient_type_id')
            allergen_ids = classification.get('allergen_ids', [])

            # Получаем имя типа продукта
            type_name = "Неизвестно"
            for type_data in ingredient_types:
                if type_data.igt_id == ingredient_type_id:
                    type_name = type_data.igt_name
                    break

            # Получаем имена аллергенов
            allergen_names = []
            for allergen_data in allergens:
                if allergen_data.alg_id in allergen_ids:
                    allergen_names.append(allergen_data.alg_name)

            logger.info(
                f"Продукт '{product_name}' классифицирован как '{type_name}' с аллергенами: {allergen_names}, "
                f"время: {time.time() - start_time:.2f}s"
            )

            return classification

        except Exception as e:
            logger.error(f"Ошибка при классификации продукта '{product_name}': {str(e)}", exc_info=True)
            # Возвращаем пустую классификацию в случае ошибки
            return {
                "ingredient_type_id": None,
                "allergen_ids": []
            }