from PyQt5.QtWidgets import QWidget, QVBoxLayout, QPushButton, QApplication, QScrollArea
from code.model import Database
from code.view import TableView


class Controller:
    def __init__(self, root):
        self.root = root
        root.resize(800, 600)
        self.db = Database(dbname="mispris3",
                           user="postgres",
                           password="1",
                           host="localhost",
                           port="5432")

        self.central_widget = QWidget()
        self.layout = QVBoxLayout(self.central_widget)
        self.root.setCentralWidget(self.central_widget)

        self.scroll_area = QScrollArea(self.central_widget)
        self.layout.addWidget(self.scroll_area)

        self.inner_widget = QWidget()
        self.inner_layout = QVBoxLayout(self.inner_widget)

        self.scroll_area.setWidget(self.inner_widget)
        self.scroll_area.setWidgetResizable(True)

        self.view = TableView(self.inner_widget)
        self.inner_layout.addWidget(self.view)

        self.buttons = []

        # Создаем кнопки для каждой таблицы
        self.create_table_buttons()

        self.update_view()

    def create_table_buttons(self):
        table_names = self.get_table_names()
        for name in table_names:
            button = QPushButton(name[0], self.central_widget)
            button.clicked.connect(lambda _, table=name[0]: self.show_table_data(table))
            self.buttons.append(button)
            self.layout.addWidget(button)

    def get_table_names(self):
        # SQL-запрос для получения названий всех таблиц в схеме "public"
        sql_query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
        return self.db.execute_query(sql_query)

    def show_table_data(self, table_name):
        sql_query = f"SELECT * FROM {table_name}"
        result = self.db.execute_query(sql_query)
        self.view.update_data(result)

    def update_view(self):
        # По умолчанию показываем данные из первой таблицы
        table_name = self.get_table_names()[0][0]
        self.show_table_data(table_name)