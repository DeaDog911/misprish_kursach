--
-- PostgreSQL database dump
--

-- Dumped from database version 15.0
-- Dumped by pg_dump version 15.0

-- Started on 2024-05-26 15:12:23

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3436 (class 1262 OID 270486)
-- Name: mispris; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE mispris WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE mispris OWNER TO postgres;

\connect mispris

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 263 (class 1255 OID 287138)
-- Name: add_agr_par(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_agr_par(agr_par_id integer, par_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    pos_num int;
begin
    IF NOT EXISTS(select 1 from pos_agr WHERE pos_agr.id_agr = agr_par_id AND pos_agr.id_par = par_id) THEN
        SELECT count(*) + 1 FROM pos_agr WHERE pos_agr.id_agr = agr_par_id INTO pos_num;
        INSERT INTO pos_agr (id_agr, id_par, num) values (agr_par_id, par_id, pos_num);
    end if;
end;
$$;


ALTER FUNCTION public.add_agr_par(agr_par_id integer, par_id integer) OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 287048)
-- Name: add_parameter_class(integer, integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_parameter_class(par_id integer, class_id integer, par_max_val numeric, par_min_val numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
    if not exists(select 1 from par_class where id_class = class_id and id_par = par_id) then
        if EXISTS(SELECT 1 FROM pos_agr WHERE id_agr = par_id) then
            RAISE EXCEPTION 'Параметр не может быть агрегатом';
        end if;
        INSERT INTO par_class (id_par, id_class, min_val, max_val) values (par_id, class_id, par_min_val, par_max_val);
    else
        UPDATE par_class SET max_val = par_max_val, min_val = par_min_val WHERE id_par = par_id and id_class = class_id;
    end if;
end;
$$;


ALTER FUNCTION public.add_parameter_class(par_id integer, class_id integer, par_max_val numeric, par_min_val numeric) OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 287119)
-- Name: add_parameter_product(integer, integer, integer, numeric, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_parameter_product(ins_par_id integer, product_id integer, par_val_int integer, par_val_real numeric, par_val_str character varying, par_val_enum integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    class_id int;
    par_type int;
    par_max_val numeric;
    par_min_val numeric;
begin
    SELECT id_class from product where id_product = product_id into class_id;
    select f.par_type, f.par_max_val, f.par_min_val from find_parameters(class_id) as f
            WHERE f.par_id = ins_par_id INTO par_type, par_max_val, par_min_val;
    if not exists(select 1 from par_prod where id_product = product_id and id_par = ins_par_id) then
        if par_type is null then
            RAISE EXCEPTION 'Параметр не связан с классом продуктов';
        end if;
        if EXISTS(SELECT 1 FROM pos_agr WHERE id_agr = ins_par_id) then
            RAISE EXCEPTION 'Параметр не может быть агрегатом';
        end if;
        if (check_parameter_values(par_type, par_val_int, par_val_real, par_val_str,
            par_val_enum, par_max_val, par_min_val)) then
            INSERT INTO par_prod (id_par, id_product, val_int, val_real, val_str, val_enum)
                VALUES (ins_par_id, product_id, par_val_int, par_val_real, par_val_str, par_val_enum);
        end if;
    else
        if (check_parameter_values(par_type, par_val_int, par_val_real, par_val_str,
            par_val_enum, par_max_val, par_min_val)) then
            UPDATE par_prod SET
                        val_int = par_val_int,
                        val_real = par_val_real,
                        val_str = par_val_str,
                        val_enum = par_val_enum
                        WHERE id_par = ins_par_id and id_product = product_id;
        end if;
    end if;
end;
$$;


ALTER FUNCTION public.add_parameter_product(ins_par_id integer, product_id integer, par_val_int integer, par_val_real numeric, par_val_str character varying, par_val_enum integer) OWNER TO postgres;

--
-- TOC entry 230 (class 1255 OID 270619)
-- Name: change_parent_class(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_parent_class(child_id_class integer, new_parent_id_class integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.change_parent_class(child_id_class integer, new_parent_id_class integer) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 286970)
-- Name: change_pos_enum(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_pos_enum(pos_id integer, new_pos_enum_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    pos_num int;
BEGIN
    IF (SELECT count(*) FROM find_children(new_pos_enum_id)) > 1 THEN
        RAISE EXCEPTION 'Позиция перечисления может относится только к терминальному классу перечислений';
    end if;
    select count(*)+1 FROM pos_enum WHERE id_enum = new_pos_enum_id into pos_num;
    UPDATE pos_enum SET id_enum = new_pos_enum_id WHERE id_pos = pos_id;
    UPDATE pos_enum SET num = pos_num WHERE id_pos = pos_id;
end;
$$;


ALTER FUNCTION public.change_pos_enum(pos_id integer, new_pos_enum_id integer) OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 286946)
-- Name: change_product_class(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_product_class(change_id_product integer, new_id_class integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT count(*) FROM find_children(new_id_class)) > 1 THEN
        RAISE EXCEPTION 'Продукт может относится только к терминальному классу';
    end if;
    UPDATE Product SET id_class = new_id_class WHERE id_product = change_id_product;
END;
$$;


ALTER FUNCTION public.change_product_class(change_id_product integer, new_id_class integer) OWNER TO postgres;

--
-- TOC entry 269 (class 1255 OID 287120)
-- Name: check_parameter_values(integer, integer, numeric, character varying, integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_parameter_values(par_type integer, par_val_int integer, par_val_real numeric, par_val_str character varying, par_val_enum integer, par_max_val numeric, par_min_val numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    intType int := 60;
    realType int := 61;
    strType int := 62;
    enType int := 50;
    val numeric;
    en_real_val numeric;
    en_int_val numeric;
begin
    if not (par_type = any(array[intType, realType, strType, enType])) then
        raise exception 'Неверно выбран тип параметра';
    end if;
    if (par_val_enum is not null) then
        if (par_type <> enType) then
            RAISE EXCEPTION 'Параметр не имеет тип перечисления';
        end if;
        SELECT pe.int_val, pe.real_val FROM pos_enum pe WHERE id_pos = par_val_enum into en_int_val, en_real_val;
        if (en_int_val is not null) then
            val = en_int_val;
        end if;
        if (en_real_val is not null) then
            val = en_real_val;
        end if;
    else
        if (par_type = any(array[intType, realType])) then
            if (par_val_int is not null) then
                val = par_val_int;
            end if;
            if (par_val_real is not null) then
                val = par_val_real;
            end if;
        end if;
    end if;
    if (val is not null) and ((par_max_val is not null and val > par_max_val)
               or (par_min_val is not null and val < par_min_val)) then
        RAISE EXCEPTION 'Значение не удовлетворяет ограничениям';
    end if;
    return true;
end;
$$;


ALTER FUNCTION public.check_parameter_values(par_type integer, par_val_int integer, par_val_real numeric, par_val_str character varying, par_val_enum integer, par_max_val numeric, par_min_val numeric) OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 286949)
-- Name: class_has_product(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.class_has_product(product_id integer, class_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS(SELECT find_children.class_id FROM find_children(class_id)
        JOIN product p on p.id_class = find_children.class_id WHERE p.id_product = product_id);
END;
$$;


ALTER FUNCTION public.class_has_product(product_id integer, class_id integer) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 286947)
-- Name: create_class(character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_class(class_short_name character varying, class_name character varying, class_id_unit integer, class_id_main_class integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT count(*) FROM classification WHERE short_name = class_short_name) > 0 THEN
        RAISE EXCEPTION 'В классификации уже есть класс с таким обозначением';
    end if;

    IF (class_id_unit = 0) THEN
        SELECT id_unit FROM classification WHERE id_class = class_id_main_class INTO class_id_unit;
    end if;

    IF (class_id_unit is not null) and (SELECT count(*) FROM unit WHERE id_unit = class_id_unit) = 0 THEN
        RAISE EXCEPTION 'Выбрана несуществующая единица измерения';
    end if;

    INSERT INTO classification (short_name, name, id_unit, id_main_class)
        VALUES (class_short_name, class_name, class_id_unit, class_id_main_class);
END;
$$;


ALTER FUNCTION public.create_class(class_short_name character varying, class_name character varying, class_id_unit integer, class_id_main_class integer) OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 287047)
-- Name: create_parameter(integer, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_parameter(par_type integer, par_short_name character varying, par_name character varying, par_id_unit integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    intType int := 60;
    realType int := 61;
    strType int := 62;
    enType int := 50;
begin
    if not exists(SELECT 1 FROM classification AS class WHERE class.id_class = par_type) THEN
        RAISE EXCEPTION 'Выбран несуществующий тип параметра';
    end if;
    IF (SELECT count(*) FROM find_children(par_type)) > 1 THEN
        RAISE EXCEPTION 'Параметр может относится только к терминальному классу типа параметров';
    end if;
    if not (par_type = any(array[intType, realType, strType, enType])) then
        raise exception 'Неверно выбран тип параметра';
    end if;
    INSERT INTO parameter (short_name, name, type_par, id_unit) values (par_short_name, par_name, par_type, par_id_unit);
end;
$$;


ALTER FUNCTION public.create_parameter(par_type integer, par_short_name character varying, par_name character varying, par_id_unit integer) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 286974)
-- Name: create_pos_enum(integer, character varying, character varying, numeric, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_pos_enum(pos_enum_id integer, pos_short_name character varying, pos_name character varying, pos_real_val numeric, pos_int_val integer, pos_pic_val character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    pos_num int;
BEGIN
    if not exists(SELECT 1 FROM Classification AS class WHERE class.id_class = pos_enum_id) THEN
        RAISE EXCEPTION 'Выбрано несуществующее перечисление';
    end if;
    IF (SELECT count(*) FROM find_children(pos_enum_id)) > 1 THEN
        RAISE EXCEPTION 'Продукт может относится только к терминальному классу перечислений';
    end if;
    SELECT count(1)+1 FROM pos_enum WHERE id_enum = pos_enum_id into pos_num;
    INSERT INTO pos_enum (id_enum, num, short_name, name, real_val, int_val, pic_val)
        VALUES (pos_enum_id, pos_num, pos_short_name, pos_name, pos_real_val, pos_int_val, pos_pic_val);
end;
$$;


ALTER FUNCTION public.create_pos_enum(pos_enum_id integer, pos_short_name character varying, pos_name character varying, pos_real_val numeric, pos_int_val integer, pos_pic_val character varying) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 270558)
-- Name: create_product(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_product(short_name character varying, name character varying, product_id_class integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    if not (SELECT 1 FROM Classification AS class WHERE class.id_class = product_id_class) THEN
        RAISE EXCEPTION 'Выбран несуществующий класс';
    end if;
    IF (SELECT count(*) FROM find_children(product_id_class)) > 1 THEN
        RAISE EXCEPTION 'Продукт может относится только к терминальному классу';
    end if;
    INSERT INTO Product (short_name, name, id_class) VALUES (short_name, name, product_id_class);
END;
$$;


ALTER FUNCTION public.create_product(short_name character varying, name character varying, product_id_class integer) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 286976)
-- Name: create_unit(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_unit(short_name character varying, name character varying, code integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Unit (short_name, name, code) VALUES (short_name, name, code);
END;
$$;


ALTER FUNCTION public.create_unit(short_name character varying, name character varying, code integer) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 270599)
-- Name: cycle(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cycle(from_id integer, to_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.cycle(from_id integer, to_id integer) OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 286966)
-- Name: del_pos_enum_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.del_pos_enum_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM pos_enum WHERE id_enum = old.id_class;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.del_pos_enum_trigger() OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 270598)
-- Name: delete_class(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_class(del_id_class integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent_id int;
    count int;
    child_id int;
    product_id int;
    i int;
BEGIN
    SELECT classification.id_main_class FROM classification where id_class = del_id_class INTO parent_id;
    select count(1) from classification where id_main_class = del_id_class into count;
    i = 0;
    if count > 0 THEN
        LOOP
            select id_class from classification where id_main_class = del_id_class LIMIT 1 OFFSET i INTO child_id;
            perform change_parent_class(child_id, parent_id);
            i = i + 1;
            if i >= count THEN
                exit;
            end if;
        end loop;
    END IF;
    i = 0;
    select count(1) from product where id_class = del_id_class into count;
    if count > 0 then
        LOOP
            select id_product from product where id_class = del_id_class LIMIT 1 OFFSET i INTO product_id;
            perform change_product_class(product_id, parent_id);
            i = i + 1;
            if i >= count THEN
                exit;
            end if;
        end loop;
    END IF;
    DELETE FROM classification WHERE id_class = del_id_class;
END;
$$;


ALTER FUNCTION public.delete_class(del_id_class integer) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 287117)
-- Name: delete_parameter(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_parameter(par_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
    DELETE FROM parameter WHERE id_par = par_id;
end;
$$;


ALTER FUNCTION public.delete_parameter(par_id integer) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 286969)
-- Name: delete_pos_enum(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_pos_enum(pos_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    pos_num int;
    pos_id_enum int;
begin
    select num from pos_enum where id_pos = pos_id into pos_num;
    select id_enum from pos_enum where id_pos = pos_id into pos_id_enum;
    DELETE FROM pos_enum WHERE id_pos = pos_id;
    UPDATE pos_enum SET num = num - 1 WHERE num > pos_num AND id_enum = pos_id_enum;
end;
$$;


ALTER FUNCTION public.delete_pos_enum(pos_id integer) OWNER TO postgres;

--
-- TOC entry 228 (class 1255 OID 270559)
-- Name: delete_product(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_product(del_id_product integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM Product WHERE id_product = del_id_product;
END;
$$;


ALTER FUNCTION public.delete_product(del_id_product integer) OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 270560)
-- Name: delete_unit(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_unit(id_unit_delete integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.delete_unit(id_unit_delete integer) OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 287140)
-- Name: down_agr_par(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.down_agr_par(agr_par_id integer, par_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    pos_num int;
    down_par_id int;
begin
    SELECT num from pos_agr WHERE id_agr = agr_par_id and id_par = par_id into pos_num;
    if pos_num = (SELECT count(1) FROM pos_agr WHERE id_agr = agr_par_id) then
        raise exception 'Параметр уже стоит на последнем месте';
    end if;
    SELECT id_par from pos_agr WHERE id_agr = agr_par_id AND num = pos_num + 1 INTO down_par_id;
    UPDATE pos_agr SET num = pos_num WHERE id_par = down_par_id;
    UPDATE pos_agr SET num = pos_num + 1 WHERE id_par = par_id;
end;
$$;


ALTER FUNCTION public.down_agr_par(agr_par_id integer, par_id integer) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 286972)
-- Name: down_pos(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.down_pos(pos_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    pos_num int;
    down_pos_id int;
    pos_enum_id int;
begin
    SELECT id_enum from pos_enum WHERE id_pos = pos_id into pos_enum_id;
    SELECT num from pos_enum WHERE id_pos = pos_id into pos_num;
    if pos_num = (SELECT count(1) FROM pos_enum WHERE id_enum = pos_enum_id) then
        raise exception 'Перечисление уже стоит на последнем месте';
    end if;
    SELECT id_pos from pos_enum WHERE id_enum = pos_enum_id AND num = pos_num + 1 INTO down_pos_id;
    UPDATE pos_enum SET num = pos_num WHERE id_pos = down_pos_id;
    UPDATE pos_enum SET num = pos_num + 1 WHERE id_pos = pos_id;
end;
$$;


ALTER FUNCTION public.down_pos(pos_id integer) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 278760)
-- Name: find_children(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_children(find_id_class integer) RETURNS TABLE(class_id integer, child_name character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.find_children(find_id_class integer) OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 287141)
-- Name: find_list_agr_par(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_list_agr_par(find_agr_par_id integer) RETURNS TABLE(agr_par_id integer, agr_par_short_name character varying, par_id integer, par_short_name character varying, par_num integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY (
        SELECT pa.id_agr, p2.short_name, pa.id_par, p1.short_name, pa.num FROM pos_agr pa
                                    JOIN parameter p1 on pa.id_par = p1.id_par
                                    JOIN parameter p2 on pa.id_agr = p2.id_par
                                    WHERE id_agr = find_agr_par_id
                                    ORDER BY pa.num
    );
END;
$$;


ALTER FUNCTION public.find_list_agr_par(find_agr_par_id integer) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 286975)
-- Name: find_list_enum(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_list_enum(enum_id integer) RETURNS TABLE(pos_enum_id integer, pos_enum_short_name character varying, pos_id integer, pos_short_name character varying, pos_num integer, pos_real_val numeric, pos_int_val integer, pos_pic_val character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY (
    WITH RECURSIVE children as (
        SELECT id_class, id_main_class, short_name FROM classification
        WHERE id_class = enum_id

        UNION

        SELECT c.id_class, c.id_main_class, c.short_name FROM classification c
        INNER JOIN children ch on c.id_main_class = ch.id_class
    ) SELECT ch.id_class, ch.short_name, pos.id_pos, pos.short_name, pos.num, pos.real_val, pos.int_val, pos.pic_val
      FROM pos_enum pos INNER JOIN children ch on ch.id_class = pos.id_enum order by pos.num);
END;
$$;


ALTER FUNCTION public.find_list_enum(enum_id integer) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 287118)
-- Name: find_parameters(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_parameters(find_class_id integer) RETURNS TABLE(par_id integer, class_id integer, par_short_name character varying, par_type integer, par_max_val numeric, par_min_val numeric)
    LANGUAGE plpgsql
    AS $$
begin
    return query (SELECT par.id_par, pc.id_class, par.short_name, par.type_par, pc.max_val, pc.min_val
                  FROM find_parents(find_class_id) p
                    JOIN par_class pc on p.class_id = pc.id_class
                           JOIN parameter par on par.id_par = pc.id_par);
end;
$$;


ALTER FUNCTION public.find_parameters(find_class_id integer) OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 287121)
-- Name: find_parameters_prod(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_parameters_prod(find_prod_id integer) RETURNS TABLE(par_id integer, par_short_name character varying, prod_id integer, prod_short_name character varying, par_val_int integer, par_val_real numeric, par_val_str character varying, par_val_enum integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query (SELECT pp.id_par, p.short_name, pp.id_product, prod.short_name,
                         pp.val_int, pp.val_real, pp.val_str, pp.val_enum FROM par_prod pp
                                     JOIN parameter p on p.id_par = pp.id_par
                                     JOIN product prod on prod.id_product = pp.id_product
                                     WHERE pp.id_product = find_prod_id);
end;
$$;


ALTER FUNCTION public.find_parameters_prod(find_prod_id integer) OWNER TO postgres;

--
-- TOC entry 270 (class 1255 OID 287142)
-- Name: find_parameters_prod(integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_parameters_prod(prod_id integer, max_val numeric, min_val numeric) RETURNS TABLE(product_id integer, product_short_name character varying, prod_real_val numeric, prod_int_vel integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query (SELECT par_prod.id_product, prod.short_name, par_prod.val_real, par_prod.val_int FROM par_prod
                                           JOIN product prod on prod.id_product = par_prod.id_product
                                           WHERE par_prod.id_product = prod_id
                                           AND ((par_prod.val_int >= min_val and par_prod.val_int <= max_val)
                                           OR (par_prod.val_real >= min_val and par_prod.val_real <= max_val)));
end;
$$;


ALTER FUNCTION public.find_parameters_prod(prod_id integer, max_val numeric, min_val numeric) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 278761)
-- Name: find_parents(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_parents(find_id_class integer) RETURNS TABLE(class_id integer, parent_name character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.find_parents(find_id_class integer) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 286948)
-- Name: find_products(integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_products(from_id_class integer[]) RETURNS TABLE(class_id integer, class_short_name character varying, id integer, p_short_name character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.find_products(from_id_class integer[]) OWNER TO postgres;

--
-- TOC entry 271 (class 1255 OID 287145)
-- Name: find_products_by_par(integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_products_by_par(par_id integer, min_val numeric, max_val numeric) RETURNS TABLE(product_id integer, product_short_name character varying, prod_real_val numeric, prod_int_vel integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query (SELECT par_prod.id_product, prod.short_name, par_prod.val_real, par_prod.val_int FROM par_prod
                                           JOIN product prod on prod.id_product = par_prod.id_product
                                           WHERE par_prod.id_par = par_id
                                           AND ((par_prod.val_int >= min_val and par_prod.val_int <= max_val)
                                           OR (par_prod.val_real >= min_val and par_prod.val_real <= max_val)));
end;
$$;


ALTER FUNCTION public.find_products_by_par(par_id integer, min_val numeric, max_val numeric) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 278759)
-- Name: show_tree(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.show_tree() RETURNS TABLE(class_id integer, class_short_name character varying, product_id integer, product_short_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN QUERY
    WITH RECURSIVE children as (
        SELECT c.id_class, c.id_main_class, c.short_name FROM classification c

        UNION

        SELECT c.id_class, c.id_main_class, c.short_name FROM classification c
        INNER JOIN children ch on c.id_main_class = ch.id_class
    ) SELECT ch.id_class, ch.short_name, p.id_product, p.short_name FROM PRODUCT p INNER JOIN children ch on ch.id_class = p.id_class;
END;
$$;


ALTER FUNCTION public.show_tree() OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 287139)
-- Name: up_agr_par(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.up_agr_par(agr_par_id integer, par_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    pos_num int;
    up_par_id int;
begin
    SELECT num from pos_agr WHERE id_agr = agr_par_id and id_par = par_id into pos_num;
    if pos_num = 1 then
        raise exception 'Перечисление уже стоит на первом месте';
    end if;
    SELECT id_par from pos_agr WHERE id_agr = agr_par_id AND num = pos_num - 1 INTO up_par_id;
    UPDATE pos_agr SET num = pos_num WHERE id_par = up_par_id;
    UPDATE pos_agr SET num = pos_num - 1 WHERE id_par = par_id;
end;
$$;


ALTER FUNCTION public.up_agr_par(agr_par_id integer, par_id integer) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 286971)
-- Name: up_pos(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.up_pos(pos_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    pos_num int;
    up_pos_id int;
    pos_enum_id int;
begin
    SELECT num from pos_enum WHERE id_pos = pos_id into pos_num;
    if pos_num = 1 then
        raise exception 'Перечисление уже стоит на первом месте';
    end if;
    SELECT id_enum from pos_enum WHERE id_pos = pos_id into pos_enum_id;
    SELECT id_pos from pos_enum WHERE id_enum = pos_enum_id AND num = pos_num - 1 INTO up_pos_id;
    UPDATE pos_enum SET num = pos_num WHERE id_pos = up_pos_id;
    UPDATE pos_enum SET num = pos_num - 1 WHERE id_pos = pos_id;
end;
$$;


ALTER FUNCTION public.up_pos(pos_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 270631)
-- Name: classification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classification (
    id_class integer NOT NULL,
    short_name character varying(50),
    name character varying(100),
    id_unit integer,
    id_main_class integer
);


ALTER TABLE public.classification OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 270630)
-- Name: classification_id_class_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classification_id_class_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.classification_id_class_seq OWNER TO postgres;

--
-- TOC entry 3437 (class 0 OID 0)
-- Dependencies: 216
-- Name: classification_id_class_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classification_id_class_seq OWNED BY public.classification.id_class;


--
-- TOC entry 224 (class 1259 OID 287066)
-- Name: par_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.par_class (
    id_par integer NOT NULL,
    id_class integer NOT NULL,
    min_val numeric,
    max_val numeric
);


ALTER TABLE public.par_class OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 287083)
-- Name: par_prod; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.par_prod (
    id_par integer NOT NULL,
    id_product integer NOT NULL,
    val_int integer,
    val_real numeric,
    val_str character varying(100),
    val_enum integer
);


ALTER TABLE public.par_prod OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 287050)
-- Name: parameter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameter (
    id_par integer NOT NULL,
    short_name character varying(50),
    name character varying(100),
    type_par integer NOT NULL,
    id_unit integer NOT NULL
);


ALTER TABLE public.parameter OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 287049)
-- Name: parameter_id_par_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parameter_id_par_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parameter_id_par_seq OWNER TO postgres;

--
-- TOC entry 3438 (class 0 OID 0)
-- Dependencies: 222
-- Name: parameter_id_par_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parameter_id_par_seq OWNED BY public.parameter.id_par;


--
-- TOC entry 226 (class 1259 OID 287122)
-- Name: pos_agr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pos_agr (
    id_agr integer NOT NULL,
    id_par integer NOT NULL,
    num integer
);


ALTER TABLE public.pos_agr OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 286953)
-- Name: pos_enum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pos_enum (
    id_pos integer NOT NULL,
    id_enum integer NOT NULL,
    num integer NOT NULL,
    short_name character varying(50),
    name character varying(100),
    real_val numeric,
    int_val integer,
    pic_val character varying(50)
);


ALTER TABLE public.pos_enum OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 286952)
-- Name: pos_enum_id_pos_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pos_enum_id_pos_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pos_enum_id_pos_seq OWNER TO postgres;

--
-- TOC entry 3439 (class 0 OID 0)
-- Dependencies: 220
-- Name: pos_enum_id_pos_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pos_enum_id_pos_seq OWNED BY public.pos_enum.id_pos;


--
-- TOC entry 219 (class 1259 OID 270648)
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    id_product integer NOT NULL,
    short_name character varying(20),
    name character varying(50),
    id_class integer
);


ALTER TABLE public.product OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 270647)
-- Name: product_id_product_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_id_product_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_id_product_seq OWNER TO postgres;

--
-- TOC entry 3440 (class 0 OID 0)
-- Dependencies: 218
-- Name: product_id_product_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_id_product_seq OWNED BY public.product.id_product;


--
-- TOC entry 215 (class 1259 OID 270624)
-- Name: unit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unit (
    id_unit integer NOT NULL,
    short_name character varying(20),
    name character varying(50),
    code integer
);


ALTER TABLE public.unit OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 270623)
-- Name: unit_id_unit_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.unit_id_unit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.unit_id_unit_seq OWNER TO postgres;

--
-- TOC entry 3441 (class 0 OID 0)
-- Dependencies: 214
-- Name: unit_id_unit_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.unit_id_unit_seq OWNED BY public.unit.id_unit;


--
-- TOC entry 3240 (class 2604 OID 270634)
-- Name: classification id_class; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classification ALTER COLUMN id_class SET DEFAULT nextval('public.classification_id_class_seq'::regclass);


--
-- TOC entry 3243 (class 2604 OID 287053)
-- Name: parameter id_par; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameter ALTER COLUMN id_par SET DEFAULT nextval('public.parameter_id_par_seq'::regclass);


--
-- TOC entry 3242 (class 2604 OID 286956)
-- Name: pos_enum id_pos; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_enum ALTER COLUMN id_pos SET DEFAULT nextval('public.pos_enum_id_pos_seq'::regclass);


--
-- TOC entry 3241 (class 2604 OID 270651)
-- Name: product id_product; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product ALTER COLUMN id_product SET DEFAULT nextval('public.product_id_product_seq'::regclass);


--
-- TOC entry 3239 (class 2604 OID 270627)
-- Name: unit id_unit; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit ALTER COLUMN id_unit SET DEFAULT nextval('public.unit_id_unit_seq'::regclass);


--
-- TOC entry 3421 (class 0 OID 270631)
-- Dependencies: 217
-- Data for Name: classification; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (1, 'Молочные продукты', 'Молочные продукты', 1, NULL);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (2, 'Молочные напитки и сливки', 'Молочные напитки и сливки', 1, 1);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (35, 'Молочные жиры и масла', 'Молочные жиры и масла', 1, 1);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (36, 'Сыры, продукты сырные и творог', 'Сыры, продукты сырные и творог', 1, 1);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (37, 'Молоко', 'Молоко', 1, 2);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (39, 'Масло сливочное', 'Масло сливочное', 1, 35);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (40, 'Пасты масляные', 'Пасты масляные', 1, 35);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (41, 'Масло топленое', 'Масло топленое', 1, 35);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (42, 'Сыры', 'Сыры', 1, 36);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (43, 'Творог', 'Творог', 1, 36);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (44, 'Продукты сыроделия прочие', 'Продукты сыроделия прочие', 1, 36);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (38, 'Сливки', 'Сливки', 1, 2);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (50, 'Enum', 'Перечисление', 1, NULL);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (51, 'ПерСтрок', 'Перечисление строк', 1, 50);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (52, 'ПерЧисел', 'Перечисление чисел', 1, 50);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (53, 'ПерИзобр', 'Перечисление изображений', 1, 50);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (54, 'ПерЦелых', 'Перечисление целых чисел', 1, 52);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (55, 'ПерВещ', 'Перечисление вещественных чисел', 1, 52);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (56, 'Упаковки', 'Перечисление видов упаковки', 1, 51);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (57, 'Объем тары', 'Объем тары', 2, 55);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (58, 'БазТип', 'Базовый тип', NULL, NULL);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (59, 'ЧислТип', 'Численный тип', NULL, 58);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (60, 'Integer', 'Integer', NULL, 59);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (61, 'Real', 'Real', NULL, 59);
INSERT INTO public.classification (id_class, short_name, name, id_unit, id_main_class) VALUES (62, 'String', 'String', NULL, 58);


--
-- TOC entry 3428 (class 0 OID 287066)
-- Dependencies: 224
-- Data for Name: par_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.par_class (id_par, id_class, min_val, max_val) VALUES (1, 1, 0, 1000);
INSERT INTO public.par_class (id_par, id_class, min_val, max_val) VALUES (3, 1, 0, 100);
INSERT INTO public.par_class (id_par, id_class, min_val, max_val) VALUES (5, 1, 0, 100);
INSERT INTO public.par_class (id_par, id_class, min_val, max_val) VALUES (4, 1, 0, 100);


--
-- TOC entry 3429 (class 0 OID 287083)
-- Dependencies: 225
-- Data for Name: par_prod; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (1, 1, NULL, 68, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (1, 2, NULL, 337, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (1, 3, NULL, 31, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (1, 5, NULL, 748, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (1, 4, NULL, 118, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (3, 1, NULL, 3, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (4, 1, NULL, 2.8, NULL, NULL);
INSERT INTO public.par_prod (id_par, id_product, val_int, val_real, val_str, val_enum) VALUES (5, 1, NULL, 4, NULL, NULL);


--
-- TOC entry 3427 (class 0 OID 287050)
-- Dependencies: 223
-- Data for Name: parameter; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.parameter (id_par, short_name, name, type_par, id_unit) VALUES (1, 'Калорийность', 'Калорийность на 100г', 61, 3);
INSERT INTO public.parameter (id_par, short_name, name, type_par, id_unit) VALUES (2, 'БЖУ', 'Состав белков, жиров и углеводов 100г', 61, 4);
INSERT INTO public.parameter (id_par, short_name, name, type_par, id_unit) VALUES (3, 'Белки', 'Количество белков на 100г', 61, 4);
INSERT INTO public.parameter (id_par, short_name, name, type_par, id_unit) VALUES (4, 'Жиры', 'Количество белков на 100г', 61, 4);
INSERT INTO public.parameter (id_par, short_name, name, type_par, id_unit) VALUES (5, 'Углеводы', 'Количество белков на 100г', 61, 4);


--
-- TOC entry 3430 (class 0 OID 287122)
-- Dependencies: 226
-- Data for Name: pos_agr; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pos_agr (id_agr, id_par, num) VALUES (2, 5, 3);
INSERT INTO public.pos_agr (id_agr, id_par, num) VALUES (2, 3, 1);
INSERT INTO public.pos_agr (id_agr, id_par, num) VALUES (2, 4, 2);


--
-- TOC entry 3425 (class 0 OID 286953)
-- Dependencies: 221
-- Data for Name: pos_enum; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (10, 56, 3, 'Коробка', 'Коробка', NULL, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (11, 56, 4, 'Пачка', 'Пачка', NULL, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (12, 57, 1, '0.5', '0.5', 0.5, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (13, 57, 2, '0.75', '0.75', 0.75, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (14, 57, 3, '1', '1', 1, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (15, 57, 4, '2', '2', 2, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (16, 57, 5, '2.5', '2.5', 2.5, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (17, 57, 6, '3', '3', 3, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (8, 56, 1, 'Бутылка', 'Бутылка', NULL, NULL, NULL);
INSERT INTO public.pos_enum (id_pos, id_enum, num, short_name, name, real_val, int_val, pic_val) VALUES (9, 56, 2, 'Пакет', 'Пакет', NULL, NULL, NULL);


--
-- TOC entry 3423 (class 0 OID 270648)
-- Dependencies: 219
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (2, 'Сливки 35%', 'Сливки 35%', 38);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (3, 'Обезжиренное молоко', 'Обезжиренное молоко', 37);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (4, 'Сливки 10%', 'Сливки 10%', 38);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (5, '"Ростагроэкспорт"', 'Сливочное масло "Ростагроэкспорт"', 39);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (6, '"Молочный двор"', 'Сивочное масло "Молочный двор"', 39);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (7, 'Фета', 'Фета', 40);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (8, 'Брынза', 'Брынза', 40);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (9, '"Алтайский край"', '"Алтайский край"', 41);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (10, '"Русский берег"', '"Русский берег"', 41);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (11, 'Чеддер', 'Чеддер', 42);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (12, 'Гауда', 'Гауда', 42);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (13, '"Домик в деревне"', '"Домик в деревне"', 43);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (14, '"Ростагроэкспорт"', '"Ростагроэкспорт"', 43);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (15, 'Моцарелла', 'Моцарелла', 44);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (16, 'Голландский сыр', 'Голландский сыр', 44);
INSERT INTO public.product (id_product, short_name, name, id_class) VALUES (1, 'Козье молоко', 'Козье молоко', 37);


--
-- TOC entry 3419 (class 0 OID 270624)
-- Dependencies: 215
-- Data for Name: unit; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.unit (id_unit, short_name, name, code) VALUES (1, 'шт', 'штука', 796);
INSERT INTO public.unit (id_unit, short_name, name, code) VALUES (2, 'л', 'литр', 112);
INSERT INTO public.unit (id_unit, short_name, name, code) VALUES (3, 'Ккал', 'Килокалория', 232);
INSERT INTO public.unit (id_unit, short_name, name, code) VALUES (4, 'г', 'Грамм', 163);


--
-- TOC entry 3442 (class 0 OID 0)
-- Dependencies: 216
-- Name: classification_id_class_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classification_id_class_seq', 62, true);


--
-- TOC entry 3443 (class 0 OID 0)
-- Dependencies: 222
-- Name: parameter_id_par_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parameter_id_par_seq', 5, true);


--
-- TOC entry 3444 (class 0 OID 0)
-- Dependencies: 220
-- Name: pos_enum_id_pos_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pos_enum_id_pos_seq', 17, true);


--
-- TOC entry 3445 (class 0 OID 0)
-- Dependencies: 218
-- Name: product_id_product_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_product_seq', 17, true);


--
-- TOC entry 3446 (class 0 OID 0)
-- Dependencies: 214
-- Name: unit_id_unit_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.unit_id_unit_seq', 4, true);


--
-- TOC entry 3249 (class 2606 OID 270636)
-- Name: classification classification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classification
    ADD CONSTRAINT classification_pkey PRIMARY KEY (id_class);


--
-- TOC entry 3257 (class 2606 OID 287072)
-- Name: par_class par_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_class
    ADD CONSTRAINT par_class_pkey PRIMARY KEY (id_par, id_class);


--
-- TOC entry 3259 (class 2606 OID 287089)
-- Name: par_prod par_prod_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_prod
    ADD CONSTRAINT par_prod_pkey PRIMARY KEY (id_par, id_product);


--
-- TOC entry 3255 (class 2606 OID 287055)
-- Name: parameter parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameter
    ADD CONSTRAINT parameter_pkey PRIMARY KEY (id_par);


--
-- TOC entry 3261 (class 2606 OID 287126)
-- Name: pos_agr pos_agr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_agr
    ADD CONSTRAINT pos_agr_pkey PRIMARY KEY (id_agr, id_par);


--
-- TOC entry 3253 (class 2606 OID 286960)
-- Name: pos_enum pos_enum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_enum
    ADD CONSTRAINT pos_enum_pkey PRIMARY KEY (id_pos);


--
-- TOC entry 3251 (class 2606 OID 270653)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id_product);


--
-- TOC entry 3245 (class 2606 OID 286951)
-- Name: unit unit_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit
    ADD CONSTRAINT unit_code_key UNIQUE (code);


--
-- TOC entry 3247 (class 2606 OID 270629)
-- Name: unit unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit
    ADD CONSTRAINT unit_pkey PRIMARY KEY (id_unit);


--
-- TOC entry 3275 (class 2620 OID 286967)
-- Name: classification del_class_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER del_class_trigger AFTER DELETE ON public.classification FOR EACH ROW EXECUTE FUNCTION public.del_pos_enum_trigger();


--
-- TOC entry 3262 (class 2606 OID 270642)
-- Name: classification classification_id_main_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classification
    ADD CONSTRAINT classification_id_main_class_fkey FOREIGN KEY (id_main_class) REFERENCES public.classification(id_class) ON DELETE RESTRICT;


--
-- TOC entry 3263 (class 2606 OID 270637)
-- Name: classification classification_id_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classification
    ADD CONSTRAINT classification_id_unit_fkey FOREIGN KEY (id_unit) REFERENCES public.unit(id_unit) ON DELETE SET NULL;


--
-- TOC entry 3268 (class 2606 OID 287078)
-- Name: par_class par_class_id_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_class
    ADD CONSTRAINT par_class_id_class_fkey FOREIGN KEY (id_class) REFERENCES public.classification(id_class) ON DELETE CASCADE;


--
-- TOC entry 3269 (class 2606 OID 287073)
-- Name: par_class par_class_id_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_class
    ADD CONSTRAINT par_class_id_par_fkey FOREIGN KEY (id_par) REFERENCES public.parameter(id_par) ON DELETE CASCADE;


--
-- TOC entry 3270 (class 2606 OID 287100)
-- Name: par_prod par_prod_enum_val_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_prod
    ADD CONSTRAINT par_prod_enum_val_fkey FOREIGN KEY (val_enum) REFERENCES public.pos_enum(id_pos);


--
-- TOC entry 3271 (class 2606 OID 287090)
-- Name: par_prod par_prod_id_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_prod
    ADD CONSTRAINT par_prod_id_par_fkey FOREIGN KEY (id_par) REFERENCES public.parameter(id_par) ON DELETE CASCADE;


--
-- TOC entry 3272 (class 2606 OID 287095)
-- Name: par_prod par_prod_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.par_prod
    ADD CONSTRAINT par_prod_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.product(id_product) ON DELETE CASCADE;


--
-- TOC entry 3266 (class 2606 OID 287061)
-- Name: parameter parameter_id_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameter
    ADD CONSTRAINT parameter_id_unit_fkey FOREIGN KEY (id_unit) REFERENCES public.unit(id_unit);


--
-- TOC entry 3267 (class 2606 OID 287056)
-- Name: parameter parameter_type_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameter
    ADD CONSTRAINT parameter_type_par_fkey FOREIGN KEY (type_par) REFERENCES public.classification(id_class) ON DELETE CASCADE;


--
-- TOC entry 3273 (class 2606 OID 287127)
-- Name: pos_agr pos_agr_id_agr_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_agr
    ADD CONSTRAINT pos_agr_id_agr_fkey FOREIGN KEY (id_agr) REFERENCES public.parameter(id_par) ON DELETE CASCADE;


--
-- TOC entry 3274 (class 2606 OID 287132)
-- Name: pos_agr pos_agr_id_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_agr
    ADD CONSTRAINT pos_agr_id_par_fkey FOREIGN KEY (id_par) REFERENCES public.parameter(id_par) ON DELETE CASCADE;


--
-- TOC entry 3265 (class 2606 OID 286961)
-- Name: pos_enum pos_enum_id_enum_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pos_enum
    ADD CONSTRAINT pos_enum_id_enum_fkey FOREIGN KEY (id_enum) REFERENCES public.classification(id_class);


--
-- TOC entry 3264 (class 2606 OID 270654)
-- Name: product product_id_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_id_class_fkey FOREIGN KEY (id_class) REFERENCES public.classification(id_class) ON DELETE CASCADE;


-- Completed on 2024-05-26 15:12:23

--
-- PostgreSQL database dump complete
--

