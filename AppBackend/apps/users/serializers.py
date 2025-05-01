from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework.authtoken.models import Token

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'usr_id', 'usr_mail', 'usr_name', 'password',
            'usr_height', 'usr_weight', 'usr_age',
            'usr_gender', 'usr_cal_day'
        ]
        read_only_fields = ['usr_id']

    def validate_usr_mail(self, value):
        """Валидация email на уникальность"""
        if User.objects.filter(usr_mail=value).exists():
            raise serializers.ValidationError("Пользователь с таким email уже существует")
        return value

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = User(**validated_data)

        if password:
            user.set_password(password)

        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if password:
            instance.set_password(password)

        instance.save()
        return instance


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'usr_name', 'usr_mail', 'usr_height', 'usr_weight',
            'usr_age', 'usr_gender', 'usr_cal_day'
        ]
        read_only_fields = ['usr_mail']


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate_password(self, value):
        try:
            validate_password(value)
        except serializers.ValidationError as error:
            raise serializers.ValidationError(error.messages)
        return value