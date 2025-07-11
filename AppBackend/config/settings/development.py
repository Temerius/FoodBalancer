from .base import *
from pathlib import Path

# Base directory from where settings are loaded
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Ensure logs directory exists
LOGS_DIR = BASE_DIR / 'logs'
LOGS_DIR.mkdir(exist_ok=True)


DEBUG = True

ALLOWED_HOSTS = ['localhost', '127.0.0.1', '192.168.151.120', '192.168.100.5', '192.168.100.6', '192.168.100.7', '192.168.100.8', '192.168.100.9', '192.168.192.120', '10.10.1.165']

PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
    'django.contrib.auth.hashers.Argon2PasswordHasher',
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
]
AUTH_PASSWORD_VALIDATORS = []

INTERNAL_IPS = [
    '127.0.0.1',
]

# Debug Toolbar settings
INSTALLED_APPS += [
    'debug_toolbar',
    #'django_extensions',
]

MIDDLEWARE = [
    'apps.core.middleware.PerformanceLoggingMiddleware',
    'debug_toolbar.middleware.DebugToolbarMiddleware',
    'apps.core.middleware.URLDebugMiddleware',
    'apps.core.middleware.ExceptionLoggingMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

DEBUG_TOOLBAR_CONFIG = {
    'SHOW_TOOLBAR_CALLBACK': lambda request: DEBUG,
}

# Добавляем кастомный JSON форматтер
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {asctime} {message}',
            'style': '{',
        },
        'json': {
            '()': 'apps.core.formatters.CustomJsonFormatter',
        },
    },
    'filters': {
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
        'file_debug': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'debug.log',
            'formatter': 'verbose',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
        },
        'file_info': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'info.log',
            'formatter': 'verbose',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
        },
        'file_error': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'error.log',
            'formatter': 'verbose',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
        },
        'json_file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'json_logs.log',
            'formatter': 'json',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file_info', 'file_error'],
            'level': 'INFO',
            'propagate': True,
        },
        'django.request': {
            'handlers': ['file_error', 'json_file'],
            'level': 'ERROR',
            'propagate': False,
        },
        'django.db.backends': {
            'handlers': ['file_debug'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'apps': {
            'handlers': ['console', 'file_debug', 'file_info', 'file_error', 'json_file'],
            'level': 'DEBUG',
            'propagate': True,
        },
        'apps.users': {
            'handlers': ['console', 'file_info', 'file_error', 'json_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps.core.recipes': {
            'handlers': ['console', 'file_info', 'json_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps.core.refrigerator': {
            'handlers': ['console', 'file_info', 'json_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps.core.shopping': {
            'handlers': ['console', 'file_info', 'json_file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}