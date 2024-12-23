-- =========================================
-- Создание таблиц
-- =========================================

-- Таблица: Unit
create table Unit (
    id_unit serial primary key,
    short_name varchar(20),
    name varchar(50),
    code int unique
);

-- Таблица: Classification
create table Classification (
    id_class serial primary key,
    short_name varchar(50),
    name varchar (100),
    id_unit int references Unit(id_unit) on delete set null,
    id_main_class int references Classification(id_class) on delete restrict
);

-- Таблица: Product
create table Product (
    id_product serial primary key,
    short_name varchar(20),
    name varchar(50),
    id_class int references Classification(id_class) on delete cascade,
    id_unit int references Unit(id_unit) on delete set null,
    price numeric(13, 2),
    base_id_product int references Product(id_product) on delete cascade
);

-- Таблица: Spec_position
create table Spec_position (
    id_position serial primary key,
    id_product int references Product(id_product) ON DELETE CASCADE,
    id_part int references Product(id_product) ON DELETE CASCADE,
    quantity int
);

-- =========================================
-- Создание функций
-- =========================================

-- Функция: Добавление единицы измерения
CREATE OR REPLACE FUNCTION create_unit(short_name VARCHAR(20), name VARCHAR(50), code int)
RETURNS VOID AS $$
BEGIN
    INSERT INTO Unit (short_name, name, code) VALUES (short_name, name, code);
END;
$$ LANGUAGE plpgsql;

-- Функция: Удаление единицы измерения
CREATE OR REPLACE FUNCTION delete_unit(id_unit_delete int)
RETURNS VOID AS $$
DECLARE
    count int;
BEGIN
    count = 0;
    SELECT count(*) FROM classification as class WHERE class.id_unit = id_unit_delete INTO count;
    if count > 0 then
        RAISE EXCEPTION 'Невозможно удалить единицу измерения';
    else
        DELETE FROM unit WHERE unit.id_unit = id_unit_delete;
    end if;
END;
$$ LANGUAGE plpgsql;

-- Функция: Добавление продукта
CREATE OR REPLACE FUNCTION create_product(
    short_name VARCHAR(100),
    name VARCHAR(200),
    product_id_class int,
    product_id_unit int,
    price numeric(13, 2),
    base_id_product int
)
RETURNS VOID AS $$
DECLARE
    hasClass int;
BEGIN
    hasClass = 0;
    SELECT 1 FROM Classification AS class WHERE class.id_class = product_id_class INTO hasClass;
    if hasClass = 1 then
        if (product_id_unit is null) then
            SELECT id_unit FROM classification as class where class.id_class = product_id_class INTO product_id_unit;
        end if;
        INSERT INTO Product (short_name, name, id_class, id_unit, price, base_id_product)
        VALUES (short_name, name, product_id_class, product_id_unit, price, base_id_product);
    end if;
END;
$$ LANGUAGE plpgsql;

-- Функция: Удаление продукта
CREATE OR REPLACE FUNCTION delete_product(del_id_product int)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Product WHERE id_product = del_id_product;
END;
$$ LANGUAGE plpgsql;

-- Функция: Изменение класса продукта
CREATE OR REPLACE FUNCTION change_product_class(change_id_product int, new_id_class int)
RETURNS VOID AS $$
BEGIN
    IF (SELECT count(*) FROM find_children(new_id_class)) > 1 THEN
        RAISE EXCEPTION 'Продукт может относится только к терминальному классу';
    end if;
    UPDATE Product SET id_class = new_id_class WHERE id_product = change_id_product;
END;
$$ LANGUAGE plpgsql;

-- Функция: Найти продукты, принадлежащие классу классификатора
CREATE OR REPLACE FUNCTION find_products(from_id_class int[])
RETURNS TABLE (class_id int, class_short_name varchar(50), id int, p_short_name varchar(20)) AS $$
BEGIN
    RETURN QUERY (
    WITH RECURSIVE children as (
        SELECT id_class, id_main_class, short_name FROM classification
        WHERE id_class = any(from_id_class)
        UNION
        SELECT c.id_class, c.id_main_class, c.short_name FROM classification c
        INNER JOIN children ch on c.id_main_class = ch.id_class
    ) SELECT ch.id_class, ch.short_name, p.id_product, p.short_name
      FROM Product p INNER JOIN children ch on ch.id_class = p.id_class);
END;
$$ LANGUAGE plpgsql;

-- Функция: Создание класса
CREATE OR REPLACE FUNCTION create_class(
    class_short_name varchar(50),
    class_name varchar (100),
    class_id_unit int,
    class_id_main_class int)
RETURNS VOID AS $$
BEGIN
    if class_id_main_class is null and (SELECT count(1) FROM classification) > 0 then
        RAISE EXCEPTION 'В классификаторе есть только одна корневая вершина';
    end if;
    IF (SELECT count(*) FROM classification WHERE short_name = class_short_name) > 0 THEN
        RAISE EXCEPTION 'В классификации уже есть класс с таким обозначением';
    end if;
    IF (class_id_unit is null) THEN
        SELECT id_unit FROM classification WHERE id_class = class_id_main_class INTO class_id_unit;
    end if;
    IF (SELECT count(*) FROM unit WHERE id_unit = class_id_unit) = 0 THEN
        RAISE EXCEPTION 'Выбрана несуществующая единица измерения';
    end if;
    INSERT INTO classification (short_name, name, id_unit, id_main_class)
        VALUES (class_short_name, class_name, class_id_unit, class_id_main_class);
END;
$$ LANGUAGE plpgsql;

-- Функция: Удаление класса
CREATE OR REPLACE FUNCTION delete_class(del_id_class int)
RETURNS VOID AS $$
BEGIN
    if (SELECT count(*) from classification WHERE id_main_class = del_id_class) > 0 then
        RAISE exception 'Нельзя удалить класс, у которого есть потомки';
    end if;
    DELETE FROM classification WHERE id_class = del_id_class;
END;
$$ LANGUAGE plpgsql;

-- Функция: Проверка на цикл
CREATE OR REPLACE FUNCTION cycle(from_id int, to_id int)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        SELECT EXISTS(WITH RECURSIVE
            parents AS (
            SELECT id_class, id_main_class
                FROM classification
                WHERE ID_CLASS = to_id

            UNION

            SELECT C.id_class,
                C.id_main_class
                FROM classification C
                INNER JOIN parents s ON
                s.id_main_class = C.id_class
    )
    SELECT * FROM parents WHERE id_class = from_id));
END;
$$ LANGUAGE plpgsql;

-- Функция: Изменить родителя класса
CREATE OR REPLACE FUNCTION change_parent_class(child_id_class int, new_parent_id_class int)
RETURNS VOID AS $$
DECLARE
    hasCycle boolean;
BEGIN
    hasCycle = cycle(child_id_class, new_parent_id_class);
    if hasCycle then
        RAISE EXCEPTION 'Нельзя поменять родителя, потому что создается цикл';
    else
        UPDATE classification SET id_main_class = new_parent_id_class WHERE ID_CLASS = child_id_class;
    end if;
END;
$$ LANGUAGE plpgsql;

-- Функция: Найти потомков класса
CREATE OR REPLACE FUNCTION find_children(find_id_class int)
RETURNS TABLE (class_id int, child_name varchar(50)) AS $$
BEGIN
    RETURN QUERY (
    WITH RECURSIVE children as (
        SELECT id_class, short_name, id_main_class FROM classification
        WHERE id_class = find_id_class

        UNION

        SELECT c.id_class, c.short_name, c.id_main_class FROM classification c
        INNER JOIN children ch on c.id_main_class = ch.id_class
    ) select ch.id_class, ch.short_name from children ch);
END;
$$ LANGUAGE plpgsql;

-- Функция: Найти родителей класса
CREATE OR REPLACE FUNCTION find_parents(find_id_class int)
RETURNS TABLE (class_id int, parent_name varchar(20)) AS $$
BEGIN
    RETURN QUERY (
    WITH RECURSIVE parents as (
        SELECT id_class, short_name, id_main_class FROM classification
        WHERE id_class = find_id_class

        UNION

        SELECT c.id_class, c.short_name, c.id_main_class FROM classification c
        INNER JOIN parents p on c.id_class = p.id_main_class
    ) select p.id_class, p.short_name from parents p);
END;
$$ LANGUAGE plpgsql;

-- Функция: Вывести классификацию вместе с продуктами
CREATE OR REPLACE function show_tree()
RETURNS TABLE (class_id int, class_short_name varchar(50), product_id int, product_short_name varchar(20)) AS $$
BEGIN
   RETURN QUERY
    WITH RECURSIVE children as (
        SELECT c.id_class, c.id_main_class, c.short_name
        FROM classification c
        WHERE c.id_main_class IS NULL
        UNION
        SELECT c.id_class, c.id_main_class, c.short_name
        FROM classification c
        INNER JOIN children ch ON c.id_main_class = ch.id_class
    )
    SELECT ch.id_class, ch.short_name, p.id_product, p.short_name
    FROM PRODUCT p
    INNER JOIN children ch ON ch.id_class = p.id_class;
END;
$$ LANGUAGE plpgsql;

-- Функция: Добавление продукта
CREATE OR REPLACE FUNCTION create_product(
    short_name VARCHAR(100),
    name VARCHAR(200),
    product_id_class int,
    product_id_unit int,
    price numeric(13, 2),
    base_id_product int
)
RETURNS VOID AS $$
DECLARE
    hasClass int;
BEGIN
    INSERT INTO Product (short_name, name, id_class, id_unit, price, base_id_product)
    VALUES (short_name, name, product_id_class, COALESCE(product_id_unit, (SELECT id_unit FROM classification WHERE id_class = product_id_class)), price, base_id_product);
END;
$$ LANGUAGE plpgsql;

-- Функция: добавление спецификации продукта
CREATE OR REPLACE FUNCTION create_spec_position(
    id_product_input INTEGER,
    id_position_input INTEGER,
    quantity NUMERIC
)
RETURNS VOID AS $$
DECLARE
    v_exists BOOLEAN;
    v_product_exists BOOLEAN;
    v_part_exists BOOLEAN;
BEGIN
    -- Проверка, существует ли продукт
    SELECT EXISTS (
        SELECT 1
        FROM product
        WHERE id_product = id_product_input
    ) INTO v_product_exists;

    -- Проверка, существует ли часть (id_position_input)
    SELECT EXISTS (
        SELECT 1
        FROM product
        WHERE id_product = id_position_input
    ) INTO v_part_exists;

    IF NOT v_product_exists THEN
        RAISE EXCEPTION 'Продукт с id_product % не существует', id_product_input;
    END IF;

    IF NOT v_part_exists THEN
        RAISE EXCEPTION 'Часть с id_position_input % не существует', id_position_input;
    END IF;

    -- Проверка на цикл (рекурсивное обнаружение)
    SELECT EXISTS (
        WITH RECURSIVE cte AS (
            SELECT id_product, id_position
            FROM spec_position
            WHERE id_product = id_product_input  -- Начинаем с текущего продукта

            UNION

            SELECT sp.id_product, sp.id_position
            FROM spec_position sp
            INNER JOIN cte ON sp.id_position = cte.id_product  -- Рекурсивно соединяем с родителями
        )
        SELECT 1
        FROM cte
        WHERE id_product = id_position_input -- Проверяем, есть ли совпадение с новым id_position_input
    ) INTO v_exists;

    IF v_exists THEN
        RAISE EXCEPTION 'Цикл обнаружен: id_position_input % является родителем для id_product_input %', id_position_input, id_product_input;
    ELSE
        -- Если цикл не найден, выполняем вставку
        INSERT INTO spec_position(id_product, id_position, quantity)
        VALUES (id_product_input, id_position_input, quantity);
    END IF;
END;
$$ LANGUAGE plpgsql;






-- Функция: Удаление позиции спецификации
CREATE OR REPLACE FUNCTION delete_spec_position(del_id_position int)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM spec_position WHERE id_position = del_id_position) THEN
        RAISE EXCEPTION 'Позиция спецификации с ID % не существует', del_id_position;
    END IF;

    DELETE FROM spec_position WHERE id_position = del_id_position;
END;
$$ LANGUAGE plpgsql;

-- Функция: Вывод таблицы спецификации продуктов
CREATE OR REPLACE FUNCTION show_spec_product(p_id_product INT)
RETURNS TABLE(
   product_full_name VARCHAR,
   id_position INT,
   quantity INT
) AS $$
BEGIN
   RETURN QUERY
   SELECT
       p.name AS product_full_name,
       sp.id_position,
       sp.quantity
   FROM
       spec_position sp
   JOIN
     product p ON sp.id_product = p.id_product
   WHERE
       sp.id_product = p_id_product;
END;
$$ LANGUAGE plpgsql;



-- Функция: Вывод спецификации изделий на всю глубину
CREATE OR REPLACE FUNCTION get_spec_positions()
RETURNS TABLE (
    id_position INT,
    id_product INT,
    quantity NUMERIC(13, 2),
    depth INT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE product_hierarchy AS (
        SELECT
            p.id_product AS root_product,
            p.id_product,
            1 AS depth
        FROM Product p

        UNION ALL

        SELECT
            ph.root_product,
            p.id_product,
            ph.depth + 1 AS depth
        FROM product_hierarchy ph
        JOIN Product p ON p.base_id_product = ph.id_product
    )
    SELECT
        sp.id_position,
        sp.id_product,
        sp.quantity,
        ph.depth
    FROM Spec_position sp
    JOIN product_hierarchy ph ON sp.id_product = ph.id_product
    ORDER BY ph.root_product, ph.depth, sp.id_position;
END;
$$ LANGUAGE plpgsql;



-- подсчет сводных норм

create function calculate_component_quantities(input_product_id integer)
    returns TABLE(id_product integer, full_name character varying, quantity_sum integer)
    language plpgsql
as
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE component_tree AS (
        -- Начальный запрос: выбираем прямые компоненты для заданного продукта
        SELECT
            sp.id_part AS id_product,
            sp.quantity::integer AS quantity, -- Увеличенный тип numeric
            p.name AS full_name
        FROM Spec_position sp
        JOIN Product p ON sp.id_part = p.id_product
        WHERE sp.id_product = input_product_id

        UNION

        -- Рекурсивно выбираем компоненты для найденных компонентов
        SELECT
            sp.id_part AS id_product,
            (sp.quantity::integer * ct.quantity)::integer AS quantity, -- Умножение с контролем типа
            p.name AS full_name
        FROM Spec_position sp
        JOIN component_tree ct ON sp.id_product = ct.id_product
        JOIN Product p ON sp.id_part = p.id_product
    )
    SELECT
        ct.id_product,
        ct.full_name,
        SUM(ct.quantity)::integer AS quantity_sum -- Агрегирование с контролем типа
    FROM component_tree ct
    GROUP BY ct.id_product, ct.full_name
    ORDER BY ct.id_product;
END;
$$;




SELECT * FROM calculate_component_quantities(1);

-- =========================================
-- Заполнение единиц измерений
SELECT create_unit('шт', 'штука', 1);
SELECT create_unit('кг', 'килограмм', 2);
SELECT create_unit('м', 'метр', 3);
SELECT create_unit('м.п.', 'метр погонный', 4);

-- =========================================
-- Заполнение классификатора
-- =========================================
SELECT create_class('Вентиляция', 'Элементы вентиляции', 1, NULL); -- Единица измерения для "шт"
-- Создание класса с учетом родительского класса
SELECT create_class('Воздуховоды', 'Элементы воздуховодов', 2, 1); -- Родительский класс для "Воздуховодов"

SELECT create_class('Крепеж', 'Крепежные элементы', 2, 1); -- Единица измерения "кг"
SELECT create_class('Решетки', 'Вентиляционные решетки', 1, 1); -- Единица измерения "шт"

-- =========================================
-- Добавление продуктов
-- =========================================
-- Продукты для воздуховодов
SELECT create_product('Заслонка воздушная', 'Заслонка воздушная с электроприводом BELIMO', 2, 1, 1800.00, NULL); -- Крепеж для воздуховодов
SELECT create_product('Крепеж', 'Крепеж для воздуховодов', 2, 1, 150.00, NULL);

-- Продукты для вентиляции
SELECT create_product('Вентилятор', 'Вентилятор радиальный приточный LITENED 50-25', 1, 1, 2500.00, NULL);
SELECT create_product('Фильтр', 'Фильтр воздушный LITENED FRU 50-25', 1, 1, 500.00, NULL);

-- Добавим продукт с id=6, чтобы можно было добавить спецификацию для него
SELECT create_product('Воздуховод', 'l', 2, 1, 1000.00, NULL);

-- =========================================
-- Заполнение спецификации
-- =========================================
SELECT create_spec_position(1,1, 8.51);  -- Для продукта с id = 1 (например, "Заслонка воздушная")
SELECT create_spec_position(2,3, 2.1);   -- Для продукта с id = 6 (новый продукт)
SELECT create_spec_position(3,2, 3.1);   -- Для продукта с id = 2 (например, "Крепеж")
-- =========================================
-- Вывод спецификации по id продукта
-- =========================================
SELECT * FROM show_spec_product(1); -- Спецификация для продукта с id = 1

-- =========================================
-- Вывод полной структуры спецификации
-- =========================================
SELECT * FROM get_spec_positions();

-- Функция для получения иерархии версий продукта
CREATE OR REPLACE FUNCTION get_product_version(product_id INT)
RETURNS TABLE (
    version_id INT,
    version_short_name VARCHAR(20),
    version_name VARCHAR(50),
    base_version_id INT,
    price NUMERIC(13, 2),
    level INT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE version_tree AS (
        -- Начальный продукт (первая версия)
        SELECT
            p.id_product AS version_id,
            p.short_name AS version_short_name,
            p.name AS version_name,
            p.base_id_product AS base_version_id,
            p.price,
            1 AS level
        FROM Product p
        WHERE p.id_product = product_id

        UNION ALL

        -- Рекурсивное добавление зависимых версий
        SELECT
            p.id_product AS version_id,
            p.short_name AS version_short_name,
            p.name AS version_name,
            p.base_id_product AS base_version_id,
            p.price,
            vt.level + 1 AS level
        FROM Product p
        INNER JOIN version_tree vt
            ON p.base_id_product = vt.version_id
        WHERE p.id_product != p.base_id_product -- Исключение самоссылки
    )
    SELECT
        vt.version_id,
        vt.version_short_name,
        vt.version_name,
        vt.base_version_id,
        vt.price,
        vt.level
    FROM version_tree vt
    ORDER BY vt.level;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy_specification(
    source_product_id INT,
    target_product_id INT
)
RETURNS VOID AS $$
DECLARE
    -- Проверка существования изделий
    source_exists BOOLEAN;
    target_exists BOOLEAN;
    has_cycle BOOLEAN;
BEGIN
    -- Проверяем, существуют ли исходный и целевой продукты
    SELECT EXISTS(SELECT 1 FROM Product WHERE id_product = source_product_id) INTO source_exists;
    SELECT EXISTS(SELECT 1 FROM Product WHERE id_product = target_product_id) INTO target_exists;

    IF NOT source_exists THEN
        RAISE EXCEPTION 'Исходный продукт с id_product % не существует', source_product_id;
    END IF;

    IF NOT target_exists THEN
        RAISE EXCEPTION 'Целевой продукт с id_product % не существует', target_product_id;
    END IF;

    -- Проверяем, чтобы не возник цикл
    SELECT EXISTS (
        WITH RECURSIVE cte AS (
            SELECT sp.id_product, sp.id_part
            FROM Spec_position sp
            WHERE sp.id_product = source_product_id

            UNION ALL

            SELECT sp.id_product, sp.id_part
            FROM Spec_position sp
            JOIN cte ON sp.id_product = cte.id_part
        )
        SELECT 1
        FROM cte
        WHERE id_part = target_product_id
    ) INTO has_cycle;

    IF has_cycle THEN
        RAISE EXCEPTION 'Цикл обнаружен: нельзя скопировать спецификацию от % к %', source_product_id, target_product_id;
    END IF;

    -- Копируем спецификацию
    INSERT INTO Spec_position (id_product, id_part, quantity)
    SELECT target_product_id, sp.id_part, sp.quantity
    FROM Spec_position sp
    WHERE sp.id_product = source_product_id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_specification_with_names()
RETURNS TABLE (
    id_product INT,
    product_name VARCHAR(50),
    id_part INT,
    part_name VARCHAR(50),
    quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sp.id_product,
        p1.name AS product_name,
        sp.id_part,
        p2.name AS part_name,
        sp.quantity
    FROM
        Spec_position sp
    JOIN
        Product p1 ON sp.id_product = p1.id_product
    JOIN
        Product p2 ON sp.id_part = p2.id_product;
END;
$$ LANGUAGE plpgsql;