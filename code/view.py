from PyQt5.QtWidgets import QMainWindow, QLabel, QVBoxLayout, QWidget


class TableView(QMainWindow):
    def __init__(self, data):
        super().__init__()

        self.setWindowTitle("Table View")
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)

        layout = QVBoxLayout()
        self.central_widget.setLayout(layout)

        self.label = QLabel(str(data))
        layout.addWidget(self.label)

    def update_data(self, new_data):
        self.label.setText(str(new_data))
