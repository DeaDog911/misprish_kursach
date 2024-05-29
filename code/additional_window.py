from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QLineEdit, QPushButton, QTableWidget, QTableWidgetItem

from code.database_dao import DatabaseDAO


class FindWindow(QDialog):
    """Окно для поиска потомков класса."""

    def __init__(self, db_dao: DatabaseDAO, mode: str):
        """
        Конструктор класса.

        Параметры:
        - db_dao (DatabaseDAO): Объект для работы с базой данных.
        """
        super().__init__()

        self.db_dao = db_dao

        match mode:
            case 'parents':
                title = 'Найти родителей класса'
            case 'children':
                title = 'Найти потомков класса'
        self.setWindowTitle(title)
        self.setFixedSize(600, 500)

        self.layout = QVBoxLayout()

        label_id = QLabel("Введите ID класса:")
        self.layout.addWidget(label_id)

        self.id_field = QLineEdit()
        self.layout.addWidget(self.id_field)

        find_button = QPushButton("Найти")
        match mode:
            case 'parents':
                find_button.clicked.connect(self.find_parents)
            case 'children':
                find_button.clicked.connect(self.find_children)

        self.layout.addWidget(find_button)

        self.result_table = QTableWidget()
        self.layout.addWidget(self.result_table)

        self.setLayout(self.layout)

        self.setStyleSheet("""
            QDialog {
                background-color: lightblue;
            }
            QLabel {
                color: black;
                font-size: 12pt;
            }
            QLineEdit {
                background-color: white;
                color: black;
                font-size: 12pt;
                border: 2px solid black;
                border-radius: 5px;
                padding: 5px;
            }
            QPushButton {
                background-color: white;
                color: black;
                font-size: 12pt;
                border: 2px solid black;
                border-radius: 5px;
                padding: 5px 10px;
            }
            QPushButton:hover {
                background: qlineargradient(
                    x1: 0, y1: 0, x2: 0, y2: 1,
                    stop: 0 black, stop: 1 #333333
                );
                color: white;
            }
            QTableWidget {
                background-color: white;
                color: black;
                font-size: 12pt;
                border: 2px solid black;
                border-radius: 5px;
            }
        """)

    def find_children(self):
        """Ищет потомков класса в базе данных."""
        class_id = self.id_field.text()
        results = self.db_dao.find_children(class_id)
        self.result_table.setRowCount(len(results))
        self.result_table.setColumnCount(2)
        self.result_table.setHorizontalHeaderLabels(["ID", "Name"])
        for row_idx, row_data in enumerate(results):
            self.result_table.setItem(row_idx, 0, QTableWidgetItem(str(row_data[0])))
            self.result_table.setItem(row_idx, 1, QTableWidgetItem(row_data[1]))

    def find_parents(self):
        """Ищет родителей класса"""
        class_id = self.id_field.text()
        results = self.db_dao.find_parents(class_id)
        self.result_table.setRowCount(len(results))
        self.result_table.setColumnCount(2)
        self.result_table.setHorizontalHeaderLabels(["ID", "Name"])
        for row_idx, row_data in enumerate(results):
            self.result_table.setItem(row_idx, 0, QTableWidgetItem(str(row_data[0])))
            self.result_table.setItem(row_idx, 1, QTableWidgetItem(row_data[1]))
