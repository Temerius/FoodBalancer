

from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _

User = get_user_model()

class Allergen(models.Model):
    """Модель аллергена"""
    alg_id = models.AutoField(primary_key=True)
    alg_name = models.CharField(_('Название'), max_length=64)

    class Meta:
        db_table = 'allergen'
        verbose_name = _('Аллерген')
        verbose_name_plural = _('Аллергены')

    def __str__(self):
        return self.alg_name


class M2MUsrAlg(models.Model):
    """Связь между пользователем и аллергеном"""
    mua_alg_id = models.ForeignKey(
        'Allergen',
        on_delete=models.CASCADE,
        db_column='mua_alg_id',
        related_name='user_allergens',
        verbose_name=_('Аллерген'),
        primary_key=True  
    )
    mua_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='mua_usr_id',
        related_name='allergen_preferences',
        verbose_name=_('Пользователь'),
        primary_key=False  
    )

    class Meta:
        db_table = 'm2m_usr_alg'
        unique_together = ('mua_alg_id', 'mua_usr_id')  
        managed = True  
        verbose_name = _('Аллерген пользователя')
        verbose_name_plural = _('Аллергены пользователей')

    def __str__(self):
        return f'{self.mua_usr_id.usr_name} - {self.mua_alg_id.alg_name}'