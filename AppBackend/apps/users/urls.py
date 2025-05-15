
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import profile, login, logout, register, password_reset_request, password_reset_confirm

app_name = 'users'

urlpatterns = [
    path('register/', register, name='register'),
    path('login/', login, name='login'),
    path('profile/', profile, name='profile'),
    path('password-reset/', password_reset_request, name='password_reset_request'),
    path('password-reset/confirm/', password_reset_confirm, name='password_reset_confirm'),
    path('logout/', logout, name='logout')
]