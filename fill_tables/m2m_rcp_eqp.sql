INSERT INTO m2m_rcp_eqp (mre_rcp_id, mre_eqp_id) VALUES
-- Spaghetti Carbonara (1)
(1, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Gas Stove')),
(1, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pot')),

-- Lentil Curry (2)
(2, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Multicooker')),
(2, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Immersion Blender')),

-- Banana Pancakes (3)
(3, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Electric Skillet')),
(3, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Hand Mixer')),

-- Greek Salad (4)
(4, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Vegetable Carving Tool')),

-- Beef Chili (5)
(5, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Dutch Oven')),
(5, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Wooden Spoon')),

-- Tiramisu (6)
(6, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Hand Mixer')),
(6, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Springform Pan')),

-- Chicken Stir-Fry (7)
(7, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Wok')),
(7, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Rice Cooker')),

-- Vegetable Soup (8)
(8, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Stock Pot')),
(8, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Ladle')),

-- Homemade Pizza (9)
(9, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pizza Oven')),
(9, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pizza Peel')),

-- Chocolate Mousse (10)
(10, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Double Boiler')),
(10, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Whisk')),

-- Salmon Teriyaki (11)
(11, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Grill Pan')),
(11, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Basting Brush')),

-- Ratatouille (12)
(12, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Casserole Dish')),
(12, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Mandoline Slicer')),

-- Caesar Salad (13)
(13, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Salad Spinner')),
(13, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Crouton Press')),

-- Beef Bourguignon (14)
(14, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Dutch Oven')),
(14, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Wine Opener')),

-- Apple Pie (15)
(15, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pie Dish')),
(15, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pastry Cutter')),

(16, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Gas Stove')),
(16, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Chef''s Knife')),
(16, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Zester')),

-- Caprese Salad (17)
(17, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Mandoline Slicer')),
(17, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Salad Bowl')),

-- Chicken Curry (18)
(18, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Dutch Oven')),
(18, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Spice Grinder')),

-- Guacamole (19)
(19, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Molcajete')),
(19, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Avocado Tool')),

-- Beef Tacos (20)
(20, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Cast Iron Skillet')),
(20, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Tortilla Press')),

-- French Onion Soup (21)
(21, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Soup Pot')),
(21, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Broiler Safe Bowls')),

-- Cheesecake (22)
(22, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Springform Pan')),
(22, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Water Bath Container')),

-- Pad Thai (23)
(23, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Carbon Steel Wok')),
(23, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Noodle Basket')),

-- Mushroom Risotto (24)
(24, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Risotto Pan')),
(24, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Ladle')),

-- Baked Salmon (25)
(25, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Roasting Rack')),
(25, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Fish Spatula')),

-- Vegetable Lasagna (26)
(26, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Lasagna Pan')),
(26, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Vegetable Mandoline')),

-- Pesto Pasta (27)
(27, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Food Processor')),
(27, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Herb Stripper')),

-- Beef Bulgogi (28)
(28, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Korean BBQ Grill')),
(28, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Meat Tenderizer')),

-- Greek Yogurt Parfait (29)
(29, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Parfait Glass')),
(29, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Berry Huller')),

-- Chicken Parmesan (30)
(30, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Meat Mallet')),
(30, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pasta Pot')),

-- Pulled Pork Sandwich (31)
(31, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Slow Cooker')),
(31, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Meat Claws')),

-- Falafel (32)
(32, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Falafel Scoop')),
(32, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Deep Fryer')),

-- Omelette (33)
(33, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Non-Stick Pan')),
(33, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Egg Whisk')),

-- Gazpacho (34)
(34, (SELECT eqp_id FROM equipment WHERE eqp_type = 'High-Speed Blender')),
(34, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Chinois')),

-- Beef Stroganoff (35)
(35, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Stroganoff Pan')),
(35, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Sour Cream Dispenser')),

-- Fish Tacos (36)
(36, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Fish Turner')),
(36, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Lime Squeezer')),

-- Moussaka (37)
(37, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Bechamel Whisk')),
(37, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Aubergine Slicer')),

-- Pho (38)
(38, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Pho Stockpot')),
(38, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Noodle Strainer')),

-- Paella (39)
(39, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Paella Pan')),
(39, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Socarrat Scraper')),

-- Creme Brulee (40)
(40, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Torch Kit')),
(40, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Ramekins')),

-- Lobster Bisque (41)
(41, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Lobster Crackers')),
(41, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Bisque Strainer')),

-- Duck Confit (42)
(42, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Confit Jar')),
(42, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Fat Skimmer')),

-- Baklava (43)
(43, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Phyllo Brush')),
(43, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Honey Drizzler')),

-- Chicken Tikka Masala (44)
(44, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Tandoor Oven')),
(44, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Masala Dabba')),

-- Goulash (45)
(45, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Goulash Pot')),
(45, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Paprika Mill')),

-- Sushi Rolls (46)
(46, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Sushi Mat')),
(46, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Rice Paddle')),

-- Borscht (47)
(47, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Borscht Pot')),
(47, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Beet Peeler')),

-- Tandoori Chicken (48)
(48, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Tandoor Oven')),
(48, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Marinade Injector')),

-- Croissants (49)
(49, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Laminating Roller')),
(49, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Proofing Box')),

-- Final Recipe (50)
(50, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Sous Vide Cooker')),
(50, (SELECT eqp_id FROM equipment WHERE eqp_type = 'Thermocouple'));