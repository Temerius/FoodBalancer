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

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Регистрация нового пользователя"""
    email = request.data.get('usr_mail')

    # Проверка на существующего пользователя перед валидацией сериализатора
    if email and User.objects.filter(usr_mail=email).exists():
        return Response(
            {'error': 'Пользователь с таким email уже существует'},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        try:
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)

            return Response({
                'user': UserSerializer(user).data,
                'token': token.key
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            # Обработка неожиданных ошибок
            return Response(
                {'error': f'Ошибка регистрации: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

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
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, username=email, password=password)

        if user:
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'user': UserSerializer(user).data,
                'token': token.key
            })
        else:
            return Response(
                {'error': 'Неверный email или пароль'},
                status=status.HTTP_401_UNAUTHORIZED
            )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def profile(request):
    """Получение и обновление профиля пользователя"""
    user = request.user

    if request.method == 'GET':
        serializer = UserSerializer(user)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request(request):
    """Запрос на сброс пароля"""
    serializer = PasswordResetRequestSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']

        try:
            user = User.objects.get(usr_mail=email)
            # Генерируем уникальный токен для восстановления пароля
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))

            # В реальном проекте здесь код отправки email
            # reset_url = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"
            # send_email(user.email, 'Восстановление пароля', f'Ссылка для сброса пароля: {reset_url}')

            # Для тестирования возвращаем токен и uid
            return Response({
                'success': True,
                'message': 'Инструкции по восстановлению пароля отправлены на указанный email',
                'debug_token': token if settings.DEBUG else None,
                'debug_uid': uid if settings.DEBUG else None
            })
        except User.DoesNotExist:
            # По соображениям безопасности не сообщаем, что пользователь не существует
            return Response({
                'success': True,
                'message': 'Если учетная запись существует, инструкции будут отправлены'
            })

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_confirm(request):
    """Подтверждение сброса пароля"""
    uid = request.data.get('uid', '')
    token = request.data.get('token', '')
    password = request.data.get('password', '')

    try:
        user_id = force_str(urlsafe_base64_decode(uid))
        user = User.objects.get(pk=user_id)

        if default_token_generator.check_token(user, token):
            user.set_password(password)
            user.save()
            return Response({
                'success': True,
                'message': 'Пароль успешно изменен'
            })
        else:
            return Response(
                {'error': 'Недействительный или истекший токен'},
                status=status.HTTP_400_BAD_REQUEST
            )
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        return Response(
            {'error': 'Недействительная ссылка для сброса пароля'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def logout(request):
    """Выход из системы"""
    try:
        # Удаляем токен пользователя
        request.user.auth_token.delete()
        return Response({'success': True})
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )