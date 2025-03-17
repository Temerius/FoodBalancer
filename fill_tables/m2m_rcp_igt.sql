INSERT INTO m2m_rcp_igt (mri_rcp_id, mri_igt_id) VALUES
-- Spaghetti Carbonara (1)
(1, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pasta')),
(1, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pork')),
(1, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),
(1, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),

-- Lentil Curry (2)
(2, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lentils')),
(2, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Coconut Oil')),
(2, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Onion')),
(2, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Garlic')),

-- Banana Pancakes (3)
(3, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Flour')),
(3, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Milk')),
(3, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),
(3, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Maple Syrup')),

-- Greek Salad (4)
(4, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(4, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cucumber')),
(4, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Olive Oil')),
(4, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),

-- Beef Chili (5)
(5, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(5, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beans')),
(5, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chili Pepper')),
(5, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),

-- Tiramisu (6)
(6, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Coffee')),
(6, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),
(6, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(6, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chocolate')),

-- Chicken Stir-Fry (7)
(7, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(7, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),
(7, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Soy Sauce')),
(7, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Garlic')),

-- Vegetable Soup (8)
(8, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Carrot')),
(8, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Celery')),
(8, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Onion')),
(8, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Broth')),

-- Homemade Pizza (9)
(9, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Flour')),
(9, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(9, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(9, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Basil')),

-- Chocolate Mousse (10)
(10, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chocolate')),
(10, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cream')),
(10, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),

-- Salmon Teriyaki (11)
(11, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Fish')),
(11, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Soy Sauce')),
(11, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Ginger')),
(11, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),

-- Ratatouille (12)
(12, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Eggplant')),
(12, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Zucchini')),
(12, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(12, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Basil')),

-- Caesar Salad (13)
(13, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lettuce')),
(13, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(13, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Bread')),
(13, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),

-- Beef Bourguignon (14)
(14, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(14, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Wine')),
(14, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Mushroom')),
(14, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Onion')),

-- Apple Pie (15)
(15, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Flour')),
(15, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Apple')),
(15, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cinnamon')),
(15, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Butter')),

(16, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Shrimp')),
(16, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Garlic')),
(16, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lemon')),
(16, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pasta')),

-- Caprese Salad (17)
(17, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(17, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(17, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Basil')),

-- Chicken Curry (18)
(18, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(18, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Coconut Milk')),
(18, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Turmeric')),

-- Guacamole (19)
(19, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Avocado')),
(19, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lime')),
(19, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chili Pepper')),

-- Beef Tacos (20)
(20, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(20, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tortilla')),
(20, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),

-- French Onion Soup (21)
(21, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Onion')),
(21, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Bread')),
(21, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Broth')),

-- Cheesecake (22)
(22, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(22, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Butter')),
(22, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cream')),

-- Pad Thai (23)
(23, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),
(23, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tofu')),
(23, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Peanuts')),

-- Mushroom Risotto (24)
(24, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Mushroom')),
(24, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),
(24, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Wine')),

-- Baked Salmon (25)
(25, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Fish')),
(25, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lemon')),
(25, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Dill')),

-- Chicken Noodle Soup (26)
(26, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(26, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pasta')),
(26, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Carrot')),

-- Vegetable Lasagna (27)
(27, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pasta')),
(27, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(27, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Zucchini')),

-- Pesto Pasta (28)
(28, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pasta')),
(28, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Basil')),
(28, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Nuts')),

-- Beef Bulgogi (29)
(29, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(29, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Soy Sauce')),
(29, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Ginger')),

-- Greek Yogurt Parfait (30)
(30, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Yogurt')),
(30, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Nuts')),
(30, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Honey')),

-- Chicken Parmesan (31)
(31, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(31, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(31, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),

-- Hummus (32)
(32, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chickpeas')),
(32, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tahini')),
(32, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lemon')),

-- Pulled Pork Sandwich (33)
(33, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Pork')),
(33, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Bread')),
(33, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'BBQ Sauce')),

-- Falafel (34)
(34, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chickpeas')),
(34, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Parsley')),
(34, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cumin')),

-- Omelette (35)
(35, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),
(35, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cheese')),
(35, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Mushroom')),

-- Chicken Satay (36)
(36, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(36, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Peanut Butter')),
(36, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Soy Sauce')),

-- Gazpacho (37)
(37, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Tomato')),
(37, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cucumber')),
(37, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Bell Pepper')),

-- Beef Stroganoff (38)
(38, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(38, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Mushroom')),
(38, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Sour Cream')),

-- Panna Cotta (39)
(39, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cream')),
(39, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Vanilla')),
(39, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Gelatin')),

-- Fish Tacos (40)
(40, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Fish')),
(40, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cabbage')),
(40, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lime')),

-- Moussaka (41)
(41, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Eggplant')),
(41, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lamb')),
(41, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cinnamon')),

-- Pho (42)
(42, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(42, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice Noodles')),
(42, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Ginger')),

-- Paella (43)
(43, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),
(43, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Shrimp')),
(43, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Saffron')),

-- Creme Brulee (44)
(44, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cream')),
(44, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Vanilla')),
(44, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Egg')),

-- Lobster Bisque (45)
(45, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Lobster')),
(45, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Cream')),
(45, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Brandy')),

-- Duck Confit (46)
(46, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Duck')),
(46, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Potato')),
(46, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Thyme')),

-- Baklava (47)
(47, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Phyllo Dough')),
(47, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Nuts')),
(47, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Honey')),

-- Chicken Tikka Masala (48)
(48, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Chicken')),
(48, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Yogurt')),
(48, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Garam Masala')),

-- Goulash (49)
(49, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Beef')),
(49, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Paprika')),
(49, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Onion')),

-- Sushi Rolls (50)
(50, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Rice')),
(50, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Fish')),
(50, (SELECT igt_id FROM ingredient_type WHERE igt_name = 'Nori'));