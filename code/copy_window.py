from PyQt5.QtCore import pyqtSignal
from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QPushButton, QLineEdit, QMessageBox
from code.database_dao import DatabaseDAO


class CopyWindow(QDialog):
    """Окно для добавления записей в базу данных."""

    record_copy = pyqtSignal()

    def __init__(self, table_name: str, db_dao: DatabaseDAO):
        """
        Конструктор класса.

        Параметры:
        - table_names (list): Список имен таблиц.
        - db_dao (DatabaseDAO): Объект для работы с базой данных.
        """
        super().__init__()

        self.db_dao = db_dao
        self.table_name = table_name
        self.fields = {}
        self.setWindowTitle("Скопировать спецификацию")
        self.setFixedSize(500, 550)

        self.layout = QVBoxLayout()

        label_table = QLabel(f"Таблица: {self.table_name}")
        self.layout.addWidget(label_table)

        self.fields_layout = QVBoxLayout()
        self.layout.addLayout(self.fields_layout)

        self.update_fields()

        add_button = QPushButton("Скопировать")
        add_button.clicked.connect(self.add_record)
        self.layout.addWidget(add_button)

        self.setLayout(self.layout)

        self.setStyleSheet("""
            QDialog {
                background-color: #f7f9fc;
                border: 1px solid #d9d9d9;
                border-radius: 10px;
                padding: 20px;
            }
            QLabel {
                color: #333333;
                font-size: 14px;
                font-weight: bold;
                margin-bottom: 8px;
            }
            QComboBox, QLineEdit {
                background-color: #ffffff;
                color: #333333;
                font-size: 12px;
                border: 1px solid #a6a6a6;
                border-radius: 5px;
                padding: 6px;
                height: 30px;
            }
            QComboBox::drop-down {
                border: none;
            }
            QComboBox QAbstractItemView {
                background-color: #ffffff;
                border: 1px solid #d9d9d9;
                selection-background-color: #0078d7;
                selection-color: white;
            }
            QPushButton {
                background-color: #0078d7;
                color: white;
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
        """)

    def update_fields(self):
        if self.table_name == "spec_position":
            columns = ["source_product_id", "target_product_id"]
        else:
            columns = []

        for column in columns:
            label = QLabel(column)
            line_edit = QLineEdit()
            line_edit.setFixedHeight(35)
            self.fields[column] = line_edit
            self.fields_layout.addWidget(label)
            self.fields_layout.addWidget(line_edit)

    def add_record(self):
        data = {column: self.fields[column].text().strip() for column in self.fields}
        try:
            print(data)
            self.db_dao.copy_spec(data)
            QMessageBox.information(self, "Успех", f"Запись успешно скопирована в таблицу spec_position.")
            self.record_copy.emit()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось добавить запись: {str(e)}")
        self.accept()
