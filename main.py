import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QLabel
from code.controller import Controller

if __name__ == "__main__":
    app = QApplication(sys.argv)
    root = QMainWindow()
    controller = Controller(root)
    root.show()
    sys.exit(app.exec_())
