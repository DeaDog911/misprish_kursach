from PyQt5.QtWidgets import QMainWindow, QVBoxLayout, QWidget, QTableWidgetItem, QTableWidget
from PyQt5.QtGui import QFont

class TableView(QWidget):
    def __init__(self,data):
        super().__init__()

        self.layout = QVBoxLayout()
        self.setLayout(self.layout)

        self.table_widget = QTableWidget()
        self.table_widget.setStyleSheet("QTableWidget { font-family: Arial; font-size: 12pt; }")  # Настройка шрифта
        self.layout.addWidget(self.table_widget)

    def update_data(self, data, column_names=None):
        if not data:
            return

        num_rows = len(data)
        num_cols = len(data[0])

        self.table_widget.setRowCount(num_rows)
        self.table_widget.setColumnCount(num_cols)

        # Установка заголовков столбцов
        if column_names:
            self.table_widget.setHorizontalHeaderLabels(column_names)

        # Вывод данных в таблицу
        for row_idx, row_data in enumerate(data):
            for col_idx, cell_data in enumerate(row_data):
                item = QTableWidgetItem(str(cell_data))
                self.table_widget.setItem(row_idx, col_idx, item)
