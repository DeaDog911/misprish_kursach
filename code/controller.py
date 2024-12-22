import sys
from PyQt5.QtWidgets import QWidget, QVBoxLayout, QPushButton, QApplication, QScrollArea, QGridLayout, QMainWindow
from PyQt5.QtCore import Qt

from code.additional_window import FindWindow
from code.change_product_class_window import ChangeProductClassWindow
from code.chante_parent_class_window import ChangeParentClassWindow
from code.delete_window import DeleteWindow
from code.add_window import AddWindow  # Ensure these imports are correct and available
from code.view import TableView
from code.static_funcs import get_russian_table_name
from code.database_dao import DatabaseDAO

from PyQt5.QtCore import QThread, pyqtSignal

class CalculateNormsThread(QThread):
    """Поток для выполнения подсчета сводных норм в фоновом режиме."""
    result_signal = pyqtSignal(list)  # Сигнал для передачи результата обратно в главный поток
    error_signal = pyqtSignal(str)  # Сигнал для передачи ошибок

    def __init__(self, db_dao):
        super().__init__()
        self.db_dao = db_dao

    def run(self):
        """Запускает подсчет сводных норм в фоновом потоке."""
        try:
            result = self.db_dao.calculate_component_quantities()
            if result:
                self.result_signal.emit(result)  # Отправляем результат обратно в главный поток
            else:
                self.error_signal.emit("Ошибка при подсчете сводных норм.")
        except Exception as e:
            self.error_signal.emit(str(e))

class Controller:
    """Контроллер для управления главным окном приложения."""

    def __init__(self, root: QMainWindow):
        """
        Конструктор класса.

        Параметры:
        - root (QMainWindow): Главное окно приложения.
        """
        self.root = root
        # root.resize(800, 600)

        # Инициализация DatabaseDAO
        self.db_dao = DatabaseDAO('database.ini', 'queries.json')

        self.central_widget = QWidget()
        self.central_widget.setStyleSheet("background-color: lightblue;")

        self.layout = QVBoxLayout(self.central_widget)
        self.root.setCentralWidget(self.central_widget)

        self.buttons = []  # Initialize the buttons list here

        self.button_layout = QGridLayout()
        self.layout.addLayout(self.button_layout)

        self.create_table_buttons()

        self.scroll_area = QScrollArea(self.central_widget)
        self.scroll_area.verticalScrollBar().setStyleSheet("""
            QScrollBar:vertical {
                background: #f0f0f0;
                width: 12px;
                border: 1px solid #d9d9d9;
                margin: 2px 0 2px 0;
                border-radius: 6px;
            }
            QScrollBar::handle:vertical {
                background: #4CAF50;
                border-radius: 6px;
                min-height: 20px;
            }
            QScrollBar::handle:vertical:hover {
                background: #45a049;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
                width: 0px;
                background: none;
            }
            QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                background: none;
            }
        """)

        self.layout.addWidget(self.scroll_area)

        self.inner_widget = QWidget()
        self.inner_widget.setStyleSheet("background-color: white;")
        self.inner_layout = QVBoxLayout(self.inner_widget)

        self.scroll_area.setWidget(self.inner_widget)
        self.scroll_area.setWidgetResizable(True)

        self.view = TableView(self.inner_widget)
        self.inner_layout.addWidget(self.view)

        self.calculate_norm_thread = None

        self.layout.addWidget(self.scroll_area)
        self.create_add_button()  # Move add button creation here
        self.create_delete_button()
        self.create_change_parent_class_button()
        self.create_change_class_button()
        self.create_find_products_button()
        self.create_find_children_button()
        self.create_find_parents_button()
        self.create_show_tree_button()
        self.create_calculate_norm_button()  # Вызываем создание кнопки подсчета сводных норм
        self.create_show_spec_structure_button()
        self.update_view()

    def create_table_buttons(self):
        """Создает кнопки для отображения данных каждой таблицы."""
        table_names = self.get_table_names()
        row, col = 0, 0
        for name in table_names:
            russian_name = get_russian_table_name(name)
            button = QPushButton(russian_name, self.central_widget)
            button.clicked.connect(lambda _, table=name: self.show_table_data(table))
            self.style_button(button)
            self.buttons.append(button)
            self.button_layout.addWidget(button, row, col)
            col += 1
            if col > 2:
                col = 0
                row += 1

    def style_button(self, button: QPushButton):
        """Применяет стилизацию к кнопке."""
        button.setStyleSheet("""
            QPushButton {
                background-color: #ffffff;
                color: #333333;
                border: 2px solid #0078d7;
                border-radius: 10px;
                padding: 8px 16px;
                font-size: 14px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #0078d7;
                color: #ffffff;
            }
            QPushButton:pressed {
                background-color: #005bb5;
                color: #ffffff;
            }
        """)

    def get_table_names(self) -> list:
        """Возвращает список имен всех таблиц в базе данных."""
        return ["classification", "product", "unit", "spec_position"]

    def show_table_data(self, table_name: str):
        """Отображает данные из выбранной таблицы."""
        result = self.db_dao.get_all_from_table(table_name)
        if result:
            column_names = [description[0] for description in self.db_dao.cur.description]
            print(f"Названия столбцов:", column_names)
            print(f"Данные из таблицы {table_name}:", *result, sep="\n")
            self.view.update_data(result, column_names)
        else:
            print("Таблица пуста")

    def update_view(self):
        """Обновляет вид отображения, показывая данные из первой таблицы."""
        table_names = self.get_table_names()
        if table_names:
            table_name = table_names[0]
            self.show_table_data(table_name)

    def create_add_button(self):
        """Создает кнопку для добавления записи в выбранную таблицу."""
        add_button = QPushButton("+", self.central_widget)
        add_button.clicked.connect(self.open_add_window)
        self.style_button(add_button)
        self.layout.addWidget(add_button)  # Add to the main layout at the bottom

    def create_delete_button(self):
        """Создает кнопку для удаления записи из выбранной таблицы."""
        delete_button = QPushButton("-", self.central_widget)
        delete_button.clicked.connect(self.open_delete_window)
        self.style_button(delete_button)
        self.layout.addWidget(delete_button)  # Add to the main layout at the bottom

    def create_find_children_button(self):
        """Создает кнопку для поиска потомков класса."""
        find_children_button = QPushButton("Найти потомков", self.central_widget)
        find_children_button.clicked.connect(self.open_find_children_window)
        self.style_button(find_children_button)
        self.layout.addWidget(find_children_button)

    def create_find_parents_button(self):
        """Создает кнопку для поиска потомков класса."""
        find_children_button = QPushButton("Найти родителей", self.central_widget)
        find_children_button.clicked.connect(self.open_find_parents_window)
        self.style_button(find_children_button)
        self.layout.addWidget(find_children_button)

    def open_add_window(self):
        """Открывает окно для добавления новой записи."""
        table_names = self.get_table_names()
        add_window = AddWindow(table_names, self.db_dao)
        add_window.exec_()

    def open_delete_window(self):
        """Открывает окно для удаления записи."""
        table_names = self.get_table_names()
        delete_window = DeleteWindow(table_names, self.db_dao)
        delete_window.exec_()

    def open_find_children_window(self):
        """Открывает окно для поиска потомков класса."""
        find_children_window = FindWindow(self.db_dao, "children")
        find_children_window.exec_()

    def open_find_parents_window(self):
        """Открывает окно для поиска потомков класса."""
        find_children_window = FindWindow(self.db_dao, "parents")
        find_children_window.exec_()

    def create_show_tree_button(self):
        """Создает кнопку для отображения дерева классов и продуктов."""
        show_tree_button = QPushButton("Отобразить дерево", self.central_widget)
        show_tree_button.clicked.connect(self.show_tree)
        self.style_button(show_tree_button)
        self.layout.addWidget(show_tree_button)  # Add to the main layout at the bottom

    def show_tree(self):
        """Отображает дерево классов и продуктов."""
        results = self.db_dao.show_tree()
        column_names = ["ID класса", "Название класса", "ID продукта", "Название продукта"]
        self.view.update_data(results, column_names)

    def create_change_parent_class_button(self):
        button = QPushButton('Изменить родителя класса', self.central_widget)
        button.clicked.connect(self.show_change_parent_class_dialog)
        self.style_button(button)
        self.layout.addWidget(button)

    def show_change_parent_class_dialog(self):
        dialog = ChangeParentClassWindow(self.root, self.db_dao)
        dialog.exec_()

    def create_change_class_button(self):
        """Создает кнопку для изменения класса продукта."""
        change_class_button = QPushButton("Изменить класс продукта", self.central_widget)
        change_class_button.clicked.connect(self.open_change_class_window)
        self.style_button(change_class_button)
        self.layout.addWidget(change_class_button)

    def open_change_class_window(self):
        """Открывает окно для изменения класса продукта."""
        change_class_window = ChangeProductClassWindow(self.db_dao)
        change_class_window.exec_()

    def create_find_products_button(self):
        """Создает кнопку для поиска продуктов по классу."""
        find_products_button = QPushButton("Найти продукты по классу", self.central_widget)
        find_products_button.clicked.connect(self.open_find_products_window)
        self.style_button(find_products_button)
        self.layout.addWidget(find_products_button)

    def open_find_products_window(self):
        """Открывает окно для поиска продуктов по классу."""
        find_products_window = FindWindow(self.db_dao, "products")
        find_products_window.exec_()

    def create_calculate_norm_button(self):
        """Создает кнопку для подсчета сводных норм."""
        calculate_norm_button = QPushButton("Подсчитать сводные нормы", self.central_widget)
        calculate_norm_button.clicked.connect(self.start_calculate_norm_thread)
        self.style_button(calculate_norm_button)
        self.layout.addWidget(calculate_norm_button)

    def start_calculate_norm_thread(self):
        """Запускает поток для подсчета сводных норм."""
        self.calculate_norm_thread = CalculateNormsThread(self.db_dao)
        self.calculate_norm_thread.result_signal.connect(self.handle_calculate_norm_result)
        self.calculate_norm_thread.error_signal.connect(self.handle_error)
        self.calculate_norm_thread.start()

    def handle_calculate_norm_result(self, result):
        """Обрабатывает результат подсчета сводных норм."""
        column_names = ["ID компонента", "Количество", "Единица измерения"]
        self.view.update_data(result, column_names)

    def create_show_spec_structure_button(self):
        """Создает кнопку для отображения структуры спецификации."""
        show_spec_structure_button = QPushButton("Отобразить структуру спецификации", self.central_widget)
        show_spec_structure_button.clicked.connect(self.show_spec_structure)  # Здесь нужно подключить правильный метод
        self.style_button(show_spec_structure_button)
        self.layout.addWidget(show_spec_structure_button)

    def show_spec_structure(self):
        """Отображает структуру спецификации, используя метод из DatabaseDAO."""
        results, column_names = self.db_dao.show_spec_structure()  # Получаем данные и названия столбцов
        if results:
            self.view.update_data(results, column_names)  # Обновляем представление
        else:
            print("Структура спецификации пуста")

    def handle_error(self, error_message):
        """Обрабатывает ошибки, если они произошли."""
        print(f"Ошибка: {error_message}")
        # Можно также отобразить сообщение пользователю через диалоговое окно или статусную строку
