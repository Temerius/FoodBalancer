# AppBackend/apps/core/models/ingredient.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from ..enums import QuantityTypeChoices

User = get_user_model()

class IngredientType(models.Model):
    """Модель типа ингредиента"""
    igt_id = models.AutoField(primary_key=True)
    igt_name = models.CharField(_('Название'), max_length=150)
    igt_img_url = models.CharField(_('URL изображения'), max_length=256, null=True, blank=True)

    class Meta:
        db_table = 'ingredient_type'
        verbose_name = _('Тип ингредиента')
        verbose_name_plural = _('Типы ингредиентов')

    def __str__(self):
        return self.igt_name


class Ingredient(models.Model):
    """Модель ингредиента"""
    ing_id = models.AutoField(primary_key=True)
    ing_name = models.CharField(_('Название'), max_length=100)
    ing_exp_date = models.DateField(_('Срок годности'), null=True, blank=True)
    ing_weight = models.IntegerField(_('Вес (г)'), default=0)
    ing_calories = models.IntegerField(_('Калорийность (ккал)'), default=0)
    ing_protein = models.SmallIntegerField(_('Белки (г)'), default=0)
    ing_fat = models.SmallIntegerField(_('Жиры (г)'), default=0)
    ing_hydrates = models.SmallIntegerField(_('Углеводы (г)'), default=0)
    ing_igt_id = models.ForeignKey(
        'IngredientType',
        on_delete=models.CASCADE,
        db_column='ing_igt_id',
        related_name='ingredients',
        verbose_name=_('Тип ингредиента')
    )
    ing_img_url = models.CharField(_('URL изображения'), max_length=256, null=True, blank=True)

    class Meta:
        db_table = 'ingredient'
        verbose_name = _('Ингредиент')
        verbose_name_plural = _('Ингредиенты')

    def __str__(self):
        return self.ing_name


class M2MUsrIng(models.Model):
    """Связь между пользователем и ингредиентом (холодильник)"""
    mui_id = models.BigAutoField(primary_key=True)
    mui_quantity = models.IntegerField(_('Количество'), default=0)
    mui_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='mui_usr_id',
        related_name='refrigerator_items',
        verbose_name=_('Пользователь')
    )
    mui_ing_id = models.ForeignKey(
        'Ingredient',
        on_delete=models.CASCADE,
        db_column='mui_ing_id',
        related_name='user_items',
        verbose_name=_('Ингредиент')
    )
    mui_quantity_type = models.CharField(
        _('Единица измерения'),
        max_length=20,
        choices=QuantityTypeChoices.choices,
        default=QuantityTypeChoices.GRAMS
    )

    class Meta:
        db_table = 'm2m_usr_ing'
        verbose_name = _('Ингредиент пользователя')
        verbose_name_plural = _('Ингредиенты пользователей')