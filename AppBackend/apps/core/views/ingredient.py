
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q, Prefetch
from datetime import datetime, timedelta

from ..models import IngredientType, Ingredient, M2MUsrIng, IngredientToAllergen, Allergen
from ..serializers import IngredientTypeSerializer, IngredientSerializer, IngredientDetailSerializer, \
    UserIngredientSerializer

import logging
import time


logger = logging.getLogger('apps.core.refrigerator')


class IngredientTypeViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к типам ингредиентов"""
    queryset = IngredientType.objects.all()
    serializer_class = IngredientTypeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Фильтрация типов ингредиентов по категории или названию"""
        start_time = time.time()
        queryset = IngredientType.objects.all()

        
        category = self.request.query_params.get('category')
        if category:
            logger.debug(f"Filtering ingredient types by category: {category}")
            queryset = queryset.filter(category=category)

        
        search = self.request.query_params.get('search')
        if search:
            logger.info(f"Searching ingredient types: query='{search}', user_id={self.request.user.usr_id}")
            queryset = queryset.filter(igt_name__icontains=search)

        query_time = time.time() - start_time
        if query_time > 0.5:  
            logger.warning(f"Slow ingredient type query: {query_time:.2f}s, params={self.request.query_params}")

        return queryset

    def list(self, request, *args, **kwargs):
        """Получение списка типов ингредиентов"""
        start_time = time.time()
        logger.info(f"Listing ingredient types: user_id={request.user.usr_id}, params={request.query_params}")
        response = super().list(request, *args, **kwargs)
        logger.debug(
            f"Retrieved {response.data['count'] if 'count' in response.data else 'unknown'} ingredient types in {time.time() - start_time:.2f}s")
        return response



from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q, Prefetch
from datetime import datetime, timedelta

from ..models import IngredientType, Ingredient, M2MUsrIng, Allergen, IngredientToAllergen
from ..serializers import IngredientTypeSerializer, IngredientSerializer, IngredientDetailSerializer, \
    UserIngredientSerializer

import logging
import time


logger = logging.getLogger('apps.core.refrigerator')


class IngredientViewSet(viewsets.ModelViewSet):
    """API для доступа к ингредиентам"""
    queryset = Ingredient.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Выбор сериализатора в зависимости от действия"""
        if self.action == 'retrieve':
            return IngredientDetailSerializer
        return IngredientSerializer

    def get_queryset(self):
        """Фильтрация ингредиентов по типу или названию"""
        start_time = time.time()

        
        queryset = Ingredient.objects.select_related('ing_igt_id').prefetch_related(
            Prefetch('allergens', queryset=Allergen.objects.all()),
            'allergen_links'
        )

        
        type_id = self.request.query_params.get('type_id')
        if type_id:
            logger.debug(f"Filtering ingredients by type: {type_id}")
            queryset = queryset.filter(ing_igt_id=type_id)

        
        search = self.request.query_params.get('search')
        if search:
            logger.info(f"Searching ingredients: query='{search}', user_id={self.request.user.usr_id}")
            queryset = queryset.filter(ing_name__icontains=search)

        query_time = time.time() - start_time
        if query_time > 0.5:  
            logger.warning(f"Slow ingredient query: {query_time:.2f}s, params={self.request.query_params}")

        return queryset

    def create(self, request, *args, **kwargs):
        """Создание нового ингредиента с поддержкой аллергенов"""
        start_time = time.time()
        user_id = request.user.usr_id

        print(f"Creating ingredient with data: {request.data}")
        logger.info(f"Creating new ingredient: user_id={user_id}, data={request.data}")

        
        serializer = self.get_serializer(data=request.data)

        if serializer.is_valid():
            
            ingredient = serializer.save()

            headers = self.get_success_headers(serializer.data)

            
            logger.info(
                f"Ingredient created successfully: ingredient_id={ingredient.ing_id}, "
                f"name='{ingredient.ing_name}', type_id={ingredient.ing_igt_id.igt_id}, "
                f"user_id={user_id}, time={time.time() - start_time:.2f}s"
            )

            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        else:
            print(f"Serializer errors: {serializer.errors}")
            logger.warning(f"Failed to create ingredient: user_id={user_id}, errors={serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        """Обновление ингредиента с поддержкой аллергенов"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.ing_id
        ingredient_name = instance.ing_name

        logger.info(f"Updating ingredient: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}")

        
        allergen_ids = request.data.get('allergen_ids', None)
        if allergen_ids is not None:
            logger.info(
                f"Updating allergens for ingredient: ingredient_id={ingredient_id}, new_allergen_ids={allergen_ids}")

            
            IngredientToAllergen.objects.filter(mia_ing_id=instance).delete()

            
            for allergen_id in allergen_ids:
                try:
                    IngredientToAllergen.objects.create(
                        mia_ing_id=instance,
                        mia_alg_id_id=allergen_id
                    )
                except Exception as e:
                    logger.error(f"Error updating allergen link: allergen_id={allergen_id}, error={e}")

        
        old_name = instance.ing_name
        old_type_id = instance.ing_igt_id.igt_id

        response = super().update(request, *args, **kwargs)

        
        if response.status_code == status.HTTP_200_OK:
            new_name = response.data.get('ing_name', old_name)
            new_type_id = response.data.get('ing_igt_id', old_type_id)

            changes = []
            if old_name != new_name:
                changes.append(f"name: '{old_name}' -> '{new_name}'")
            if old_type_id != new_type_id:
                changes.append(f"type_id: {old_type_id} -> {new_type_id}")
            if allergen_ids is not None:
                changes.append(f"allergens updated to: {allergen_ids}")

            if changes:
                logger.info(
                    f"Ingredient updated: ingredient_id={ingredient_id}, "
                    f"changes: {', '.join(changes)}, user_id={user_id}, time={time.time() - start_time:.2f}s"
                )
            else:
                logger.info(
                    f"Ingredient update called but no changes made: ingredient_id={ingredient_id}, user_id={user_id}"
                )
        else:
            logger.warning(
                f"Failed to update ingredient: ingredient_id={ingredient_id}, user_id={user_id}, status={response.status_code}"
            )

        return response


class RefrigeratorViewSet(viewsets.ModelViewSet):
    """API для доступа к холодильнику пользователя (ингредиенты пользователя)"""
    serializer_class = UserIngredientSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает ингредиенты текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Accessing refrigerator: user_id={user_id}")

        
        return M2MUsrIng.objects.filter(
            mui_usr_id=self.request.user
        ).select_related(
            'mui_ing_id',
            'mui_ing_id__ing_igt_id'
        ).order_by('-mui_id')

    def list(self, request, *args, **kwargs):
        """Получение списка ингредиентов пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing refrigerator ingredients: user_id={user_id}")

        
        search_query = request.query_params.get('search', '')
        category_filter = request.query_params.get('category', '')
        expiring_soon = request.query_params.get('expiring_soon', '').lower() == 'true'

        queryset = self.get_queryset()

        
        if search_query:
            queryset = queryset.filter(
                Q(mui_ing_id__ing_name__icontains=search_query) |
                Q(mui_ing_id__ing_igt_id__igt_name__icontains=search_query)
            )

        
        if expiring_soon:
            now = datetime.now().date()
            future = now + timedelta(days=3)
            queryset = queryset.filter(
                mui_ing_id__ing_exp_date__lte=future,
                mui_ing_id__ing_exp_date__gte=now
            )

        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)

        
        response_data = {
            'results': serializer.data,
            'count': len(serializer.data),
            'stats': self._get_refrigerator_stats(request.user),
        }

        logger.info(
            f"Retrieved {len(serializer.data)} refrigerator ingredients for user_id={user_id}, time={time.time() - start_time:.2f}s"
        )
        return Response(response_data)

    def _get_refrigerator_stats(self, user):
        """Получение статистики холодильника"""
        now = datetime.now().date()
        total_items = M2MUsrIng.objects.filter(mui_usr_id=user).count()

        
        expiring_count = M2MUsrIng.objects.filter(
            mui_usr_id=user,
            mui_ing_id__ing_exp_date__lte=now + timedelta(days=3),
            mui_ing_id__ing_exp_date__gte=now
        ).count()

        
        expired_count = M2MUsrIng.objects.filter(
            mui_usr_id=user,
            mui_ing_id__ing_exp_date__lt=now
        ).count()

        return {
            'total_items': total_items,
            'expiring_soon': expiring_count,
            'expired': expired_count,
        }

    def create(self, request, *args, **kwargs):
        """Добавление ингредиента в холодильник пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Adding ingredient to refrigerator: user_id={user_id}")

        if not all(k in request.data for k in ('mui_ing_id', 'mui_quantity', 'mui_quantity_type')):
            logger.warning(f"Missing required fields for ingredient: user_id={user_id}, data={request.data}")
            return Response(
                {"error": "Необходимо указать ингредиент, количество и единицу измерения"},
                status=status.HTTP_400_BAD_REQUEST
            )

        ingredient_id = request.data['mui_ing_id']

        
        try:
            ingredient = Ingredient.objects.get(ing_id=ingredient_id)
            quantity = int(request.data['mui_quantity'])
            quantity_type = request.data['mui_quantity_type']

            
            refrigerator_item = M2MUsrIng.objects.create(
                mui_usr_id=request.user,
                mui_ing_id=ingredient,  
                mui_quantity=quantity,
                mui_quantity_type=quantity_type
            )

            logger.info(
                f"Ingredient added to refrigerator: ingredient_id={ingredient_id}, name='{ingredient.ing_name}', "
                f"quantity={quantity} {quantity_type}, user_id={user_id}, time={time.time() - start_time:.2f}s"
            )

            
            serializer = self.get_serializer(refrigerator_item)

            
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Ingredient.DoesNotExist:
            logger.warning(f"Ingredient not found: ingredient_id={ingredient_id}, user_id={user_id}")
            return Response(
                {"error": "Указанный ингредиент не существует"},
                status=status.HTTP_404_NOT_FOUND
            )
        except ValueError as e:
            logger.warning(f"Invalid data format: user_id={user_id}, error={str(e)}")
            return Response(
                {"error": f"Неверный формат данных: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(
                f"Error adding ingredient to refrigerator: ingredient_id={ingredient_id}, user_id={user_id}, error: {str(e)}",
                exc_info=True
            )
            return Response(
                {"error": f"Произошла ошибка: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, *args, **kwargs):
        """Обновление ингредиента в холодильнике"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.mui_ing_id.ing_id
        ingredient_name = instance.mui_ing_id.ing_name

        
        if instance.mui_usr_id != request.user:
            logger.warning(
                f"Unauthorized refrigerator update attempt: ingredient_id={ingredient_id}, requested_by={user_id}, owner={instance.mui_usr_id.usr_id}"
            )
            return Response(
                {"error": "У вас нет прав на редактирование этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        
        old_quantity = instance.mui_quantity
        old_quantity_type = instance.mui_quantity_type

        logger.info(
            f"Updating refrigerator ingredient: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}"
        )
        response = super().update(request, *args, **kwargs)

        
        if response.status_code == status.HTTP_200_OK:
            new_quantity = response.data.get('mui_quantity', old_quantity)
            new_quantity_type = response.data.get('mui_quantity_type', old_quantity_type)

            changes = []
            if old_quantity != new_quantity:
                changes.append(f"quantity: {old_quantity} -> {new_quantity}")
            if old_quantity_type != new_quantity_type:
                changes.append(f"type: {old_quantity_type} -> {new_quantity_type}")

            if changes:
                logger.info(
                    f"Refrigerator ingredient updated: ingredient_id={ingredient_id}, name='{ingredient_name}', "
                    f"changes: {', '.join(changes)}, user_id={user_id}, time={time.time() - start_time:.2f}s"
                )
            else:
                logger.info(
                    f"Refrigerator ingredient update called but no changes made: ingredient_id={ingredient_id}, user_id={user_id}"
                )
        else:
            logger.warning(
                f"Failed to update refrigerator ingredient: ingredient_id={ingredient_id}, user_id={user_id}, status={response.status_code}"
            )

        return response

    def destroy(self, request, *args, **kwargs):
        """Удаление ингредиента из холодильника"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        ingredient_id = instance.mui_ing_id.ing_id
        ingredient_name = instance.mui_ing_id.ing_name

        
        if instance.mui_usr_id != request.user:
            logger.warning(
                f"Unauthorized refrigerator delete attempt: ingredient_id={ingredient_id}, requested_by={user_id}, owner={instance.mui_usr_id.usr_id}"
            )
            return Response(
                {"error": "У вас нет прав на удаление этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(
            f"Removing ingredient from refrigerator: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}"
        )
        self.perform_destroy(instance)
        logger.info(
            f"Ingredient removed from refrigerator: ingredient_id={ingredient_id}, name='{ingredient_name}', user_id={user_id}, time={time.time() - start_time:.2f}s"
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Получить ингредиенты с истекающим сроком годности (в течение 3 дней)"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Checking expiring ingredients: user_id={user_id}")

        now = datetime.now().date()
        future = now + timedelta(days=3)

        
        user_ingredients = M2MUsrIng.objects.filter(
            mui_usr_id=request.user
        ).select_related('mui_ing_id', 'mui_ing_id__ing_igt_id')

        
        expiring_items = []
        for item in user_ingredients:
            if item.mui_ing_id.ing_exp_date and now <= item.mui_ing_id.ing_exp_date <= future:
                expiring_items.append(item)

        count = len(expiring_items)
        logger.info(f"Found {count} expiring ingredients for user_id={user_id}, time={time.time() - start_time:.2f}s")

        serializer = self.get_serializer(expiring_items, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def categories(self, request):
        """Получить все категории (типы) ингредиентов в холодильнике пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Getting refrigerator categories: user_id={user_id}")

        
        ingredient_types = IngredientType.objects.filter(
            igt_id__in=M2MUsrIng.objects.filter(
                mui_usr_id=request.user
            ).values_list('mui_ing_id__ing_igt_id', flat=True).distinct()
        )

        serializer = IngredientTypeSerializer(ingredient_types, many=True)

        logger.info(
            f"Found {len(serializer.data)} categories in refrigerator for user_id={user_id}, time={time.time() - start_time:.2f}s"
        )

        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def add_multiple(self, request):
        """Добавить несколько ингредиентов одновременно"""
        start_time = time.time()
        user_id = request.user.usr_id

        logger.info(f"Adding multiple ingredients to refrigerator: user_id={user_id}")

        if 'items' not in request.data or not isinstance(request.data['items'], list):
            return Response(
                {"error": "Необходимо передать список ингредиентов в поле 'items'"},
                status=status.HTTP_400_BAD_REQUEST
            )

        added_items = []
        errors = []

        for item in request.data['items']:
            if not all(k in item for k in ('mui_ing_id', 'mui_quantity', 'mui_quantity_type')):
                errors.append({
                    'ingredient_id': item.get('mui_ing_id'),
                    'error': 'Необходимо указать все поля'
                })
                continue

            try:
                
                ingredient = Ingredient.objects.get(ing_id=item['mui_ing_id'])

                
                if M2MUsrIng.objects.filter(
                        mui_usr_id=request.user,
                        mui_ing_id=item['mui_ing_id']
                ).exists():
                    errors.append({
                        'ingredient_id': item['mui_ing_id'],
                        'error': 'Ингредиент уже есть в холодильнике'
                    })
                    continue

                
                refrigerator_item = M2MUsrIng.objects.create(
                    mui_usr_id=request.user,
                    mui_ing_id=ingredient,
                    mui_quantity=item['mui_quantity'],
                    mui_quantity_type=item['mui_quantity_type']
                )

                added_items.append(refrigerator_item.mui_id)

            except Ingredient.DoesNotExist:
                errors.append({
                    'ingredient_id': item.get('mui_ing_id'),
                    'error': 'Ингредиент не найден'
                })
            except Exception as e:
                errors.append({
                    'ingredient_id': item.get('mui_ing_id'),
                    'error': str(e)
                })

        logger.info(
            f"Added {len(added_items)} ingredients, {len(errors)} errors for user_id={user_id}, time={time.time() - start_time:.2f}s"
        )

        return Response({
            'added': added_items,
            'errors': errors,
            'summary': {
                'total': len(request.data['items']),
                'added': len(added_items),
                'failed': len(errors)
            }
        }, status=status.HTTP_201_CREATED if added_items else status.HTTP_400_BAD_REQUEST)