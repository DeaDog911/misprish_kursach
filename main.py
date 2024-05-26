import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QLabel
from code.controller import Controller


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Курсовая работа")
        self.setFixedSize(800, 600)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    root = MainWindow()
    controller = Controller(root)
    root.show()
    sys.exit(app.exec_())
