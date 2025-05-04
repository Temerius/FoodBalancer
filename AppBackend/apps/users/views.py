from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.authentication import TokenAuthentication
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.contrib.auth.tokens import default_token_generator

from .serializers import (
    UserSerializer,
    UserProfileSerializer,
    LoginSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer
)

import logging
import time

# Создаем логгер для модуля пользователей
logger = logging.getLogger('apps.users')

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Регистрация нового пользователя"""
    start_time = time.time()

    email = request.data.get('usr_mail')
    logger.info(f"Registration attempt: email={email}")

    # Проверка на существующего пользователя перед валидацией сериализатора
    if email and User.objects.filter(usr_mail=email).exists():
        logger.warning(f"Registration failed - email already exists: {email}")
        return Response(
            {'error': 'Пользователь с таким email уже существует'},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        try:
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)

            logger.info(
                f"User registered successfully: user_id={user.usr_id}, email={email}, time={time.time() - start_time:.2f}s")
            return Response({
                'user': UserSerializer(user).data,
                'token': token.key
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            # Более детальное логирование исключения
            logger.error(f"Registration error: {str(e)}", exc_info=True)
            return Response(
                {'error': f'Ошибка регистрации: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

    # Детальное логирование ошибок валидации
    error_fields = ", ".join(serializer.errors.keys())
    logger.warning(f"Registration validation error: fields={error_fields}, time={time.time() - start_time:.2f}s")

    # Обработка ошибок валидации
    error_message = 'Ошибка валидации данных'
    if serializer.errors:
        # Собираем все ошибки в одно сообщение
        field_errors = []
        for field, errors in serializer.errors.items():
            error_text = ' '.join(str(e) for e in errors)
            field_errors.append(f"{field}: {error_text}")

        if field_errors:
            error_message = '. '.join(field_errors)

    return Response({'error': error_message}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """Авторизация пользователя"""
    start_time = time.time()

    # Структурированное логирование начала запроса
    logger.info(f"Login attempt: email={request.data.get('email', 'unknown')}")

    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, username=email, password=password)

        if user:
            token, _ = Token.objects.get_or_create(user=user)
            # Успешная авторизация
            logger.info(
                f"User login successful: user_id={user.usr_id}, email={email}, time={time.time() - start_time:.2f}s")
            return Response({
                'user': UserSerializer(user).data,
                'token': token.key
            })
        else:
            # Неудачная авторизация
            logger.warning(f"Failed login attempt: email={email}, time={time.time() - start_time:.2f}s")
            return Response(
                {'error': 'Неверный email или пароль'},
                status=status.HTTP_401_UNAUTHORIZED
            )

    # Ошибка валидации данных
    logger.warning(f"Login validation error: {serializer.errors}, time={time.time() - start_time:.2f}s")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def profile(request):
    """Получение и обновление профиля пользователя"""
    user = request.user
    start_time = time.time()

    if request.method == 'GET':
        logger.info(f"Profile accessed: user_id={user.usr_id}")
        serializer = UserSerializer(user)
        return Response(serializer.data)

    elif request.method == 'PUT':
        logger.info(f"Profile update attempt: user_id={user.usr_id}")

        data = request.data.copy()

        # Обработка поля gender - преобразуем к формату, ожидаемому PostgreSQL
        if 'usr_gender' in data:
            gender_value = data['usr_gender']
            # Преобразуем к формату с заглавной буквы
            if gender_value.lower() == 'male':
                data['usr_gender'] = 'Male'
            elif gender_value.lower() == 'female':
                data['usr_gender'] = 'Female'

        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            logger.info(f"Profile updated successfully: user_id={user.usr_id}, time={time.time() - start_time:.2f}s")
            return Response(serializer.data)

        logger.warning(f"Profile update validation error: user_id={user.usr_id}, errors={serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request(request):
    """Запрос на сброс пароля"""
    start_time = time.time()
    serializer = PasswordResetRequestSerializer(data=request.data)

    if serializer.is_valid():
        email = serializer.validated_data['email']
        logger.info(f"Password reset requested for email: {email}")

        try:
            user = User.objects.get(usr_mail=email)
            # Генерируем уникальный токен для восстановления пароля
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))

            # В реальном проекте здесь код отправки email
            # reset_url = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"
            # send_email(user.email, 'Восстановление пароля', f'Ссылка для сброса пароля: {reset_url}')

            logger.info(
                f"Password reset token generated for user_id={user.usr_id}, time={time.time() - start_time:.2f}s")

            # Для тестирования возвращаем токен и uid
            return Response({
                'success': True,
                'message': 'Инструкции по восстановлению пароля отправлены на указанный email',
                'debug_token': token if settings.DEBUG else None,
                'debug_uid': uid if settings.DEBUG else None
            })
        except User.DoesNotExist:
            # По соображениям безопасности не сообщаем, что пользователь не существует
            logger.info(f"Password reset requested for non-existent email: {email}")
            return Response({
                'success': True,
                'message': 'Если учетная запись существует, инструкции будут отправлены'
            })

    logger.warning(f"Password reset request validation error: {serializer.errors}")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_confirm(request):
    """Подтверждение сброса пароля"""
    start_time = time.time()
    uid = request.data.get('uid', '')
    token = request.data.get('token', '')
    password = request.data.get('password', '')

    logger.info(f"Password reset confirmation attempt with token")

    try:
        user_id = force_str(urlsafe_base64_decode(uid))
        user = User.objects.get(pk=user_id)

        if default_token_generator.check_token(user, token):
            user.set_password(password)
            user.save()
            logger.info(f"Password reset successful for user_id={user.usr_id}, time={time.time() - start_time:.2f}s")
            return Response({
                'success': True,
                'message': 'Пароль успешно изменен'
            })
        else:
            logger.warning(f"Invalid or expired token for password reset: user_id={user.usr_id}")
            return Response(
                {'error': 'Недействительный или истекший токен'},
                status=status.HTTP_400_BAD_REQUEST
            )
    except (TypeError, ValueError, OverflowError, User.DoesNotExist) as e:
        logger.error(f"Password reset confirmation error: {str(e)}")
        return Response(
            {'error': 'Недействительная ссылка для сброса пароля'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def logout(request):
    """Выход из системы"""
    user_id = request.user.usr_id
    logger.info(f"Logout attempt: user_id={user_id}")

    try:
        # Удаляем токен пользователя
        request.user.auth_token.delete()
        logger.info(f"User logged out successfully: user_id={user_id}")
        return Response({'success': True})
    except Exception as e:
        logger.error(f"Logout error for user_id={user_id}: {str(e)}", exc_info=True)
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )