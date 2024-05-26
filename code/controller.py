from PyQt5.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QApplication, QScrollArea, QGridLayout, QMainWindow
from code.model import Database
from code.view import TableView


class Controller:
    def __init__(self, root):
        self.root = root
        root.resize(800, 600)
        self.db = Database(dbname="mispris3",
                           user="postgres",
                           password="1",
                           host="localhost",
                           port="5432")

        self.central_widget = QWidget()
        self.central_widget.setStyleSheet("background-color: lightblue;")

        self.layout = QVBoxLayout(self.central_widget)
        self.root.setCentralWidget(self.central_widget)

        self.scroll_area = QScrollArea(self.central_widget)
        self.scroll_area.verticalScrollBar().setStyleSheet(
            """
            QScrollBar:vertical {
                background: #f1f1f1;
                width: 10px; /* Толщина скроллбара */
                margin: 0px 0px 0px 0px; /* Расположение скроллбара */
                border: 2px solid black; /* Черная рамка */
            }

            QScrollBar::handle:vertical {
                background: #888;
                min-height: 20px;
            }

            QScrollBar::add-line:vertical {
                subcontrol-origin: margin;
                subcontrol-position: bottom;
                height: 0px;
                width: 0px;
            }

            QScrollBar::sub-line:vertical {
                subcontrol-origin: margin;
                subcontrol-position: top;
                height: 0px;
                width: 0px;
            }
            """
        )
        self.layout.addWidget(self.scroll_area)

        self.inner_widget = QWidget()
        self.inner_widget.setStyleSheet("background-color: white;")
        self.inner_layout = QVBoxLayout(self.inner_widget)

        self.scroll_area.setWidget(self.inner_widget)
        self.scroll_area.setWidgetResizable(True)

        self.view = TableView(self.inner_widget)
        self.inner_layout.addWidget(self.view)

        self.button_layout = QGridLayout()  # Используем QGridLayout для кнопок
        self.layout.addLayout(self.button_layout)  # Добавляем макет кнопок в основной макет

        self.buttons = []

        # Создаем кнопки для каждой таблицы
        self.create_table_buttons()

        self.update_view()

    def create_table_buttons(self):
        table_names = self.get_table_names()
        row, col = 0, 0
        for name in table_names:
            button = QPushButton(name[0], self.central_widget)
            button.clicked.connect(lambda _, table=name[0]: self.show_table_data(table))
            self.style_button(button)  # Применяем стиль к кнопке
            self.buttons.append(button)
            self.button_layout.addWidget(button, row, col)  # Добавляем кнопку в сетку
            col += 1
            if col > 2:  # Меняем расположение кнопок в три столбца
                col = 0
                row += 1

    def style_button(self, button):
        button.setStyleSheet("""
            QPushButton {
                background-color: white;
                color: black;
                font-weight: bold;
                border: 2px solid black;
                padding: 10px;
                border-radius: 15px;
                font-size: 12pt;
                transition: all 0.2s ease;
                box-shadow: 0 5px 10px rgba(0, 0, 0, 0.3);
            }
            QPushButton:hover {
                background: qlineargradient(
                    x1: 0, y1: 0, x2: 0, y2: 1,
                    stop: 0 black, stop: 1 #333333
                );
                color: white;
            }
        """)

    def get_table_names(self):
        # SQL-запрос для получения названий всех таблиц в схеме "public"
        sql_query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
        return self.db.execute_query(sql_query)

    def show_table_data(self, table_name):
        sql_query = f"SELECT * FROM {table_name}"
        result = self.db.execute_query(sql_query)
        print(f"данные из таблицы {table_name}:", *result, sep="\n")
        self.view.update_data(result)

    def update_view(self):
        # По умолчанию показываем данные из первой таблицы
        table_names = self.get_table_names()
        if table_names:
            table_name = table_names[0][0]
            self.show_table_data(table_name)


if __name__ == "__main__":
    import sys
    app = QApplication(sys.argv)
    root = QMainWindow()
    controller = Controller(root)
    root.show()
    sys.exit(app.exec_())
