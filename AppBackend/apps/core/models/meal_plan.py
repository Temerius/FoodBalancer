
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from ..enums import QuantityTypeChoices

User = get_user_model()

class WeaklyMealPlan(models.Model):
    """Модель недельного плана питания"""
    wmp_id = models.AutoField(primary_key=True)
    wmp_start = models.DateField(_('Дата начала'))
    wmp_end = models.DateField(_('Дата окончания'))
    wmp_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='wmp_usr_id',
        related_name='weekly_meal_plans',
        verbose_name=_('Пользователь')
    )

    class Meta:
        db_table = 'weakly_meal_plan'
        verbose_name = _('Недельный план питания')
        verbose_name_plural = _('Недельные планы питания')

    def __str__(self):
        return f"План {self.wmp_id} для {self.wmp_usr_id} ({self.wmp_start} - {self.wmp_end})"


class DailyMealPlan(models.Model):
    """Модель дневного плана питания"""
    dmp_id = models.AutoField(primary_key=True)
    dmp_date = models.DateField(_('Дата'))
    dmp_cal_day = models.IntegerField(_('Дневная норма калорий'), default=0)
    dmp_wmp_id = models.ForeignKey(
        'WeaklyMealPlan',
        on_delete=models.CASCADE,
        db_column='dmp_wmp_id',
        related_name='daily_plans',
        verbose_name=_('Недельный план')
    )

    class Meta:
        db_table = 'daily_meal_plan'
        verbose_name = _('Дневной план питания')
        verbose_name_plural = _('Дневные планы питания')

    def __str__(self):
        return f"План на {self.dmp_date}"


class ActualDayMeal(models.Model):
    """Модель фактического приема пищи"""
    adm_id = models.AutoField(primary_key=True)
    adm_date = models.DateField(_('Дата'))
    adm_usr_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='adm_usr_id',
        related_name='actual_meals',
        verbose_name=_('Пользователь')
    )
    
    adm_type = models.CharField(_('Тип приема пищи'), max_length=50, null=True, blank=True)  
    adm_time = models.TimeField(_('Время'), null=True, blank=True)

    class Meta:
        db_table = 'actual_day_meal'
        verbose_name = _('Фактический прием пищи')
        verbose_name_plural = _('Фактические приемы пищи')

    def __str__(self):
        meal_type = f" ({self.adm_type})" if self.adm_type else ""
        return f"Прием пищи на {self.adm_date}{meal_type}"


class M2MRcpDmp(models.Model):
    """Связь между рецептом и дневным планом питания"""
    mrd_id = models.AutoField(primary_key=True)
    mrd_rcp_id = models.ForeignKey(
        'Recipe',
        on_delete=models.CASCADE,
        db_column='mrd_rcp_id',
        related_name='daily_meal_plans',
        verbose_name=_('Рецепт')
    )
    mrd_dmp_id = models.ForeignKey(
        'DailyMealPlan',
        on_delete=models.CASCADE,
        db_column='mrd_dmp_id',
        related_name='recipes',
        verbose_name=_('Дневной план')
    )

    class Meta:
        db_table = 'm2m_rcp_dmp'
        verbose_name = _('Рецепт в дневном плане')
        verbose_name_plural = _('Рецепты в дневных планах')


class M2MRcpAdm(models.Model):
    """Связь между рецептом и приемом пищи"""
    mra_adm_id = models.ForeignKey(
        'ActualDayMeal',
        on_delete=models.CASCADE,
        db_column='mra_adm_id',
        related_name='recipes',
        verbose_name=_('Прием пищи')
    )
    mra_rcp_id = models.ForeignKey(
        'Recipe',
        on_delete=models.CASCADE,
        db_column='mra_rcp_id',
        related_name='actual_meals',
        verbose_name=_('Рецепт')
    )

    class Meta:
        db_table = 'm2m_rcp_adm'
        unique_together = ('mra_adm_id', 'mra_rcp_id')
        verbose_name = _('Рецепт в приеме пищи')
        verbose_name_plural = _('Рецепты в приемах пищи')


class M2MIngDmp(models.Model):
    """Связь между ингредиентом и дневным планом питания"""
    mid_dmp_id = models.ForeignKey(
        'DailyMealPlan',
        on_delete=models.CASCADE,
        db_column='mid_dmp_id',
        related_name='ingredients',
        verbose_name=_('Дневной план')
    )
    mid_ing_id = models.ForeignKey(
        'Ingredient',
        on_delete=models.CASCADE,
        db_column='mid_ing_id',
        related_name='daily_plans',
        verbose_name=_('Ингредиент')
    )
    mid_quantity = models.IntegerField(_('Количество'), default=0)
    mid_quantity_type = models.CharField(
        _('Единица измерения'),
        max_length=20,
        choices=QuantityTypeChoices.choices,
        default=QuantityTypeChoices.GRAMS
    )

    class Meta:
        db_table = 'm2m_ing_dmp'
        unique_together = ('mid_dmp_id', 'mid_ing_id')
        verbose_name = _('Ингредиент в дневном плане')
        verbose_name_plural = _('Ингредиенты в дневных планах')


class M2MIngAdm(models.Model):
    """Связь между ингредиентом и приемом пищи"""
    mia_adm_id = models.ForeignKey(
        'ActualDayMeal',
        on_delete=models.CASCADE,
        db_column='mia_adm_id',
        related_name='ingredients',
        verbose_name=_('Прием пищи')
    )
    mia_ing_id = models.ForeignKey(
        'Ingredient',
        on_delete=models.CASCADE,
        db_column='mia_ing_id',
        related_name='actual_meals',
        verbose_name=_('Ингредиент')
    )
    mia_quantity = models.IntegerField(_('Количество'), default=0)
    mia_quantity_type = models.CharField(
        _('Единица измерения'),
        max_length=20,
        choices=QuantityTypeChoices.choices,
        default=QuantityTypeChoices.GRAMS
    )

    class Meta:
        db_table = 'm2m_ing_adm'
        unique_together = ('mia_adm_id', 'mia_ing_id')
        verbose_name = _('Ингредиент в приеме пищи')
        verbose_name_plural = _('Ингредиенты в приемах пищи')