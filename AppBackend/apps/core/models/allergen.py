# AppBackend/apps/core/models/allergen.py
from django.db import models
from django.contrib.auth import get_user_model
from django.conf import settings
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
    # Foreign keys with existing column names
    mua_usr_id = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='allergens',
        db_column='mua_usr_id',
        primary_key=True  # Part of composite primary key
    )

    mua_alg_id = models.ForeignKey(
        'Allergen',  # Make sure this points to your Allergen model
        on_delete=models.CASCADE,
        related_name='users',
        db_column='mua_alg_id',
        primary_key=False  # Not marked as primary key in Django
    )

    class Meta:
        db_table = 'm2m_usr_alg'  # Use the existing table name
        unique_together = ('mua_usr_id', 'mua_alg_id')  # This creates a composite primary key
        managed = True  # Let Django manage this model

    def __str__(self):
        return f"User {self.mua_usr_id_id} - Allergen {self.mua_alg_id_id}"