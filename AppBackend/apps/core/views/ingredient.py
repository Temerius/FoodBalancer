# AppBackend/apps/core/views/ingredient.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from datetime import datetime, timedelta

from ..models import IngredientType, Ingredient, M2MUsrIng
from ..serializers import IngredientTypeSerializer, IngredientSerializer, IngredientDetailSerializer, \
    UserIngredientSerializer


class IngredientTypeViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к типам ингредиентов"""
    queryset = IngredientType.objects.all()
    serializer_class = IngredientTypeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Фильтрация типов ингредиентов по категории или названию"""
        queryset = IngredientType.objects.all()

        # Фильтрация по категории
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)

        # Поиск по названию
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(igt_name__icontains=search)

        return queryset


class IngredientViewSet(viewsets.ReadOnlyModelViewSet):
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
        queryset = Ingredient.objects.all()

        # Фильтрация по типу
        type_id = self.request.query_params.get('type_id')
        if type_id:
            queryset = queryset.filter(ing_igt_id=type_id)

        # Поиск по названию
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(ing_name__icontains=search)

        return queryset


class RefrigeratorViewSet(viewsets.ModelViewSet):
    """API для доступа к холодильнику пользователя (ингредиенты пользователя)"""
    serializer_class = UserIngredientSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает ингредиенты текущего пользователя"""
        return M2MUsrIng.objects.filter(mui_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Добавление ингредиента в холодильник пользователя"""
        if not all(k in request.data for k in ('mui_ing_id', 'mui_quantity', 'mui_quantity_type')):
            return Response(
                {"error": "Необходимо указать ингредиент, количество и единицу измерения"},
                status=status.HTTP_400_BAD_REQUEST
            )

        ingredient_id = request.data['mui_ing_id']

        # Проверка, существует ли уже такой ингредиент у пользователя
        if M2MUsrIng.objects.filter(mui_usr_id=request.user, mui_ing_id=ingredient_id).exists():
            return Response(
                {"error": "Этот ингредиент уже есть в холодильнике"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        refrigerator_item = M2MUsrIng.objects.create(
            mui_usr_id=request.user,
            mui_ing_id_id=ingredient_id,
            mui_quantity=request.data['mui_quantity'],
            mui_quantity_type=request.data['mui_quantity_type']
        )

        serializer = self.get_serializer(refrigerator_item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        """Обновление ингредиента в холодильнике"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()

        # Проверка, принадлежит ли ингредиент текущему пользователю
        if instance.mui_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на редактирование этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        """Удаление ингредиента из холодильника"""
        instance = self.get_object()

        # Проверка, принадлежит ли ингредиент текущему пользователю
        if instance.mui_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на удаление этого ингредиента"},
                status=status.HTTP_403_FORBIDDEN
            )

        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Получить ингредиенты с истекающим сроком годности (в течение 3 дней)"""
        now = datetime.now().date()
        future = now + timedelta(days=3)

        # Получаем ингредиенты пользователя
        user_ingredients = M2MUsrIng.objects.filter(mui_usr_id=request.user).select_related('mui_ing_id')

        # Фильтруем по сроку годности
        expiring_items = []
        for item in user_ingredients:
            if item.mui_ing_id.ing_exp_date and now <= item.mui_ing_id.ing_exp_date <= future:
                expiring_items.append(item)

        serializer = self.get_serializer(expiring_items, many=True)
        return Response(serializer.data)