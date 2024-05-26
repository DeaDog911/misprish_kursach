import psycopg2


class Database:
    """Класс для работы с базой данных PostgreSQL."""

    def __init__(self, dbname: str, user: str, password: str, host: str, port: int):
        """
        Конструктор класса.

        Параметры:
        - dbname (str): Имя базы данных.
        - user (str): Имя пользователя базы данных.
        - password (str): Пароль пользователя базы данных.
        - host (str): Хост базы данных.
        - port (int): Порт базы данных.
        """
        self.conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host, port=port)
        self.cur = self.conn.cursor()

    def execute_query(self, query: str, params=None):
        """
        Выполняет SQL-запрос к базе данных.

        Параметры:
        - query (str): SQL-запрос.
        - params (tuple, опционально): Параметры запроса.

        Возвращает:
        tuple: Результат выполнения запроса или None, если запрос не возвращает результат.
        """
        self.cur.execute(query, params)
        self.conn.commit()
        try:
            return self.cur.fetchall()
        except psycopg2.ProgrammingError:
            return None

    def __del__(self):
        """Деструктор класса, закрывает соединение с базой данных."""
        self.cur.close()
        self.conn.close()
