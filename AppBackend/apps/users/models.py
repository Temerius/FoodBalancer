from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models
import hashlib
from apps.core.enums import GenderChoices

class UserManager(BaseUserManager):
    def create_user(self, usr_mail, password=None, **extra_fields):
        if not usr_mail:
            raise ValueError('Email обязателен')

        email = self.normalize_email(usr_mail)
        user = self.model(usr_mail=email, **extra_fields)

        if password:
            user.set_password(password)

        user.save(using=self._db)
        return user

    def create_superuser(self, usr_mail, usr_name=None, password=None, **extra_fields):
        """
        Создание суперпользователя - принимает параметры соответствующие REQUIRED_FIELDS
        """
        if not usr_name:
            usr_name = "Admin"  

        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(usr_mail=usr_mail, password=password, usr_name=usr_name, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    
    usr_id = models.BigAutoField(primary_key=True)
    usr_name = models.CharField(max_length=100, null=True, blank=True)
    usr_pas_hash = models.CharField(max_length=32, null=True, blank=True)
    usr_mail = models.EmailField(max_length=100, unique=True)
    usr_height = models.SmallIntegerField(null=True, blank=True)
    usr_weight = models.SmallIntegerField(null=True, blank=True)
    usr_age = models.SmallIntegerField(null=True, blank=True)

    usr_cal_day = models.IntegerField(null=True, blank=True)

    usr_gender = models.CharField(
        max_length=10,
        choices=GenderChoices.choices,
        null=True,
        blank=True
    )

    
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=False)
    last_login = models.DateTimeField(null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True, null=True)

    
    username = None

    objects = UserManager()

    USERNAME_FIELD = 'usr_mail'
    EMAIL_FIELD = 'usr_mail'
    REQUIRED_FIELDS = ['usr_name']

    class Meta:
        db_table = 'user'

    def __str__(self):
        return self.usr_mail

    def get_full_name(self):
        return self.usr_name or self.usr_mail

    def get_short_name(self):
        return self.usr_name or self.usr_mail

    def set_password(self, raw_password):
        
        if raw_password is not None:
            self.usr_pas_hash = hashlib.md5(raw_password.encode()).hexdigest()
        else:
            self.usr_pas_hash = None

        
        super().set_password(raw_password)