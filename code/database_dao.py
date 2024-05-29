import configparser

import psycopg2
import json

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
            SELECT create_product (%s, %s, %s);
            """
            values = (data["short_name"], data["name"], data["id_class"])
        elif table_name == "unit":
            query = """
            SELECT create_unit (%s, %s, %s);
            """
            values = (data["short_name"], data["name"], data["code"])
        else:
            raise ValueError(f"Неизвестная таблица: {table_name}")
        try:
            self.cur.execute(query, values)
            self.connection.commit()
        except Exception as e:
            self.connection.commit()
            raise e

    def delete_data_from_table(self, table_name, record_id):
        """Удаляет данные из указанной таблицы по ID."""
        if table_name == "classification":
            query = "SELECT delete_class(%s);"
        elif table_name == "product":
            query = "SELECT delete_product(%s);"
        elif table_name == "unit":
            query = "SELECT delete_unit(%s)"
        else:
            raise ValueError(f"Неизвестная таблица: {table_name}")

        try:
            self.cur.execute(query, (record_id,))
            self.connection.commit()
        except Exception as e:
            self.connection.commit()
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
        """Ищет потомков класса в базе данных."""
        query = """
        SELECT * FROM find_parents(%s);
        """
        self.cur.execute(query, (class_id,))
        results = self.cur.fetchall()
        return results

    def show_tree(self):
        """Ищет потомков класса в базе данных."""
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
        return results

    def change_product_class(self, change_id_product: int, new_id_class: int):
        """Изменяет класс продукта."""
        query = f"""
        SELECT change_product_class({change_id_product},{new_id_class});
        """
        self.cur.execute(query)
        self.connection.commit()

    def change_parent_class(self, child_id_class: int, new_parent_id_class: int):
        """Изменяет родителя указанного класса."""
        query = f"""
                SELECT change_parent_class({child_id_class},{new_parent_id_class});
                """
        self.cur.execute(query)
        self.connection.commit()
