
from django.db import models
from django.utils.translation import gettext_lazy as _

class GenderChoices(models.TextChoices):
    """Перечисление для пола"""
    MALE = 'Male', _('Мужской')  
    FEMALE = 'Female', _('Женский')  

class QuantityTypeChoices(models.TextChoices):
    """Перечисление для типов количества"""
    GRAMS = 'grams', _('Граммы')
    MILLILITERS = 'milliliters', _('Миллилитры')
    LITERS = 'liters', _('Литры')
    PIECES = 'pieces', _('Штуки')
    TABLESPOONS = 'tablespoons', _('Столовые ложки')
    TEASPOONS = 'teaspoons', _('Чайные ложки')
    CUPS = 'cups', _('Стаканы')