"""Original desktop settings interface, without simulated scene or live game integration."""
from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path

from PySide6.QtCore import Qt, QTimer, QRectF, QPointF
from PySide6.QtGui import QColor, QPainter, QPen, QFont
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QComboBox, QCheckBox, QSlider, QStackedWidget, QGroupBox,
    QLineEdit, QListWidget, QFileDialog, QMessageBox, QProgressBar, QTabWidget,
    QScrollArea, QSpinBox, QColorDialog,
)
from catalog import CATALOG, clean_catalog

GAMES = ['ROB RUN']
DEFAULTS = dict(skeleton=True, boxes=True, names=True, distance=True, radar=True,
                target_line=True, fov_circle=True, fov=249, max_distance=500,
                loot=True, weapons=True, ammo=True, armor=True, accent='#29bfff')
BOOL_KEYS = {key for key, value in DEFAULTS.items() if type(value) is bool}
STYLE = """
QWidget {background:#090e18;color:#e3ecfa;font:12px 'Segoe UI';}
QMainWindow {background:#090e18;}
QGroupBox {border:1px solid #263449;border-radius:8px;}
QGroupBox {margin-top:20px;padding:18px 12px 12px;font-weight:600;}
QGroupBox::title {subcontrol-origin:margin;left:12px;color:#60cfff;}
QPushButton {background:#162237;border:1px solid #2b3d58;border-radius:6px;padding:10px 14px;}
QPushButton:hover {background:#233d5b;border-color:#29bfff;}
QPushButton:checked {background:#124869;border-color:#29bfff;}
QComboBox,QLineEdit,QListWidget {background:#101a2a;border:1px solid #293a51;border-radius:5px;padding:8px;}
QComboBox QAbstractItemView {background:#101a2a;selection-background-color:#165c80;}
QCheckBox {spacing:10px;padding:7px 0;}
QCheckBox::indicator {width:17px;height:17px;border:1px solid #45566e;border-radius:4px;background:#101a29;}
QCheckBox::indicator:checked {background:#29bfff;border-color:#69d5ff;}
QSlider::groove:horizontal {height:5px;background:#30435c;border-radius:2px;}
QSlider::handle:horizontal {width:14px;background:#63d4ff;margin:-5px 0;border-radius:7px;}
QTabWidget::pane {border:1px solid #25364c;border-radius:7px;}
QTabBar::tab {padding:12px;background:#101827;color:#91a2ba;}
QTabBar::tab:selected {background:#16304a;color:#67d4ff;}
QProgressBar {border:1px solid #28405e;border-radius:5px;text-align:center;min-height:8px;}
QProgressBar::chunk {background:#29bfff;}
QStatusBar {background:#0d1826;color:#9ab1cc;}
"""


def new_config():
    return {**DEFAULTS, 'catalog': clean_catalog({})}


def clean_config(data: dict) -> dict:
    result = dict(DEFAULTS)
    if not isinstance(data, dict):
        raise ValueError('Settings must be a JSON object.')
    for key in BOOL_KEYS:
        if type(data.get(key)) is bool:
            result[key] = data[key]
    for key, low, high in [('fov', 40, 300), ('max_distance', 50, 1500)]:
        value = data.get(key)
        if type(value) in (int, float) and math.isfinite(value):
            result[key] = min(high, max(low, int(value)))
    accent = data.get('accent')
    if isinstance(accent, str) and len(accent) == 7 and accent.startswith('#') and QColor(accent).isValid():
        result['accent'] = accent
    result['catalog'] = clean_catalog(data.get('catalog', {}))
    return result


def settings_path(game: str) -> Path:
    root = Path(os.environ.get('APPDATA') or Path.home() / '.config') / 'DirectLitePreview'
    return root / (''.join(ch for ch in game if ch.isalnum()) + '.json')


class Window(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('Direct Lite · ROB RUN')
        self.resize(1080, 760)
        self.setMinimumSize(1000, 680)
        self.game = 'ROB RUN'
        self.config = new_config()
        self.controls = {}
        self.catalog_controls = {}
        self.clock = 0.0
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)
        self.statusBar().showMessage('Not connected to a game · Local settings only')
        self.splash = QWidget()
        sl = QVBoxLayout(self.splash)
        sl.addStretch()
        title = QLabel('DIRECT <span style="color:#29bfff">LITE</span>')
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet('font-size:38px;font-weight:700;')
        sl.addWidget(title)
        caption = QLabel('Original desktop settings interface')
        caption.setAlignment(Qt.AlignmentFlag.AlignCenter)
        sl.addWidget(caption)
        self.progress = QProgressBar(); self.progress.setTextVisible(False); self.progress.setMaximumWidth(360)
        sl.addWidget(self.progress, alignment=Qt.AlignmentFlag.AlignHCenter)
        sl.addStretch()
        self.stack.addWidget(self.splash)
        self.workbench = self.build_workbench(); self.stack.addWidget(self.workbench)
        self.timer = QTimer(self); self.timer.setInterval(33); self.timer.timeout.connect(self.tick)
        self.intro = QTimer(self); self.intro.setInterval(50); self.intro.timeout.connect(self.intro_tick)
        self.intro.start()
        self.intro_step = 0

    def intro_tick(self):
        self.intro_step += 1
        self.progress.setValue(min(100, self.intro_step * 100 // 60))
        if self.intro_step >= 60:
            self.intro.stop(); self.open_profile('ROB RUN')

    def check(self, layout, label, key):
        box = QCheckBox(label); box.setChecked(self.config[key])
        box.toggled.connect(lambda value, k=key: self.change(k, value))
        self.controls[key] = box; layout.addWidget(box)

    def slider(self, layout, label, key, low, high):
        text = QLabel(f'{label}: {self.config[key]}'); layout.addWidget(text)
        slider = QSlider(Qt.Orientation.Horizontal); slider.setRange(low, high); slider.setValue(self.config[key])
        slider.valueChanged.connect(lambda value, k=key, t=text, l=label: (self.change(k, value), t.setText(f'{l}: {value}')))
        self.controls[key] = slider; layout.addWidget(slider)

    def catalog_change(self, key, value):
        self.config['catalog'][key] = value
        links = {
            'Aimbot/Main/Aim Radius':'fov', 'Aimbot/Aimbot Visuals/FOV Circle':'fov_circle',
            'Aimbot/Aimbot Visuals/Target Line':'target_line', 'Visuals/Radar/Enabled':'radar',
            'Visuals/Settler/Skeleton':'skeleton', 'Visuals/Settler/Box':'boxes',
            'Visuals/Settler/Name':'names', 'Visuals/Settler/Distance':'distance',
            'World/Main / Loot/Enabled':'loot', 'World/Main / Loot/Weapons':'weapons',
            'World/Main / Loot/Ammo':'ammo', 'World/Main / Loot/Armor':'armor',
            'Settings/Appearance/Accent Color':'accent',
        }
        if key in links: self.config[links[key]] = value

    def catalog_color(self, key):
        color = QColorDialog.getColor(QColor(self.config['catalog'][key]), self, 'Choose color')
        if color.isValid(): self.catalog_change(key, color.name()); self.sync()

    def catalog_pane(self, tab):
        pane = QWidget(); layout = QVBoxLayout(pane)
        selector = QComboBox(); selector.addItems(list(CATALOG[tab])); layout.addWidget(selector)
        caption = QLabel('Stored preferences · no live game connection')
        caption.setWordWrap(True); caption.setStyleSheet('color:#89a4be;font-size:10px;')
        layout.addWidget(caption)
        stack = QStackedWidget(); layout.addWidget(stack, 1)
        selector.currentIndexChanged.connect(stack.setCurrentIndex)
        for group, rows in CATALOG[tab].items():
            scroll = QScrollArea(); scroll.setWidgetResizable(True)
            content = QWidget(); fields = QVBoxLayout(content)
            for row in rows:
                name, kind, default, *bounds = row
                key = f'{tab}/{group}/{name}'
                value = self.config['catalog'][key]
                if kind == 'bool':
                    control = QCheckBox(name); control.setChecked(value)
                    control.toggled.connect(lambda v, k=key: self.catalog_change(k,v))
                    fields.addWidget(control)
                else:
                    fields.addWidget(QLabel(name))
                    if kind == 'number':
                        control = QSpinBox(); control.setRange(bounds[0], bounds[1]); control.setValue(value)
                        control.valueChanged.connect(lambda v,k=key: self.catalog_change(k,v))
                    elif kind == 'choice':
                        control = QComboBox(); control.addItems(bounds[0]); control.setCurrentText(value)
                        control.currentTextChanged.connect(lambda v,k=key: self.catalog_change(k,v))
                    elif kind == 'color':
                        control = QPushButton(value)
                        control.setStyleSheet(f'border-left:12px solid {value};')
                        control.clicked.connect(lambda checked=False,k=key: self.catalog_color(k))
                    else:
                        control = QLineEdit(value)
                        control.setCursorPosition(0)
                        control.setMaxLength(500)
                        control.textChanged.connect(lambda v,k=key: self.catalog_change(k,v))
                    fields.addWidget(control)
                control.setToolTip('Stored preference. No live ROB RUN connection.')
                self.catalog_controls[key] = control
            fields.addStretch(); scroll.setWidget(content); stack.addWidget(scroll)
        return pane

    def build_workbench(self):
        root = QWidget(); outer = QVBoxLayout(root)
        top = QHBoxLayout()
        self.profile_label = QLabel('ROB RUN / SETTINGS'); self.profile_label.setStyleSheet('font-size:21px;font-weight:700;')
        top.addWidget(self.profile_label, 1)
        top.addWidget(QLabel('Not connected'))
        outer.addLayout(top)
        body = QHBoxLayout(); outer.addLayout(body, 1)
        tabs = QTabWidget(); tabs.setMinimumWidth(360); body.addWidget(tabs, 1)
        for name in ['Aimbot', 'Visuals', 'World', 'Misc']:
            tabs.addTab(self.catalog_pane(name), name)
        settings = QWidget(); settings_layout = QVBoxLayout(settings)
        for label, fn in [('Save profile', self.save), ('Load profile', self.load), ('Export JSON', self.export), ('Import JSON', self.import_json), ('Reset settings', self.reset)]:
            button = QPushButton(label); button.clicked.connect(fn); settings_layout.addWidget(button)
        settings_layout.addWidget(QLabel('ROB RUN settings are stored locally.\nThere is no licence check or expiration.\nThe app never accesses a game process.'))
        settings_layout.addWidget(self.catalog_pane('Settings'), 1); tabs.addTab(settings, 'Settings')
        return root

    def change(self, key, value):
        self.config[key] = value

    def sync(self):
        for key, control in self.catalog_controls.items():
            value = self.config['catalog'][key]
            control.blockSignals(True)
            if isinstance(control,QCheckBox): control.setChecked(value)
            elif isinstance(control,QSpinBox): control.setValue(value)
            elif isinstance(control,QComboBox): control.setCurrentText(value)
            elif isinstance(control,QLineEdit): control.setText(value); control.setCursorPosition(0)
            else: control.setText(value); control.setStyleSheet(f'border-left:12px solid {value};')
            control.blockSignals(False)
        for key, control in self.controls.items():
            control.blockSignals(True)
            if isinstance(control, QCheckBox): control.setChecked(self.config[key])
            else: control.setValue(self.config[key])
            control.blockSignals(False)
        # Sliders' labels follow programmatic changes as well.
        for control in self.controls.values():
            if isinstance(control, QSlider): control.valueChanged.emit(control.value())

    def open_profile(self, game):
        if game != 'ROB RUN': raise ValueError('This build supports only ROB RUN settings.')
        self.intro.stop(); self.game = game; self.config = new_config()
        path = settings_path(game)
        if path.exists():
            try: self.config = clean_config(json.loads(path.read_text(encoding='utf-8')))
            except (OSError, ValueError): self.statusBar().showMessage('Saved settings could not be loaded; using defaults. Not connected to a game.')
        self.profile_label.setText(f'{game} / SETTINGS')
        self.sync(); self.stack.setCurrentWidget(self.workbench)

    def tick(self):
        pass

    def save(self):
        try:
            path = settings_path(self.game); path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(self.config, indent=2), encoding='utf-8')
            self.statusBar().showMessage(f'{self.game} settings saved. Not connected to a game.')
        except OSError as error: QMessageBox.warning(self, 'Save failed', str(error))

    def load(self):
        self.read_file(settings_path(self.game))

    def read_file(self, path):
        try: self.config = clean_config(json.loads(Path(path).read_text(encoding='utf-8'))); self.sync()
        except (OSError, ValueError) as error: QMessageBox.warning(self, 'Load failed', str(error))

    def export(self):
        path, _ = QFileDialog.getSaveFileName(self, 'Export settings', 'DirectLite.json', 'JSON (*.json)')
        if path:
            try: Path(path).write_text(json.dumps(self.config, indent=2), encoding='utf-8')
            except OSError as error: QMessageBox.warning(self, 'Export failed', str(error))

    def import_json(self):
        path, _ = QFileDialog.getOpenFileName(self, 'Import settings', '', 'JSON (*.json)')
        if path: self.read_file(path)

    def reset(self):
        self.config = new_config(); self.sync()

    def closeEvent(self, event):
        self.timer.stop(); self.intro.stop(); super().closeEvent(event)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--preview', type=Path, help='Render an offscreen UI screenshot and exit.')
    args = parser.parse_args()
    app = QApplication(sys.argv[:1]); app.setStyle('Fusion'); app.setStyleSheet(STYLE)
    window = Window(); window.show()
    if args.preview:
        def capture():
            window.open_profile('ROB RUN'); window.timer.stop(); app.processEvents()
            if not window.grab().save(str(args.preview)):
                raise OSError('Could not save screenshot')
            window.close(); app.quit()
        QTimer.singleShot(150, capture)
    return app.exec()


if __name__ == '__main__':
    raise SystemExit(main())
