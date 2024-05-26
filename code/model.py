import psycopg2

class Database:
    def __init__(self, dbname, user, password, host, port):
        self.conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        self.cur = self.conn.cursor()

    def execute_query(self, query):
        self.cur.execute(query)
        return self.cur.fetchall()

    def close_connection(self):
        self.cur.close()
        self.conn.close()
