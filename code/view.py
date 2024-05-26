from PyQt5.QtWidgets import QMainWindow, QLabel, QVBoxLayout, QWidget
from PyQt5.QtGui import QFont

class TableView(QWidget):
    def __init__(self,data):
        super().__init__()

        self.layout = QVBoxLayout()
        self.setLayout(self.layout)

        self.label = QLabel()
        self.label.setStyleSheet("QLabel { font-family: Arial; font-size: 12pt; }")  # Настройка шрифта
        self.layout.addWidget(self.label)

    def update_data(self, new_data):
        formatted_data = "<br>".join(str(row) for row in new_data)  # Форматированный вывод в столбец
        self.label.setText(f"<html>{formatted_data}</html>")
