
from rest_framework import serializers
from ..models import Allergen, M2MUsrAlg


class AllergenSerializer(serializers.ModelSerializer):
    """Сериализатор для аллергенов"""

    class Meta:
        model = Allergen
        fields = ['alg_id', 'alg_name']


class UserAllergenSerializer(serializers.ModelSerializer):
    """Сериализатор для аллергенов пользователя"""
    allergen = AllergenSerializer(source='mua_alg_id', read_only=True)

    class Meta:
        model = M2MUsrAlg
        fields = ['allergen']

    def to_representation(self, instance):
        
        representation = super().to_representation(instance)
        return representation['allergen']