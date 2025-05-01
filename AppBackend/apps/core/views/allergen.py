# AppBackend/apps/core/views/allergen.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q

from ..models import Allergen, M2MUsrAlg
from ..serializers import AllergenSerializer, UserAllergenSerializer


class AllergenViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к аллергенам"""
    queryset = Allergen.objects.all()
    serializer_class = AllergenSerializer
    permission_classes = [IsAuthenticated]


class UserAllergenViewSet(viewsets.ModelViewSet):
    """API для управления аллергенами пользователя"""
    serializer_class = UserAllergenSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает аллергены текущего пользователя"""
        return M2MUsrAlg.objects.filter(mua_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Добавление аллергена пользователю"""
        if 'mua_alg_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID аллергена"},
                status=status.HTTP_400_BAD_REQUEST
            )

        allergen_id = request.data['mua_alg_id']

        # Проверка, существует ли уже такой аллерген у пользователя
        if M2MUsrAlg.objects.filter(mua_usr_id=request.user, mua_alg_id=allergen_id).exists():
            return Response(
                {"error": "Этот аллерген уже добавлен"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        allergen_rel = M2MUsrAlg.objects.create(
            mua_usr_id=request.user,
            mua_alg_id_id=allergen_id
        )

        serializer = self.get_serializer(allergen_rel)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        """Удаление аллергена у пользователя"""
        instance = self.get_object()

        # Проверка, принадлежит ли связь текущему пользователю
        if instance.mua_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на удаление этого аллергена"},
                status=status.HTTP_403_FORBIDDEN
            )

        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def user_allergens(self, request):
        """Получить все аллергены пользователя"""
        user_allergens = self.get_queryset()

        # Получаем только ID аллергенов для клиента
        allergen_ids = [rel.mua_alg_id.alg_id for rel in user_allergens]

        return Response(allergen_ids, status=status.HTTP_200_OK)