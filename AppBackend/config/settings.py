# Указываем кастомную модель пользователя
AUTH_USER_MODEL = 'users.User'

# Настройки REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Добавляем приложения в INSTALLED_APPS
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Сторонние приложения
    'rest_framework',
    'rest_framework.authtoken',  # Добавляем это
    'corsheaders',
    
    # Наши приложения
    'apps.users',
]

# Обновленные ALLOWED_HOSTS
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '192.168.151.120']

# Настройки CORS
CORS_ALLOW_ALL_ORIGINS = True