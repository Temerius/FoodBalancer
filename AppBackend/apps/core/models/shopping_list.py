# AppBackend/apps/core/models/shopping_list.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from ..enums import QuantityTypeChoices

User = get_user_model()

class ShoppingList(models.Model):
    """Модель списка покупок"""
    spl_id = models.AutoField(primary_key=True)
    spl_usr_id = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        db_column='spl_usr_id',
        related_name='shopping_list',
        verbose_name=_('Пользователь')
    )

    class Meta:
        db_table = 'shopping_list'
        verbose_name = _('Список покупок')
        verbose_name_plural = _('Списки покупок')

    def __str__(self):
        return f"Список покупок пользователя {self.spl_usr_id}"


class M2MIngSpl(models.Model):
    """Связь между типом ингредиента и списком покупок"""
    mis_id = models.AutoField(primary_key=True)
    mis_quantity = models.IntegerField(_('Количество'), default=0)
    mis_spl_id = models.ForeignKey(
        'ShoppingList',
        on_delete=models.CASCADE,
        db_column='mis_spl_id',
        related_name='items',
        verbose_name=_('Список покупок')
    )
    mis_igt_id = models.ForeignKey(
        'IngredientType',
        on_delete=models.CASCADE,
        db_column='mis_igt_id',
        related_name='shopping_list_items',
        verbose_name=_('Тип ингредиента')
    )
    mis_quantity_type = models.CharField(
        _('Единица измерения'),
        max_length=20,
        choices=QuantityTypeChoices.choices,
        default=QuantityTypeChoices.GRAMS
    )
    # Removed the is_checked field that doesn't exist in the database

    class Meta:
        db_table = 'm2m_ing_spl'
        verbose_name = _('Элемент списка покупок')
        verbose_name_plural = _('Элементы списка покупок')

    def __str__(self):
        return f"{self.mis_igt_id} ({self.mis_quantity} {self.mis_quantity_type})"