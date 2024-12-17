from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QComboBox, QLineEdit, QPushButton, QMessageBox

from code.database_dao import DatabaseDAO


class DeleteWindow(QDialog):
    """Окно для удаления записей из базы данных."""

    def __init__(self, table_names: list, db_dao: DatabaseDAO):
        """
        Конструктор класса.

        Параметры:
        - table_names (list): Список имен таблиц.
        - db_dao (DatabaseDAO): Объект для работы с базой данных.
        """
        super().__init__()

        self.db_dao = db_dao

        self.setWindowTitle("Удалить запись")
        self.setFixedSize(400, 200)

        self.table_names = table_names

        self.layout = QVBoxLayout()

        label_table = QLabel("Выберите таблицу:")
        self.layout.addWidget(label_table)

        self.table_selector = QComboBox()
        self.table_selector.addItems(table_names)
        self.layout.addWidget(self.table_selector)

        label_id = QLabel("Введите ID записи:")
        self.layout.addWidget(label_id)

        self.id_field = QLineEdit()
        self.layout.addWidget(self.id_field)

        delete_button = QPushButton("Удалить")
        delete_button.clicked.connect(self.delete_record)
        self.layout.addWidget(delete_button)

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
            QComboBox, QLineEdit {
                background-color: #ffffff;
                color: #333333;
                font-size: 12px;
                border: 1px solid #a6a6a6;
                border-radius: 5px;
                padding: 6px;
            }
            QComboBox::drop-down {
                border: none;
            }
            QComboBox QAbstractItemView {
                background-color: #ffffff;
                border: 1px solid #d9d9d9;
                selection-background-color: #0078d7;
                selection-color: #ffffff;
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
        """)

    def delete_record(self):
        """Удаляет запись из базы данных."""
        selected_table = self.table_selector.currentText()
        record_id = self.id_field.text()
        if record_id == "":
            return
        try:
            self.db_dao.delete_data_from_table(selected_table, record_id)
            QMessageBox.information(self, "Успех", "Запись удалена успешно")
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось удалить запись: {str(e)}")
        self.accept()
