from PyQt5.QtWidgets import QWidget, QVBoxLayout
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

        self.view = TableView(self.central_widget)
        self.layout.addWidget(self.view)

        self.update_view()

    def get_data(self):
        # Пример запроса на получение данных из таблицы
        result = self.db.execute_query("SELECT * FROM product")
        return result

    def update_view(self):
        new_data = self.get_data()
        self.view.update_data(new_data)
