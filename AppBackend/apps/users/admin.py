from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _

User = get_user_model()

class UserAdmin(BaseUserAdmin):
    list_display = ('usr_mail', 'usr_name', 'is_staff')
    list_filter = ('is_staff', 'is_superuser', 'is_active')
    fieldsets = (
        (None, {'fields': ('usr_mail', 'password')}),
        (_('Персональная информация'), {'fields': ('usr_name', 'usr_height', 'usr_weight', 'usr_age', 'usr_gender', 'usr_cal_day')}),
        (_('Права'), {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        (_('Важные даты'), {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('usr_mail', 'usr_name', 'password1', 'password2'),
        }),
    )
    search_fields = ('usr_mail', 'usr_name')
    ordering = ('usr_mail',)
    filter_horizontal = ('groups', 'user_permissions',)

admin.site.register(User, UserAdmin)