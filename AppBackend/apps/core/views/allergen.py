
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q

from ..models import Allergen, M2MUsrAlg
from ..serializers import AllergenSerializer, UserAllergenSerializer

import logging
import time


logger = logging.getLogger('apps.core.allergens')


class AllergenViewSet(viewsets.ReadOnlyModelViewSet):
    """API для доступа к аллергенам"""
    queryset = Allergen.objects.all()
    serializer_class = AllergenSerializer
    permission_classes = [IsAuthenticated]

    def list(self, request, *args, **kwargs):
        """Получение списка аллергенов"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing all allergens: user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = response.data['count'] if 'count' in response.data else 'unknown'
        logger.info(f"Retrieved {count} allergens, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def retrieve(self, request, *args, **kwargs):
        """Получение конкретного аллергена"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        allergen_id = instance.alg_id

        logger.info(f"Retrieving allergen: allergen_id={allergen_id}, user_id={user_id}")
        response = super().retrieve(request, *args, **kwargs)
        logger.info(
            f"Retrieved allergen: allergen_id={allergen_id}, name='{instance.alg_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response


class UserAllergenViewSet(viewsets.ModelViewSet):
    """API для управления аллергенами пользователя"""
    serializer_class = UserAllergenSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'], url_path='update')
    def update_user_allergens(self, request):
        """Update user's allergens"""
        import logging
        logger = logging.getLogger('apps.core')

        logger.info(f"Starting user allergens update for user ID: {request.user.usr_id}")
        logger.info(f"Request data: {request.data}")

        try:
            allergen_ids = request.data.get('allergen_ids', [])
            user = request.user

            logger.info(f"Allergen IDs to update: {allergen_ids}")

            
            from apps.core.models import M2MUsrAlg, Allergen
            from django.contrib.auth import get_user_model

            User = get_user_model()
            user_obj = User.objects.get(usr_id=user.usr_id)

            
            delete_count = M2MUsrAlg.objects.filter(mua_usr_id=user.usr_id).delete()
            logger.info(f"Deleted {delete_count} existing allergen records")

            
            created_allergens = []
            for allergen_id in allergen_ids:
                
                allergen_obj = Allergen.objects.get(alg_id=allergen_id)

                
                allergen_relation = M2MUsrAlg.objects.create(
                    mua_usr_id=user_obj,  
                    mua_alg_id=allergen_obj  
                )
                created_allergens.append(allergen_id)
                logger.info(f"Created allergen mapping: user {user.usr_id} - allergen {allergen_id}")

            logger.info(f"Successfully updated allergens for user {user.usr_id}: {created_allergens}")

            return Response({
                'success': True,
                'message': 'Allergens updated successfully'
            })
        except Exception as e:
            import traceback
            error_traceback = traceback.format_exc()
            logger.error(f"Error updating allergens: {str(e)}")
            logger.error(f"Traceback: {error_traceback}")

            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    def get_queryset(self):
        """Возвращает аллергены текущего пользователя"""
        user_id = self.request.user.usr_id
        logger.debug(f"Getting user allergens: user_id={user_id}")
        return M2MUsrAlg.objects.filter(mua_usr_id=self.request.user)

    def list(self, request, *args, **kwargs):
        """Получение списка аллергенов пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Listing user allergens: user_id={user_id}")

        response = super().list(request, *args, **kwargs)
        count = len(response.data) if isinstance(response.data, list) else 'unknown'
        logger.info(f"Retrieved {count} user allergens, user_id={user_id}, time={time.time() - start_time:.2f}s")
        return response

    def create(self, request, *args, **kwargs):
        """Добавление аллергена пользователю"""
        start_time = time.time()
        user_id = request.user.usr_id

        if 'mua_alg_id' not in request.data:
            logger.warning(f"Missing allergen ID in add request: user_id={user_id}")
            return Response(
                {"error": "Необходимо указать ID аллергена"},
                status=status.HTTP_400_BAD_REQUEST
            )

        allergen_id = request.data['mua_alg_id']
        logger.info(f"Adding allergen to user: allergen_id={allergen_id}, user_id={user_id}")

        
        if M2MUsrAlg.objects.filter(mua_usr_id=request.user, mua_alg_id=allergen_id).exists():
            logger.info(f"Allergen already added to user: allergen_id={allergen_id}, user_id={user_id}")
            return Response(
                {"error": "Этот аллерген уже добавлен"},
                status=status.HTTP_400_BAD_REQUEST
            )

        
        try:
            allergen = Allergen.objects.get(alg_id=allergen_id)
            allergen_rel = M2MUsrAlg.objects.create(
                mua_usr_id=request.user,
                mua_alg_id_id=allergen_id
            )

            logger.info(
                f"Allergen added to user: allergen_id={allergen_id}, name='{allergen.alg_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
            serializer = self.get_serializer(allergen_rel)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Allergen.DoesNotExist:
            logger.warning(f"Allergen not found: allergen_id={allergen_id}, user_id={user_id}")
            return Response(
                {"error": "Указанный аллерген не существует"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(
                f"Error adding allergen to user: allergen_id={allergen_id}, user_id={user_id}, error: {str(e)}",
                exc_info=True)
            return Response(
                {"error": f"Произошла ошибка: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def destroy(self, request, *args, **kwargs):
        """Удаление аллергена у пользователя"""
        start_time = time.time()
        instance = self.get_object()
        user_id = request.user.usr_id
        allergen_id = instance.mua_alg_id.alg_id
        allergen_name = instance.mua_alg_id.alg_name

        
        if instance.mua_usr_id != request.user:
            logger.warning(
                f"Unauthorized allergen delete attempt: allergen_id={allergen_id}, requested_by={user_id}, owner={instance.mua_usr_id.usr_id}")
            return Response(
                {"error": "У вас нет прав на удаление этого аллергена"},
                status=status.HTTP_403_FORBIDDEN
            )

        logger.info(
            f"Removing allergen from user: allergen_id={allergen_id}, name='{allergen_name}', user_id={user_id}")
        self.perform_destroy(instance)
        logger.info(
            f"Allergen removed from user: allergen_id={allergen_id}, name='{allergen_name}', user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def user_allergens(self, request):
        """Получить все аллергены пользователя"""
        start_time = time.time()
        user_id = request.user.usr_id
        logger.info(f"Getting allergen IDs for user_id={user_id}")

        user_allergens = self.get_queryset()

        
        allergen_ids = [rel.mua_alg_id.alg_id for rel in user_allergens]
        count = len(allergen_ids)

        logger.info(f"Retrieved {count} allergen IDs for user_id={user_id}, time={time.time() - start_time:.2f}s")
        return Response(allergen_ids, status=status.HTTP_200_OK)
