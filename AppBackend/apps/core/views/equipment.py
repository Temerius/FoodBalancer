# AppBackend/apps/core/views/equipment.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import Equipment, M2MUsrEqp
from ..serializers import EquipmentSerializer, UserEquipmentSerializer

from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from ..mixins import CacheInvalidationMixin


class EquipmentViewSet(viewsets.ModelViewSet):
    """API для доступа к кухонному оборудованию"""
    queryset = Equipment.objects.all()
    serializer_class = EquipmentSerializer
    permission_classes = [IsAuthenticated]


@method_decorator(cache_page(60 * 60 * 10), name='list')
class UserEquipmentViewSet(CacheInvalidationMixin, viewsets.ModelViewSet):
    cache_prefix = 'user_equipment'
    """API для управления оборудованием пользователя"""
    serializer_class = UserEquipmentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Возвращает оборудование текущего пользователя"""
        return M2MUsrEqp.objects.filter(mue_usr_id=self.request.user)

    def create(self, request, *args, **kwargs):
        """Добавление оборудования пользователю"""
        if 'mue_eqp_id' not in request.data:
            return Response(
                {"error": "Необходимо указать ID оборудования"},
                status=status.HTTP_400_BAD_REQUEST
            )

        equipment_id = request.data['mue_eqp_id']

        # Проверка, существует ли уже такое оборудование у пользователя
        if M2MUsrEqp.objects.filter(mue_usr_id=request.user, mue_eqp_id=equipment_id).exists():
            return Response(
                {"error": "Это оборудование уже добавлено"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Создание связи
        equipment_rel = M2MUsrEqp.objects.create(
            mue_usr_id=request.user,
            mue_eqp_id_id=equipment_id
        )

        serializer = self.get_serializer(equipment_rel)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        """Удаление оборудования у пользователя"""
        instance = self.get_object()

        # Проверка, принадлежит ли связь текущему пользователю
        if instance.mue_usr_id != request.user:
            return Response(
                {"error": "У вас нет прав на удаление этого оборудования"},
                status=status.HTTP_403_FORBIDDEN
            )

        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def user_equipment(self, request):
        """Получить все оборудование пользователя"""
        user_equipment = self.get_queryset()

        # Получаем только ID оборудования для клиента
        equipment_ids = [rel.mue_eqp_id.eqp_id for rel in user_equipment]

        return Response(equipment_ids, status=status.HTTP_200_OK)