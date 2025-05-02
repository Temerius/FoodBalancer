# AppBackend/apps/core/mixins.py
from django.core.cache import cache
from rest_framework.response import Response


class CacheInvalidationMixin:
    """Миксин для инвалидации кэша при изменении данных"""
    cache_prefix = 'cache_key_'

    def invalidate_cache(self, prefix=None):
        """Инвалидация кэша по префиксу"""
        prefix = prefix or self.cache_prefix
        if hasattr(self, 'request') and hasattr(self.request, 'user'):
            user_id = self.request.user.pk
            cache_key = f"{prefix}_{user_id}"
            cache.delete(cache_key)

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        self.invalidate_cache()
        return response

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        self.invalidate_cache()
        return response

    def destroy(self, request, *args, **kwargs):
        response = super().destroy(request, *args, **kwargs)
        self.invalidate_cache()
        return response