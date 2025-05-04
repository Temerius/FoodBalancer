# AppBackend/config/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('apps.users.urls', namespace='users')),
    path('api/', include('apps.core.urls', namespace='core'))
]

# Add Debug Toolbar URLs
if settings.DEBUG:
    import debug_toolbar
    urlpatterns.append(path('__debug__/', include(debug_toolbar.urls)))

# Existing static/media configuration
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

from django.urls import get_resolver


def print_url_patterns():
    """Выводит все зарегистрированные URL-шаблоны"""
    print("\n" + "=" * 80)
    print("СПИСОК ВСЕХ ЗАРЕГИСТРИРОВАННЫХ URL-МАРШРУТОВ:")
    print("=" * 80)

    resolver = get_resolver()

    def collect_patterns(resolver, prefix=''):
        for pattern in resolver.url_patterns:
            if hasattr(pattern, 'pattern'):
                pattern_str = str(pattern.pattern)
                if hasattr(pattern, 'lookup_str'):
                    lookup_str = pattern.lookup_str
                    print(f"{prefix}{pattern_str} -> {lookup_str}")
                elif hasattr(pattern, 'callback') and pattern.callback:
                    callback_name = pattern.callback.__name__
                    print(f"{prefix}{pattern_str} -> {callback_name}")
                else:
                    print(f"{prefix}{pattern_str}")

                if hasattr(pattern, 'url_patterns'):
                    collect_patterns(pattern, prefix=f"{prefix}{pattern_str}")

    collect_patterns(resolver)
    print("=" * 80 + "\n")


# Запустить функцию при загрузке модуля
print_url_patterns()