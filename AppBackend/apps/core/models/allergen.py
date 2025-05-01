# AppBackend/apps/core/models/allergen.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _

User = get_user_model()

class Allergen(models.Model):
    """Модель аллергена"""
    alg_id = models.AutoField(primary_key=True)
    alg_name = models.CharField(_('Название'), max_length=100)

    class Meta:
        db_table = 'allergen'
        verbose_name = _('Аллерген')
        verbose_name_plural = _('Аллергены')

    def __str__(self):
        return self.alg_name


class M2MIngAlg(models.Model):
    """Связь между ингредиентом и аллергеном"""
    mia_alg_id = models.ForeignKey(
        'Allergen',
        on_delete=models.CASCADE,
        db_column='mia_alg_id',
        verbose_name=_('Аллерген')
    )
    mia_ing_id = models.ForeignKey(
        'Ingredient',
        on_delete=models.CASCADE,
        db_column='mia_ing_id',
        verbose_name=_('Ингредиент')
    )

    class Meta:
        db_table = 'm2m_ing_alg'
        unique_together = ('mia_alg_id', 'mia_ing_id')
        verbose_name = _('Связь ингредиент-аллерген')
        verbose_name_plural = _('Связи ингредиент-аллерген')


class M2MUsrAlg(models.Model):
    """Связь между пользователем и аллергеном"""
    mua_alg_id = models.ForeignKey(
        'Allergen',
        on_delete=models.CASCADE,
        db_column='mua_alg_id',
        related_name='user_allergies',
        verbose_name=_('Аллерген')
    )
    mua_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='mua_usr_id',
        related_name='user_allergens',
        verbose_name=_('Пользователь')
    )

    class Meta:
        db_table = 'm2m_usr_alg'
        unique_together = ('mua_alg_id', 'mua_usr_id')
        verbose_name = _('Аллергия пользователя')
        verbose_name_plural = _('Аллергии пользователей')