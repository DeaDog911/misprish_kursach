from PyQt5.QtCore import pyqtSignal
from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QLineEdit, QPushButton, QMessageBox

from code.database_dao import DatabaseDAO

class DeleteWindow(QDialog):
    """Окно для удаления записей из базы данных."""

    record_deleted = pyqtSignal()
    def __init__(self, current_table: str, db_dao: DatabaseDAO):
        """
        Конструктор класса.

        Параметры:
        - current_table (str): Название текущей таблицы.
        - db_dao (DatabaseDAO): Объект для работы с базой данных.
        """
        super().__init__()

        self.db_dao = db_dao
        self.current_table = current_table

        self.setWindowTitle("Удалить запись")
        self.setFixedSize(400, 200)

        self.layout = QVBoxLayout()

        # Отображаем название текущей таблицы
        label_table = QLabel(f"Таблица: {self.current_table}")
        self.layout.addWidget(label_table)

        # Поле для ввода ID записи
        label_id = QLabel("Введите ID записи:")
        self.layout.addWidget(label_id)

        self.id_field = QLineEdit()
        self.layout.addWidget(self.id_field)

        # Кнопка для удаления записи
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
        """)

    def delete_record(self):
        """Удаляет запись из базы данных."""
        record_id = self.id_field.text()
        if record_id == "":
            QMessageBox.warning(self, "Предупреждение", "ID записи не может быть пустым")
            return
        try:
            self.db_dao.delete_data_from_table(self.current_table, record_id)
            QMessageBox.information(self, "Успех", "Запись удалена успешно")
            self.record_deleted.emit()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось удалить запись: {str(e)}")
        self.accept()
