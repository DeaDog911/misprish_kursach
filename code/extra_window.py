from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QPushButton, QLineEdit
from PyQt5.QtCore import Qt

class AddWindow(QDialog):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Добавить запись")
        self.setFixedSize(300, 150)  # Фиксированный размер окна

        layout = QVBoxLayout()

        label = QLabel("Введите данные:")
        layout.addWidget(label)

        # Добавляем пример поля ввода
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
        """)

    def add_record(self):
        # Здесь вы можете написать код для добавления записи в базу данных
        pass
