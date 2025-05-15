import hashlib
import os
from datetime import datetime, timedelta
import jwt
from django.conf import settings
from .models import User



TOKEN_STORAGE = {}


def generate_token(user_id):
    """Генерирует токен для пользователя"""
    token = hashlib.sha256(os.urandom(64)).hexdigest()
    TOKEN_STORAGE[token] = user_id
    return token


def get_user_by_token(token):
    """Возвращает пользователя по токену"""
    user_id = TOKEN_STORAGE.get(token)
    if user_id:
        try:
            return User.objects.get(usr_id=user_id)
        except User.DoesNotExist:
            return None
    return None


def remove_token(token):
    """Удаляет токен"""
    if token in TOKEN_STORAGE:
        del TOKEN_STORAGE[token]


def verify_password(user, plain_password):
    """Проверка пароля пользователя"""
    if not user.usr_pas_hash:
        return False

    
    md5_hash = hashlib.md5(plain_password.encode()).hexdigest()
    return user.usr_pas_hash == md5_hash


def generate_password_reset_token(user):
    """Генерация токена для сброса пароля"""
    payload = {
        'user_id': user.usr_id,
        'exp': datetime.utcnow() + timedelta(hours=24),
        'iat': datetime.utcnow(),
        'type': 'password_reset'
    }

    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm='HS256'
    )


def verify_password_reset_token(token):
    """Проверка токена для сброса пароля"""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )

        if payload['type'] != 'password_reset':
            return None

        user_id = payload['user_id']
        return User.objects.filter(usr_id=user_id).first()
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception:
        return None