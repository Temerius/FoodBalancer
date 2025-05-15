
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from django.conf import settings

User = get_user_model()

class Equipment(models.Model):
    """Модель кухонного оборудования"""
    eqp_id = models.AutoField(primary_key=True)
    eqp_type = models.CharField(_('Тип'), max_length=50)
    eqp_power = models.IntegerField(_('Мощность (Вт)'), default=0)
    eqp_capacity = models.IntegerField(_('Вместимость (л)'), default=0)
    eqp_img_url = models.CharField(_('URL изображения'), max_length=256, null=True, blank=True)

    class Meta:
        db_table = 'equipment'
        verbose_name = _('Оборудование')
        verbose_name_plural = _('Оборудование')

    def __str__(self):
        return self.eqp_type


class M2MUsrEqp(models.Model):
    """Связь между пользователем и оборудованием"""
    mue_eqp_id = models.ForeignKey(
        'Equipment',
        on_delete=models.CASCADE,
        db_column='mue_eqp_id',
        related_name='user_equipment',
        verbose_name=_('Оборудование'),
        primary_key=True  
    )
    mue_usr_id = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        db_column='mue_usr_id',
        related_name='user_equipment',
        verbose_name=_('Пользователь'),
        primary_key=False  
    )

    class Meta:
        db_table = 'm2m_usr_eqp'
        unique_together = ('mue_eqp_id', 'mue_usr_id')  
        managed = True  

    def __str__(self):
        return f"User {self.mue_usr_id_id} - Equipment {self.mue_eqp_id_id}"


class M2MRcpEqp(models.Model):
    """Связь между рецептом и оборудованием"""
    mre_rcp_id = models.ForeignKey(
        'Recipe',
        on_delete=models.CASCADE,
        db_column='mre_rcp_id',
        related_name='recipe_equipment',
        verbose_name=_('Рецепт')
    )
    mre_eqp_id = models.ForeignKey(
        'Equipment',
        on_delete=models.CASCADE,
        db_column='mre_eqp_id',
        related_name='recipe_equipment',
        verbose_name=_('Оборудование')
    )

    class Meta:
        db_table = 'm2m_rcp_eqp'
        unique_together = ('mre_rcp_id', 'mre_eqp_id')
        verbose_name = _('Оборудование для рецепта')
        verbose_name_plural = _('Оборудование для рецептов')