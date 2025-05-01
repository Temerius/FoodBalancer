# AppBackend/apps/core/models/base.py
from django.db import models
from django.utils.translation import gettext_lazy as _

class TimeStampedModel(models.Model):
    """Абстрактная модель с временными метками"""
    created_at = models.DateTimeField(_('Дата создания'), auto_now_add=True)
    updated_at = models.DateTimeField(_('Дата обновления'), auto_now=True)

    class Meta:
        abstract = True