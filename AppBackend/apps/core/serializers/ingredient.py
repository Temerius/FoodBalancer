

from rest_framework import serializers
from ..models import IngredientType, Ingredient, M2MUsrIng, Allergen, IngredientToAllergen


class AllergenSerializer(serializers.ModelSerializer):
    """Сериализатор для аллергенов"""

    class Meta:
        model = Allergen
        fields = ['alg_id', 'alg_name']


class IngredientTypeSerializer(serializers.ModelSerializer):
    """Сериализатор для типов ингредиентов"""

    class Meta:
        model = IngredientType
        fields = ['igt_id', 'igt_name', 'igt_img_url']


class IngredientSerializer(serializers.ModelSerializer):
    """Базовый сериализатор для ингредиентов с поддержкой аллергенов"""
    ing_igt_id = serializers.PrimaryKeyRelatedField(queryset=IngredientType.objects.all())
    allergen_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        write_only=True
    )

    class Meta:
        model = Ingredient
        fields = [
            'ing_id', 'ing_name', 'ing_exp_date', 'ing_weight', 'ing_calories',
            'ing_protein', 'ing_fat', 'ing_hydrates', 'ing_igt_id', 'ing_img_url',
            'allergen_ids'
        ]

    def create(self, validated_data):
        print(f"Creating ingredient with data: {validated_data}")

        
        allergen_ids = validated_data.pop('allergen_ids', [])
        print(f"Allergen IDs to create: {allergen_ids}")

        
        ingredient = super().create(validated_data)
        print(f"Created ingredient: {ingredient.ing_id} - {ingredient.ing_name}")

        
        for allergen_id in allergen_ids:
            try:
                
                allergen = Allergen.objects.get(alg_id=allergen_id)

                
                if IngredientToAllergen.objects.filter(
                        mia_ing_id=ingredient,
                        mia_alg_id=allergen
                ).exists():
                    print(f"Allergen link already exists: {ingredient.ing_name} - {allergen.alg_name}")
                else:
                    
                    IngredientToAllergen.objects.create(
                        mia_ing_id=ingredient,
                        mia_alg_id=allergen
                    )
                    print(f"Created allergen link: {ingredient.ing_name} - {allergen.alg_name}")

            except Allergen.DoesNotExist:
                print(f"Allergen with ID {allergen_id} does not exist")
            except Exception as e:
                print(f"Error creating allergen link for ID {allergen_id}: {str(e)}")

        return ingredient

    def update(self, instance, validated_data):
        print(f"Updating ingredient {instance.ing_id} with data: {validated_data}")

        
        allergen_ids = validated_data.pop('allergen_ids', None)

        
        instance = super().update(instance, validated_data)

        
        if allergen_ids is not None:
            print(f"Updating allergens to: {allergen_ids}")

            
            IngredientToAllergen.objects.filter(mia_ing_id=instance).delete()
            print("Deleted old allergen links")

            
            for allergen_id in allergen_ids:
                try:
                    allergen = Allergen.objects.get(alg_id=allergen_id)
                    IngredientToAllergen.objects.create(
                        mia_ing_id=instance,
                        mia_alg_id=allergen
                    )
                    print(f"Created new allergen link: {instance.ing_name} - {allergen.alg_name}")
                except Allergen.DoesNotExist:
                    print(f"Allergen with ID {allergen_id} does not exist")
                except Exception as e:
                    print(f"Error creating allergen link: {str(e)}")

        return instance


class IngredientDetailSerializer(serializers.ModelSerializer):
    """Детальный сериализатор для ингредиентов с включением типа и аллергенов"""
    ing_igt_id = IngredientTypeSerializer(read_only=True)
    allergens = AllergenSerializer(many=True, read_only=True)

    class Meta:
        model = Ingredient
        fields = [
            'ing_id', 'ing_name', 'ing_exp_date', 'ing_weight', 'ing_calories',
            'ing_protein', 'ing_fat', 'ing_hydrates', 'ing_igt_id', 'ing_img_url',
            'allergens'
        ]


class UserIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов пользователя (холодильник)"""
    ingredient = IngredientDetailSerializer(source='mui_ing_id', read_only=True)

    
    mui_ing_id = serializers.SerializerMethodField()
    mui_usr_id = serializers.SerializerMethodField()

    class Meta:
        model = M2MUsrIng
        fields = ['mui_id', 'mui_usr_id', 'mui_ing_id', 'mui_quantity', 'mui_quantity_type', 'ingredient']
        read_only_fields = ['mui_usr_id']

    def get_mui_ing_id(self, obj):
        """Возвращает ID ингредиента как integer"""
        return obj.mui_ing_id.ing_id if obj.mui_ing_id else None

    def get_mui_usr_id(self, obj):
        """Возвращает ID пользователя как integer"""
        return obj.mui_usr_id.usr_id if obj.mui_usr_id else None

    def to_internal_value(self, data):
        """Преобразует входящие данные для создания/обновления"""
        
        ret = super().to_internal_value(data)
        if 'mui_ing_id' in data:
            ret['mui_ing_id'] = data['mui_ing_id']
        return ret