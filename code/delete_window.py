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
                background-color: lightblue;
            }
            QLabel {
                color: black;
                font-size: 12pt;
            }
            QComboBox, QLineEdit {
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
