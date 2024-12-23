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
            case 'products':
                title = 'Найти продукты класса'
            case 'changes':
                title = 'Найти изменения'
        self.setWindowTitle(title)
        self.setFixedSize(600, 500)

        self.layout = QVBoxLayout()

        if (mode != 'changes'):
            label_id = QLabel("Введите ID класса:")
        else:
            label_id = QLabel("Введите Base Id продукта:")
        self.layout.addWidget(label_id)

        self.id_field = QLineEdit()
        self.layout.addWidget(self.id_field)

        find_button = QPushButton("Найти")
        match mode:
            case 'parents':
                find_button.clicked.connect(self.find_parents)
            case 'children':
                find_button.clicked.connect(self.find_children)
            case 'products':
                find_button.clicked.connect(self.find_products)
            case 'changes':
                find_button.clicked.connect(self.find_changes)

        self.layout.addWidget(find_button)
        self.result_table = QTableWidget()
        self.layout.addWidget(self.result_table)

        self.setLayout(self.layout)

        self.setStyleSheet("""
            QDialog {
                background-color: #f7f9fc;
                border: 1px solid #d9d9d9;
                border-radius: 10px;
            }
            QLabel {
                color: #333333;
                font-size: 14px;
                font-weight: bold;
            }
            QLineEdit {
                background-color: #ffffff;
                color: #333333;
                font-size: 12px;
                border: 1px solid #a6a6a6;
                border-radius: 5px;
                padding: 6px;
            }
            QPushButton {
                background-color: #0078d7;
                color: #ffffff;
                font-size: 12px;
                font-weight: bold;
                border: none;
                border-radius: 5px;
                padding: 8px 12px;
            }
            QPushButton:hover {
                background-color: #005bb5;
            }
            QPushButton:pressed {
                background-color: #003f7f;
            }
            QTableWidget {
                background-color: #ffffff;
                color: #333333;
                font-size: 12px;
                border: 1px solid #a6a6a6;
                border-radius: 5px;
                gridline-color: #d9d9d9;
            }
            QTableWidget::item {
                padding: 5px;
            }
            QTableWidget::horizontalHeader {
                background-color: #f0f0f0;
                color: #333333;
                font-weight: bold;
            }
            QTableWidget::verticalHeader {
                background-color: #f0f0f0;
                color: #333333;
                font-weight: bold;
            }
            QTableWidget::item:selected {
                background-color: #0078d7;
                color: white;
            }
        """)

    def find_children(self):
        """Ищет потомков класса в базе данных."""
        class_id = self.id_field.text()
        if class_id == "":
            return
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
        if class_id == "":
            return
        results = self.db_dao.find_parents(class_id)
        self.result_table.setRowCount(len(results))
        self.result_table.setColumnCount(2)
        self.result_table.setHorizontalHeaderLabels(["ID", "Name"])
        for row_idx, row_data in enumerate(results):
            self.result_table.setItem(row_idx, 0, QTableWidgetItem(str(row_data[0])))
            self.result_table.setItem(row_idx, 1, QTableWidgetItem(row_data[1]))


    def find_changes(self):
        """Ищет изменения продукта"""
        base_product_id = self.id_field.text()
        if base_product_id == "":
            return
        results = self.db_dao.get_product_version(base_product_id)
        self.result_table.setRowCount(len(results))
        self.result_table.setColumnCount(4)
        self.result_table.setHorizontalHeaderLabels(["ID product", "Short name", "name", "Base Id product"])
        for row_idx, row_data in enumerate(results):
            self.result_table.setItem(row_idx, 0, QTableWidgetItem(str(row_data[0])))
            self.result_table.setItem(row_idx, 1, QTableWidgetItem(row_data[1]))
            self.result_table.setItem(row_idx, 2, QTableWidgetItem(row_data[2]))
            self.result_table.setItem(row_idx, 3, QTableWidgetItem(str(row_data[3])))

    def find_products(self):
        """Ищет продукты класса"""
        class_id = self.id_field.text()
        if class_id == "":
            return
        results = self.db_dao.find_products(class_id)
        self.result_table.setRowCount(len(results))
        self.result_table.setColumnCount(4)
        self.result_table.setHorizontalHeaderLabels(["ID class", "Class short name", "ID Product", "Product short name"])
        for row_idx, row_data in enumerate(results):
            self.result_table.setItem(row_idx, 0, QTableWidgetItem(str(row_data[0])))
            self.result_table.setItem(row_idx, 1, QTableWidgetItem(row_data[1]))
            self.result_table.setItem(row_idx, 2, QTableWidgetItem(str(row_data[2])))
            self.result_table.setItem(row_idx, 3, QTableWidgetItem(row_data[3]))
