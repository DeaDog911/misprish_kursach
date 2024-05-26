import psycopg2

# Подключение к базе данных
conn = psycopg2.connect(
    dbname="mispris3",
    user="postgres",
    password="1",
    host="localhost",
    port="5432"
)

# Создание курсора для выполнения запросов
cur = conn.cursor()

# Выполнение запроса на получение названий таблиц в схеме "public"
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")

# Получение результатов запроса
table_names = cur.fetchall()

# Вывод названий таблиц
print("Названия таблиц в схеме 'public':", *table_names)


# Закрытие курсора и соединения
cur.close()
conn.close()
