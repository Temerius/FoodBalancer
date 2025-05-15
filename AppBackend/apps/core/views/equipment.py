

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import Equipment, M2MUsrEqp
from ..serializers import EquipmentSerializer, UserEquipmentSerializer

import logging
import time


logger = logging.getLogger('apps.core.equipment')


class EquipmentViewSet(viewsets.ModelViewSet):
    """API для доступа к кухонному оборудованию"""
    queryset = Equipment.objects.all()
    serializer_class = EquipmentSerializer
    permission_classes = [IsAuthenticated]

    def list(self, request, *args, **kwargs):
        """Получение списка оборудования"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing all equipment: user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = response.data['count'] if 'count' in response.data else 'unknown'
        logger.info(f"Retrieved {count} equipment items, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного оборудования"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        equipment_id = instance.eqp_id

        logger.info(f"Retrieving equipment: equipment_id={equipment_id}, user_id={user_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.info(
            f"Retrieved equipment: equipment_id={equipment_id}, type='{instance.eqp_type}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response


class UserEquipmentViewSet(viewsets.ModelViewSet):
    cache_prefix = 'user_equipment'
    """API для управления оборудованием пользователя"""
    serializer_class = UserEquipmentSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'], url_path='update')
    def update_user_equipment(self, request):
        """Update user's equipment"""
        import logging
        logger = logging.getLogger('apps.core')

        logger.info(f"Starting user equipment update for user ID: {request.user.usr_id}")
        logger.info(f"Request data: {request.data}")

        try:
            equipment_ids = request.data.get('equipment_ids', [])
            user = request.user

            logger.info(f"Equipment IDs to update: {equipment_ids}")

            
            from apps.core.models import M2MUsrEqp, Equipment
            from django.contrib.auth import get_user_model

            User = get_user_model()
            user_obj = User.objects.get(usr_id=user.usr_id)

            
            delete_count = M2MUsrEqp.objects.filter(mue_usr_id=user.usr_id).delete()
            logger.info(f"Deleted {delete_count} existing equipment records")

            
            created_equipment = []
            for equipment_id in equipment_ids:
                try:
                    
                    equipment_obj = Equipment.objects.get(eqp_id=equipment_id)

                    
                    M2MUsrEqp.objects.create(
                        mue_usr_id=user_obj,  
                        mue_eqp_id=equipment_obj  
                    )
                    created_equipment.append(equipment_id)
                    logger.info(f"Created equipment mapping: user {user.usr_id} - equipment {equipment_id}")
                except Equipment.DoesNotExist:
                    logger.warning(f"Equipment ID {equipment_id} not found")
                except Exception as eq_error:
                    logger.error(f"Error creating equipment mapping: {str(eq_error)}")

            logger.info(f"Successfully updated equipment for user {user.usr_id}: {created_equipment}")

            return Response({
                'success': True,
                'message': 'Equipment updated successfully'
            })
        except Exception as e:
            import traceback
            error_traceback = traceback.format_exc()
            logger.error(f"Error updating equipment: {str(e)}")
            logger.error(f"Traceback: {error_traceback}")

            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    def get_queryset(self):
        """Возвращает оборудование текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting user equipment: user_id={user_id}")
        return M2MUsrEqp.objects.filter(mue_usr_id=self.request.user)

    def list(self, request, *args, **kwargs):
        """Получение списка оборудования пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing user equipment: user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = len(response.data) if isinstance(response.data, list) else 'unknown'
        logger.info(f"Retrieved {count} user equipment items, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def create(self, request, *args, **kwargs):
        """Добавление оборудования пользователю"""
        start_time = time.time()
        user_id = request.user.usr_id

        if 'mue_eqp_id' not in request.data:
            logger.warning(f"Missing equipment ID in add request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID оборудования"},
                status=status.HTTP_400_BAD_REQUEST
            )

        equipment_id = request.data['mue_eqp_id']
        logger.info(f"Adding equipment to user: equipment_id={equipment_id}, user_id={user_id}")

        
        if M2MUsrEqp.objects.filter(mue_usr_id=request.user, mue_eqp_id=equipment_id).exists():
            logger.info(f"Equipment already added to user: equipment_id={equipment_id}, user_id={user_id}")
            return Response(
                {"error": "Это оборудование уже добавлено"},
                status=status.HTTP_400_BAD_REQUEST
            )

        
        try:
            equipment = Equipment.objects.get(eqp_id=equipment_id)
            equipment_rel = M2MUsrEqp.objects.create(
                mue_usr_id=request.user,
                mue_eqp_id_id=equipment_id
            )

            logger.info(
                f"Equipment added to user: equipment_id={equipment_id}, type='{equipment.eqp_type}', user_id={user_id}, time={time.time() - start_time:.2f}s")
            serializer = self.get_serializer(equipment_rel)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Equipment.DoesNotExist:
            logger.warning(f"Equipment not found: equipment_id={equipment_id}, user_id={user_id}")
            return Response(
                {"error": "Указанное оборудование не существует"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(
                f"Error adding equipment to user: equipment_id={equipment_id}, user_id={user_id}, error: {str(e)}",
                exc_info=True)
            return Response(
                {"error": f"Произошла ошибка: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def destroy(self, request, *args, **kwargs):
        """Удаление оборудования у пользователя"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        equipment_id = instance.mue_eqp_id.eqp_id
        equipment_type = instance.mue_eqp_id.eqp_type

        
        if instance.mue_usr_id != request.user:
            logger.warning(
                f"Unauthorized equipment delete attempt: equipment_id={equipment_id}, requested_by={user_id}, owner={instance.mue_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на удаление этого оборудования"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(
            f"Removing equipment from user: equipment_id={equipment_id}, type='{equipment_type}', user_id={user_id}")
        self.perform_destroy(instance)
        logger.info(
            f"Equipment removed from user: equipment_id={equipment_id}, type='{equipment_type}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def user_equipment(self, request):
        """Получить все оборудование пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Getting equipment IDs for user_id={user_id}")

        user_equipment = self.get_queryset()

        
        equipment_ids = [rel.mue_eqp_id.eqp_id for rel in user_equipment]
        count = len(equipment_ids)

        logger.info(f"Retrieved {count} equipment IDs for user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(equipment_ids, status=status.HTTP_200_OK)