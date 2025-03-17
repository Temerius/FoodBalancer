INSERT INTO m2m_ing_alg (mia_ing_id, mia_alg_id) VALUES
-- Tree Nuts
((SELECT ing_id FROM ingredient WHERE ing_name = 'Nutmeg'), (SELECT alg_id FROM allergen WHERE alg_name = 'Tree Nut')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Cinnamon Stick'), (SELECT alg_id FROM allergen WHERE alg_name = 'Tree Nut')), -- Cross-contact in spice processing

-- Dairy
((SELECT ing_id FROM ingredient WHERE ing_name = 'Vanilla Bean'), (SELECT alg_id FROM allergen WHERE alg_name = 'Milk')), -- Some extracts contain dairy
((SELECT ing_id FROM ingredient WHERE ing_name = 'Sage'), (SELECT alg_id FROM allergen WHERE alg_name = 'Milk')), -- Dairy-based additives

-- Gluten
((SELECT ing_id FROM ingredient WHERE ing_name = 'Soybean'), (SELECT alg_id FROM allergen WHERE alg_name = 'Gluten')), -- Processed soy products
((SELECT ing_id FROM ingredient WHERE ing_name = 'Oregano'), (SELECT alg_id FROM allergen WHERE alg_name = 'Wheat')), -- Flour additives

-- Soy
((SELECT ing_id FROM ingredient WHERE ing_name = 'Green Beans'), (SELECT alg_id FROM allergen WHERE alg_name = 'Soy')), -- Cross-contact
((SELECT ing_id FROM ingredient WHERE ing_name = 'Smoked Paprika'), (SELECT alg_id FROM allergen WHERE alg_name = 'Soy')), -- Processing aids

-- Mustard
((SELECT ing_id FROM ingredient WHERE ing_name = 'Celery Stalk'), (SELECT alg_id FROM allergen WHERE alg_name = 'Mustard')), -- Shared equipment
((SELECT ing_id FROM ingredient WHERE ing_name = 'Cauliflower Rice'), (SELECT alg_id FROM allergen WHERE alg_name = 'Mustard')),

-- Sesame
((SELECT ing_id FROM ingredient WHERE ing_name = 'Ground Turmeric'), (SELECT alg_id FROM allergen WHERE alg_name = 'Sesame')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Coriander'), (SELECT alg_id FROM allergen WHERE alg_name = 'Sesame')),

-- Fish
((SELECT ing_id FROM ingredient WHERE ing_name = 'Organic Maple Syrup'), (SELECT alg_id FROM allergen WHERE alg_name = 'Fish')), -- Fish gelatin filtering
((SELECT ing_id FROM ingredient WHERE ing_name = 'Raw Honey'), (SELECT alg_id FROM allergen WHERE alg_name = 'Shellfish')), -- Processing

-- Peanuts
((SELECT ing_id FROM ingredient WHERE ing_name = 'Sweet Corn'), (SELECT alg_id FROM allergen WHERE alg_name = 'Peanut')), -- Field rotation
((SELECT ing_id FROM ingredient WHERE ing_name = 'Butternut Squash'), (SELECT alg_id FROM allergen WHERE alg_name = 'Peanut')),

-- Lupin
((SELECT ing_id FROM ingredient WHERE ing_name = 'Italian Zucchini'), (SELECT alg_id FROM allergen WHERE alg_name = 'Lupin')), -- Flour substitutes

-- Celery
((SELECT ing_id FROM ingredient WHERE ing_name = 'Leek'), (SELECT alg_id FROM allergen WHERE alg_name = 'Celery')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Florence Fennel'), (SELECT alg_id FROM allergen WHERE alg_name = 'Celery')),

-- Cross-Contamination Examples
((SELECT ing_id FROM ingredient WHERE ing_name = 'Shiitake Mushroom'), (SELECT alg_id FROM allergen WHERE alg_name = 'Tree Nut')), -- Processing facilities
((SELECT ing_id FROM ingredient WHERE ing_name = 'Curly Kale'), (SELECT alg_id FROM allergen WHERE alg_name = 'Sesame')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Daikon Radish'), (SELECT alg_id FROM allergen WHERE alg_name = 'Mustard')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Savoy Cabbage'), (SELECT alg_id FROM allergen WHERE alg_name = 'Gluten')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Serrano Chili Pepper'), (SELECT alg_id FROM allergen WHERE alg_name = 'Peanut')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Japanese Sweet Potato'), (SELECT alg_id FROM allergen WHERE alg_name = 'Soy')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Chioggia Beet'), (SELECT alg_id FROM allergen WHERE alg_name = 'Celery')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Globe Artichoke'), (SELECT alg_id FROM allergen WHERE alg_name = 'Milk')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Thin Asparagus'), (SELECT alg_id FROM allergen WHERE alg_name = 'Egg')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Hass Avocado'), (SELECT alg_id FROM allergen WHERE alg_name = 'Latex')), -- Latex-food syndrome
((SELECT ing_id FROM ingredient WHERE ing_name = 'Baby Spinach'), (SELECT alg_id FROM allergen WHERE alg_name = 'Fish')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Romaine Lettuce'), (SELECT alg_id FROM allergen WHERE alg_name = 'Shellfish')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Yukon Gold Potato'), (SELECT alg_id FROM allergen WHERE alg_name = 'Corn')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Roma Tomato'), (SELECT alg_id FROM allergen WHERE alg_name = 'Grass')), -- Pollen-related
((SELECT ing_id FROM ingredient WHERE ing_name = 'Italian Parsley'), (SELECT alg_id FROM allergen WHERE alg_name = 'Mugwort')), -- Oral allergy
((SELECT ing_id FROM ingredient WHERE ing_name = 'Sweet Basil'), (SELECT alg_id FROM allergen WHERE alg_name = 'Ragweed')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Dill'), (SELECT alg_id FROM allergen WHERE alg_name = 'Birch Pollen')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Fresh Rosemary'), (SELECT alg_id FROM allergen WHERE alg_name = 'Salicylates')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Chives'), (SELECT alg_id FROM allergen WHERE alg_name = 'Onion')), -- Allium family
((SELECT ing_id FROM ingredient WHERE ing_name = 'Whole Clove'), (SELECT alg_id FROM allergen WHERE alg_name = 'Tree Nut')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Fresh Ginger'), (SELECT alg_id FROM allergen WHERE alg_name = 'Cardamom')), -- Cross-reactivity
((SELECT ing_id FROM ingredient WHERE ing_name = 'Cilantro'), (SELECT alg_id FROM allergen WHERE alg_name = 'Coriander')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Spearmint'), (SELECT alg_id FROM allergen WHERE alg_name = 'Peppermint')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Green Peas'), (SELECT alg_id FROM allergen WHERE alg_name = 'Pea')), -- Direct match
((SELECT ing_id FROM ingredient WHERE ing_name = 'Sugar Pumpkin'), (SELECT alg_id FROM allergen WHERE alg_name = 'Squash')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Red Bell Pepper'), (SELECT alg_id FROM allergen WHERE alg_name = 'Nightshade')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Broccoli Florets'), (SELECT alg_id FROM allergen WHERE alg_name = 'Cruciferous')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Carrot'), (SELECT alg_id FROM allergen WHERE alg_name = 'Birch Pollen')), -- Oral allergy
((SELECT ing_id FROM ingredient WHERE ing_name = 'Yellow Onion'), (SELECT alg_id FROM allergen WHERE alg_name = 'Allium')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'California Garlic'), (SELECT alg_id FROM allergen WHERE alg_name = 'Allium')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'English Cucumber'), (SELECT alg_id FROM allergen WHERE alg_name = 'Ragweed')),
((SELECT ing_id FROM ingredient WHERE ing_name = 'Japanese Eggplant'), (SELECT alg_id FROM allergen WHERE alg_name = 'Nightshade'));