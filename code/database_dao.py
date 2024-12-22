import configparser
import traceback

import psycopg2
import json

from PyQt5.QtWidgets import QPushButton


class DatabaseDAO:
    """Data Access Object для работы с базой данных PostgreSQL."""

    def __init__(self, config_file: str, queries_file: str):
        """
        Конструктор класса.

        Параметры:
        - config_file (str): Путь к файлу конфигурации базы данных.
        - queries_file (str): Путь к файлу с SQL-запросами.
        """
        self.config = self._load_config(config_file)
        self.queries = self._load_queries(queries_file)
        self.connection = self._connect()
        self.cur = self.connection.cursor()

    def _load_config(self, config_file: str) -> dict:
        """Загружает конфигурацию базы данных из файла."""
        config = configparser.ConfigParser()
        config.read(config_file)
        return config['postgresql']

    def _load_queries(self, queries_file: str) -> dict:
        """Загружает SQL-запросы из файла."""
        with open(queries_file, 'r') as file:
            return json.load(file)

    def _connect(self):
        """Устанавливает соединение с базой данных."""
        return psycopg2.connect(
            dbname=self.config['dbname'],
            user=self.config['user'],
            password=self.config['password'],
            host=self.config['host'],
            port=self.config['port']
        )

    def execute_query(self, query_key: str, params=None) -> list:
        """
        Выполняет SQL-запрос и возвращает результат.

        Параметры:
        - query_key (str): Ключ запроса в файле queries.json.
        - params (tuple): Параметры запроса (если есть).

        Возвращает:
        - list: Результат выполнения запроса.
        """
        query = self.queries[query_key].format(**(params or {}))
        self.cur.execute(query)
        return self.cur.fetchall()

    def close(self):
        """Закрывает соединение с базой данных."""
        self.cur.close()
        self.connection.close()

    def get_all_from_table(self, table_name):
        query = f"SELECT * FROM {table_name}"
        try:
            self.cur.execute(query)
            return self.cur.fetchall()
        except Exception as e:
            print(e)
            print("name:", table_name)

    def insert_data_into_table(self, table_name, data):
        """Вставляет данные в указанную таблицу."""
        if table_name == "classification":
            query = f"""
            SELECT create_class (%s, %s, %s, %s);
            """
            values = (data["short_name"], data["name"], data["id_unit"], data["id_main_class"])
        elif table_name == "product":
            query = """
            SELECT create_product (%s, %s, %s, %s, %s, %s);
            """
            values = (
            data["short_name"], data["name"], data["id_class"], data["id_unit"], data["price"], data["base_id_product"])
        elif table_name == "unit":
            query = """
            SELECT create_unit (%s, %s, %s);
            """
            values = (data["short_name"], data["name"], data["code"])
        elif table_name == "spec_position":
            query = """
            SELECT create_spec_position (%s, %s, %s);
            """
            values = (data["id_product_input"], data["id_part_input"],data["quantity"])
        else:
            raise ValueError(f"Неизвестная таблица: {table_name}")
        try:
            self.cur.execute(query, values)
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    def delete_data_from_table(self, table_name, record_id):
        """Удаляет данные из указанной таблицы по ID."""
        if table_name == "classification":
            query = "SELECT delete_class(%s);"
        elif table_name == "product":
            query = "SELECT delete_product(%s);"
        elif table_name == "unit":
            query = "SELECT delete_unit(%s);"
        elif table_name == "spec_position":
            query = "SELECT delete_spec_position(%s);"
        else:
            raise ValueError(f"Неизвестная таблица: {table_name}")

        try:
            self.cur.execute(query, (record_id,))
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    def find_children(self, class_id):
        """Ищет потомков класса в базе данных."""
        query = """
        SELECT * FROM find_children(%s);
        """
        self.cur.execute(query, (class_id,))
        results = self.cur.fetchall()
        return results

    def find_parents(self, class_id):
        """Ищет родителей класса в базе данных."""
        query = """
        SELECT * FROM find_parents(%s);
        """
        self.cur.execute(query, (class_id,))
        results = self.cur.fetchall()
        return results

    def show_tree(self):
        """Отображает дерево классификации."""
        query = """
        SELECT * FROM show_tree();
        """
        self.cur.execute(query)
        results = self.cur.fetchall()
        return results

    def find_products(self, class_id):
        query = f"""
                SELECT * FROM find_products(array[{class_id}]);
                """
        try:
            self.cur.execute(query)
            results = self.cur.fetchall()
        except Exception as e:
            print(e)
            return []
        return results

    def change_product_class(self, change_id_product: int, new_id_class: int):
        """Изменяет класс продукта."""
        query = """
        SELECT change_product_class(%s, %s);
        """
        try:
            self.cur.execute(query, (change_id_product, new_id_class))
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    def change_parent_class(self, child_id_class: int, new_parent_id_class: int):
        """Изменяет родителя указанного класса."""
        query = """
        SELECT change_parent_class(%s, %s);
        """
        try:
            self.cur.execute(query, (child_id_class, new_parent_id_class))
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    def insert_spec_position(self, id_product: int, quantity: float):
        """Вставляет новую позицию спецификации."""
        query = """
        SELECT create_spec_position(%s, %s);
        """
        try:
            self.cur.execute(query, (id_product, quantity))
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    def delete_spec_position(self, id_position: int):
        """Удаляет позицию спецификации по ID."""
        query = """
        SELECT delete_spec_position(%s);
        """
        try:
            self.cur.execute(query, (id_position,))
            self.connection.commit()
        except Exception as e:
            self.connection.rollback()
            raise e

    import traceback

    def calculate_component_quantities(self):
        """Выполняет подсчет сводных норм и возвращает результат."""
        try:
            query = "SELECT * FROM calculate_component_quantities(%s);"  # Подставим параметры (например, 1)
            self.cur.execute(query, (1,))
            results = self.cur.fetchall()
            return results
        except Exception as e:
            print("Ошибка при подсчете сводных норм:", e)
            print("Трассировка ошибки:", traceback.format_exc())
            self.connection.rollback()  # Откат транзакции
            self.connection.rollback()
            return []

    def show_spec_structure(self):
        """Отображает структуру спецификации."""
        try:
            # Получаем все данные из таблицы спецификаций
            results = self.get_all_from_table("spec_position")

            # Если результаты не пусты, возвращаем их для отображения
            if results:
                column_names = ["ID продукта", "ID части", "Количество"]  # Пример названий колонок
                return results, column_names
            else:
                return [], []  # Возвращаем пустые данные и столбцы, если результатов нет
        except Exception as e:
            print("Ошибка при получении структуры спецификации:", e)
            return [], []  # В случае ошибки возвращаем пустые данные

