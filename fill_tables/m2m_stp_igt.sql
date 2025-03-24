-- Шаг 1 (stp_id=1)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(56, 150, 'grams', 1),   -- Bacon (панчетта)
(47, 100, 'grams', 1),   -- Cheese (пекорино романо)
(46, 3, 'pieces', 1);    -- Egg (яичные желтки + целое яйцо)

-- Шаг 2 (stp_id=2)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(56, 150, 'grams', 2);   -- Bacon

-- Шаг 3 (stp_id=3)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(42, 400, 'grams', 3);   -- Pasta (спагетти)

-- Шаг 1 (stp_id=4)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(44, 200, 'grams', 4),   -- Lentils (чечевица)
(10, 1, 'pieces', 4),    -- Onion (лук)
(34, 2, 'pieces', 4);    -- Garlic (чеснок)

-- Шаг 2 (stp_id=5)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(37, 2, 'tablespoons', 5), -- Coconut Oil
(35, 1, 'teaspoons', 5),   -- Turmeric (куркума)
(38, 1, 'teaspoons', 5);   -- Paprika (кумин)

-- Шаг 3 (stp_id=6)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(43, 400, 'milliliters', 6), -- Coconut Milk
(48, 200, 'milliliters', 6); -- Broth

-- Шаг 1 (stp_id=7)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(46, 2, 'pieces', 7),    -- Egg
(41, 150, 'grams', 7),   -- Flour
(40, 150, 'milliliters', 7); -- Milk

-- Шаг 2 (stp_id=8)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(37, 50, 'milliliters', 8); -- Coconut Oil (для жарки)

-- Шаг 1 (stp_id=9)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(2, 3, 'pieces', 9),     -- Tomato
(3, 1, 'pieces', 9),     -- Cucumber
(10, 1, 'pieces', 9);    -- Onion

-- Шаг 2 (stp_id=10)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(36, 4, 'tablespoons', 10), -- Olive Oil
(50, 1, 'pieces', 10);      -- Lemon

-- Шаг 1 (stp_id=11)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(45, 500, 'grams', 11),  -- Beef
(10, 1, 'pieces', 11),   -- Onion
(34, 2, 'pieces', 11);   -- Garlic

-- Шаг 2 (stp_id=12)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(2, 400, 'grams', 12),   -- Tomato
(52, 1, 'cans', 12);     -- Beans

-- Шаг 1 (stp_id=13)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(46, 4, 'pieces', 13),    -- Egg (желтки)
(47, 500, 'grams', 13),   -- Cheese (маскарпоне)
(43, 200, 'milliliters', 13); -- Cream

-- Шаг 2 (stp_id=14)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(42, 200, 'grams', 14),   -- Pasta (савоярди)
(51, 100, 'milliliters', 14); -- Coffee

-- Шаг 1 (stp_id=15)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(45, 400, 'grams', 15),   -- Chicken
(54, 2, 'tablespoons', 15), -- Soy Sauce
(41, 1, 'teaspoons', 15);   -- Кукурузный крахмал (нет в списке, пропустить)

-- Шаг 2 (stp_id=16)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(4, 200, 'grams', 16),    -- Broccoli
(7, 1, 'pieces', 16);     -- Bell Pepper

-- Шаг 1 (stp_id=17)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(1, 1, 'pieces', 17),     -- Carrot
(10, 1, 'pieces', 17),    -- Onion
(28, 2, 'pieces', 17);    -- Celery

-- Шаг 2 (stp_id=18)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(6, 2, 'pieces', 18),     -- Potato
(23, 200, 'grams', 18);   -- Green Beans

-- Шаг 1 (stp_id=19)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(41, 500, 'grams', 19),   -- Flour
(29, 7, 'grams', 19);     -- Yeast (дрожжи)

-- Шаг 2 (stp_id=20)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(47, 200, 'grams', 20),   -- Cheese (моцарелла)
(31, 100, 'grams', 20);   -- Pepperoni

-- Шаг 1 (stp_id=21)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(49, 200, 'grams', 21);   -- Chocolate

-- Шаг 2 (stp_id=22)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(46, 4, 'pieces', 22);    -- Egg (белки)

-- Шаг 1 (stp_id=23)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(54, 4, 'tablespoons', 23), -- Soy Sauce
(33, 1, 'tablespoons', 23); -- Ginger

-- Шаг 2 (stp_id=24)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(45, 2, 'pieces', 24);    -- Fish (лосось)

-- Шаг 1 (stp_id=25)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(13, 1, 'pieces', 25),    -- Eggplant
(8, 2, 'pieces', 25);     -- Zucchini

-- Шаг 2 (stp_id=26)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, mmi_stp_id) 
VALUES
(2, 2, 'pieces', 26);     -- Tomato

-- Шаг 1 (stp_id=27)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(40, 200, 'grams', 27);   -- Bread (багет)

-- Шаг 2 (stp_id=28)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(46, 1, 'pieces', 28),    -- Egg (желток)
(36, 50, 'milliliters', 28); -- Olive Oil

-- Шаг 1 (stp_id=29)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(45, 800, 'grams', 29),   -- Beef
(56, 200, 'grams', 29);   -- Bacon

-- Шаг 2 (stp_id=30)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(53, 500, 'milliliters', 30); -- Wine

-- Шаг 1 (stp_id=31)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(1, 6, 'pieces', 31),     -- Apple
(17, 100, 'grams', 31);   -- Sugar

-- Шаг 2 (stp_id=32)
INSERT INTO m2m_stp_igt (msi_igt_id, msi_quantity, msi_quantity_type, msi_stp_id) 
VALUES
(41, 300, 'grams', 32);   -- Flour (для теста)