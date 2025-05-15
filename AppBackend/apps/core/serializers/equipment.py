
from rest_framework import serializers
from ..models import Equipment, M2MUsrEqp


class EquipmentSerializer(serializers.ModelSerializer):
    """Сериализатор для оборудования"""

    class Meta:
        model = Equipment
        fields = ['eqp_id', 'eqp_type', 'eqp_power', 'eqp_capacity', 'eqp_img_url']


class UserEquipmentSerializer(serializers.ModelSerializer):
    """Сериализатор для оборудования пользователя"""
    equipment = EquipmentSerializer(source='mue_eqp_id', read_only=True)

    class Meta:
        model = M2MUsrEqp
        fields = ['equipment']

    def to_representation(self, instance):
        
        representation = super().to_representation(instance)
        return representation['equipment']