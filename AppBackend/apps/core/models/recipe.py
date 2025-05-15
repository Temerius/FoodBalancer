
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from ..enums import QuantityTypeChoices

User = get_user_model()

class Recipe(models.Model):
    """Модель рецепта"""
    rcp_id = models.AutoField(primary_key=True)
    rcp_title = models.CharField(_('Название'), max_length=300)
    rcp_description = models.TextField(_('Описание'), blank=True)
    rcp_cal = models.IntegerField(_('Калорийность'), default=0)
    rcp_portion_count = models.SmallIntegerField(_('Количество порций'), default=1)
    rcp_main_img = models.CharField(_('Основное изображение'), max_length=256, blank=True, null=True)

    
    rcp_weight = models.IntegerField(_('Вес порции (г)'), default=0)
    rcp_fat = models.IntegerField(_('Жиры (г)'), default=0)
    rcp_hydrates = models.IntegerField(_('Углеводы (г)'), default=0)
    rcp_protein = models.IntegerField(_('Белки (г)'), default=0)

    class Meta:
        db_table = 'recipe'
        verbose_name = _('Рецепт')
        verbose_name_plural = _('Рецепты')

    def __str__(self):
        return self.rcp_title


class Step(models.Model):
    """Модель шага рецепта"""
    stp_id = models.BigAutoField(primary_key=True)
    stp_title = models.CharField(_('Заголовок'), max_length=100)
    stp_instruction = models.TextField(_('Инструкция'))
    stp_rcp_id = models.ForeignKey(
        'Recipe',
        on_delete=models.CASCADE,
        db_column='stp_rcp_id',
        related_name='steps',
        verbose_name=_('Рецепт')
    )

    class Meta:
        db_table = 'step'
        verbose_name = _('Шаг рецепта')
        verbose_name_plural = _('Шаги рецепта')
        ordering = ['stp_id']  

    def __str__(self):
        return f"{self.stp_title} ({self.stp_rcp_id})"


class Image(models.Model):
    """Модель изображения для шага рецепта"""
    img_id = models.BigAutoField(primary_key=True)
    img_url = models.CharField(_('URL изображения'), max_length=256)
    img_stp_id = models.ForeignKey(
        'Step',
        on_delete=models.CASCADE,
        db_column='img_stp_id',
        related_name='images',
        verbose_name=_('Шаг рецепта')
    )

    class Meta:
        db_table = 'image'
        verbose_name = _('Изображение')
        verbose_name_plural = _('Изображения')

    def __str__(self):
        return f"Изображение для {self.img_stp_id}"


class M2MStpIgt(models.Model):
    """Связь между шагом рецепта и типом ингредиента"""
    msi_id = models.AutoField(primary_key=True)
    msi_igt_id = models.ForeignKey(
        'IngredientType',
        on_delete=models.CASCADE,
        db_column='msi_igt_id',
        related_name='steps',
        verbose_name=_('Тип ингредиента')
    )
    msi_quantity = models.IntegerField(_('Количество'), default=0)
    msi_quantity_type = models.CharField(
        _('Единица измерения'),
        max_length=20,
        choices=QuantityTypeChoices.choices,
        default=QuantityTypeChoices.GRAMS
    )
    msi_stp_id = models.ForeignKey(
        'Step',
        on_delete=models.CASCADE,
        db_column='msi_stp_id',
        related_name='ingredient_types',
        verbose_name=_('Шаг рецепта')
    )

    class Meta:
        db_table = 'm2m_stp_igt'
        verbose_name = _('Ингредиент шага')
        verbose_name_plural = _('Ингредиенты шагов')


class FavoriteRecipe(models.Model):
    """Модель избранных рецептов"""
    fvr_id = models.AutoField(primary_key=True)
    fvr_rcp_id = models.ForeignKey(
        'Recipe',
        on_delete=models.CASCADE,
        db_column='fvr_rcp_id',
        related_name='favorited_by',
        verbose_name=_('Рецепт')
    )
    fvr_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='fvr_usr_id',
        related_name='favorite_recipes',
        verbose_name=_('Пользователь')
    )

    class Meta:
        db_table = 'favorite_recipe'
        unique_together = ('fvr_rcp_id', 'fvr_usr_id')
        verbose_name = _('Избранный рецепт')
        verbose_name_plural = _('Избранные рецепты')