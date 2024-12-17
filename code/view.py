from PyQt5.QtWidgets import QMainWindow, QVBoxLayout, QWidget, QTableWidgetItem, QTableWidget
from PyQt5.QtGui import QFont

class TableView(QWidget):
    """Виджет для отображения данных в виде таблицы."""

    def __init__(self, data: list):
        """
        Конструктор класса.

        Параметры:
        - data (list): Двумерный список данных для отображения в таблице.
        """
        super().__init__()

        self.layout = QVBoxLayout()
        self.setLayout(self.layout)

        self.table_widget = QTableWidget()
        self.table_widget.setStyleSheet("""
            QTableWidget {
                font-family: 'Segoe UI', sans-serif;
                font-size: 12pt;
                background-color: #ffffff; /* Белый фон для таблицы */
                border: 1px solid #cccccc;
                border-radius: 8px;
            }
            QTableWidget::item {
                padding: 8px;
                border-bottom: 1px solid #e0e0e0;
            }
            QTableWidget::item:selected {
                background-color: #ffcc00; /* Желтый фон при выделении */
                color: black; /* Темный текст для выделенных элементов */
            }
            QTableWidget::horizontalHeader {
                background-color: #0066cc; /* Темно-синий фон для заголовка */
                color: white; /* Белый текст в заголовке */
                font-weight: bold;
                border: none;
            }
            QTableWidget::horizontalHeader::section {
                padding: 10px;
                border-right: 1px solid #dddddd;
            }
            QTableWidget::verticalHeader {
                background-color: #f2f2f2; /* Светлый фон для вертикальных заголовков */
                color: #555555; /* Серый текст */
                font-weight: normal;
                border: none;
            }
            QTableWidget::verticalHeader::section {
                padding: 8px;
                border-bottom: 1px solid #dddddd;
            }
        """)
        self.layout.addWidget(self.table_widget)

    def update_data(self, data: list, column_names: list = None):
        """
        Обновляет данные в таблице.

        Параметры:
        - data (list): Двумерный список новых данных.
        - column_names (list, опционально): Список названий столбцов.
        """
        if not data:
            return

        num_rows = len(data)
        num_cols = len(data[0])

        self.table_widget.setRowCount(num_rows)
        self.table_widget.setColumnCount(num_cols)

        if column_names:
            self.table_widget.setHorizontalHeaderLabels(column_names)

        for row_idx, row_data in enumerate(data):
            for col_idx, cell_data in enumerate(row_data):
                item = QTableWidgetItem(str(cell_data))
                self.table_widget.setItem(row_idx, col_idx, item)

        scroll_bar = self.table_widget.verticalScrollBar()
        scroll_bar.setStyleSheet("""
            QScrollBar:vertical {
                border: 1px solid #cccccc; /* Обрамление полосы прокрутки */
                width: 12px;
                margin: 12px 0 12px 0;
                background: #f0f0f0; /* Светло-серый фон */
                border-radius: 6px;
            }
            QScrollBar::handle:vertical {
                background: #0078d7; /* Темно-синий цвет */
                border-radius: 6px;
                min-height: 20px;
            }
            QScrollBar::handle:vertical:hover {
                background: #005bb5; /* Более насыщенный синий при наведении */
            }
            QScrollBar::handle:vertical:pressed {
                background: #003f8a; /* Темно-синий при нажатии */
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                border: none;
                background: none;
            }
            QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                background: none;
            }
        """)
