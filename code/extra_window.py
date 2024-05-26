from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QPushButton, QLineEdit, QComboBox, QMessageBox
from PyQt5.QtCore import Qt
from code.model import Database

class AddWindow(QDialog):
    """Окно для добавления записей в базу данных."""

    def __init__(self, table_names: list, db: Database):
        """
        Конструктор класса.

        Параметры:
        - table_names (list): Список имен таблиц.
        - db (Database): Объект для работы с базой данных.
        """
        super().__init__()

        self.db = db

        self.setWindowTitle("Добавить запись")
        self.setFixedSize(400, 250)  # Фиксированный размер окна

        layout = QVBoxLayout()

        label_table = QLabel("Выберите таблицу:")
        layout.addWidget(label_table)

        self.table_selector = QComboBox()
        layout.addWidget(self.table_selector)

        # Добавляем таблицы в комбобокс
        for name in table_names:
            table_name = name[0] if isinstance(name, tuple) else name
            self.table_selector.addItem(table_name)

        label_data = QLabel("Введите данные (через запятую):")
        layout.addWidget(label_data)

        # Добавляем поле для ввода данных
        self.input_field = QLineEdit()
        layout.addWidget(self.input_field)

        # Кнопка для добавления записи
        add_button = QPushButton("Добавить")
        add_button.clicked.connect(self.add_record)
        layout.addWidget(add_button)

        self.setLayout(layout)

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

    def add_record(self):
        selected_table = self.table_selector.currentText()
        input_data = self.input_field.text().strip()
        # Разделяем вводимые данные по запятым
        data_list = [item.strip() for item in input_data.split(',')]

        # Получаем имена и типы столбцов для выбранной таблицы
        column_info = self.get_column_info(selected_table)
        column_names = [col[0] for col in column_info]
        column_types = [col[1] for col in column_info]

        if len(data_list) != len(column_names):
            # Вывести сообщение об ошибке если количество введенных данных не соответствует количеству столбцов
            QMessageBox.critical(self, "Ошибка", f"Ожидается {len(column_names)} значений, получено {len(data_list)}.")
            return

        # Преобразуем данные в соответствии с типами столбцов
        try:
            data_list = self.convert_data_types(data_list, column_types)
        except ValueError as e:
            QMessageBox.critical(self, "Ошибка", str(e))
            return

        # Формируем SQL-запрос для вставки данных
        columns = ', '.join(column_names)
        placeholders = ', '.join(['%s'] * len(data_list))
        sql_query = f"INSERT INTO {selected_table} ({columns}) VALUES ({placeholders})"

        try:
            print(f"Executing SQL: {sql_query} with data: {data_list}")  # Отладочная информация
            self.db.execute_query(sql_query, tuple(data_list))
            QMessageBox.information(self, "Успех", f"Запись успешно добавлена в таблицу {selected_table}.")
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Ошибка при добавлении записи: {e}")
            print(f"Ошибка при выполнении запроса: {e}")

    def get_column_info(self, table_name: str):
        """Получает информацию о столбцах выбранной таблицы."""
        # SQL-запрос для получения имен и типов столбцов таблицы
        sql_query = f"""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = '{table_name}';
        """
        return self.db.execute_query(sql_query)

    def convert_data_types(self, data_list: list, column_types: list):
        """Преобразует данные в соответствии с типами столбцов."""
        converted_data = []
        for data, col_type in zip(data_list, column_types):
            if col_type in ['integer', 'smallint', 'bigint']:
                try:
                    converted_data.append(int(data))
                except ValueError:
                    raise ValueError(f"Значение '{data}' не является корректным числом для столбца типа {col_type}.")
            elif col_type in ['numeric', 'decimal', 'real', 'double precision']:
                try:
                    converted_data.append(float(data))
                except ValueError:
                    raise ValueError(
                        f"Значение '{data}' не является корректным числом с плавающей точкой для столбца типа {col_type}.")
            elif col_type in ['boolean']:
                if data.lower() in ['true', 'false']:
                    converted_data.append(data.lower() == 'true')
                else:
                    raise ValueError(
                        f"Значение '{data}' не является корректным булевым значением для столбца типа {col_type}.")
            else:
                # Для строковых и других типов данных
                converted_data.append(data)
        return converted_data
