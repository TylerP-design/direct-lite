"""Original desktop interface with simulated data, never a game injector."""
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

GAMES = ['ROB RUN', 'CS2', 'Delta Force', 'Rust', 'Call of Duty']
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


class Scene(QWidget):
    def __init__(self, app):
        super().__init__()
        self.app = app
        self.setMinimumSize(440, 380)

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()
        p.fillRect(self.rect(), QColor('#101d2c'))
        p.setPen(QPen(QColor('#203249'), 1))
        for i in range(12):
            x = w * i / 11
            p.drawLine(QPointF(w / 2, h * .22), QPointF(x, h))
        for y in range(int(h * .3), h, 38):
            p.drawLine(0, y, w, y)
        c, t = self.app.config, self.app.clock
        accent = QColor(c['accent'])
        center = QPointF(w / 2, h / 2)
        if c['fov_circle']:
            p.setPen(QPen(QColor('#5e839e'), 1))
            radius = min(c['fov'], min(w, h) * .43)
            p.drawEllipse(center, radius, radius)
        p.setFont(QFont('Segoe UI', 10))
        p.setPen(QColor('#7c98b5'))
        p.drawText(18, 28, 'SIMULATED SCENE  /  NO GAME CONNECTION')
        for i, name in enumerate(['Demo Settler', 'Demo Citizen', 'Demo Robber', 'Demo Cop']):
            dist = 45 + i * 42
            if dist > c['max_distance']:
                continue
            x = w * (.19 + i * .205) + math.sin(t * .35 + i) * 15
            foot = h * (.64 + .05 * (i % 2))
            height = h * (.29 - i * .018)
            head = QPointF(x, foot - height)
            neck = QPointF(x, foot - height * .83)
            hip = QPointF(x, foot - height * .38)
            p.setPen(QPen(accent, 1.7))
            if c['skeleton']:
                p.drawEllipse(head, 6, 6)
                p.drawLine(head, neck)
                p.drawLine(neck, hip)
                for side in [-1, 1]:
                    elbow = QPointF(x + side * 18, foot - height * .61)
                    hand = QPointF(x + side * 23, foot - height * .43)
                    knee = QPointF(x + side * 13, foot - height * .20)
                    heel = QPointF(x + side * 20, foot)
                    p.drawLine(neck, elbow); p.drawLine(elbow, hand)
                    p.drawLine(hip, knee); p.drawLine(knee, heel)
            if c['boxes']:
                p.drawRect(QRectF(x - 31, foot - height - 12, 62, height + 17))
            if c['names']:
                p.drawText(QRectF(x - 75, foot - height - 38, 150, 20), Qt.AlignmentFlag.AlignCenter, name)
            if c['distance']:
                p.drawText(QRectF(x - 50, foot + 13, 100, 20), Qt.AlignmentFlag.AlignCenter, f'{dist} m (demo)')
            if c['target_line'] and i == 1:
                p.drawLine(center, head)
                p.drawEllipse(head, 3, 3)
        if c['loot']:
            for i, key in enumerate(['weapons', 'ammo', 'armor']):
                if c[key]:
                    p.setPen(QColor('#e4c776'))
                    p.drawText(20 + i * 145, h - 27, f'◇ Demo {key}')
        if c['radar']:
            size = min(145, w // 3)
            rx, ry = w - size - 14, 45
            p.fillRect(QRectF(rx, ry, size, size), QColor('#091321'))
            p.setPen(QPen(QColor('#2c4c69'), 1))
            for i in range(1, 4):
                p.drawLine(rx + i * size // 4, ry, rx + i * size // 4, ry + size)
                p.drawLine(rx, ry + i * size // 4, rx + size, ry + i * size // 4)
            p.setPen(accent)
            p.drawText(rx + 8, ry - 8, 'DEMO RADAR')
            p.setBrush(accent)
            for i in range(4):
                p.drawEllipse(QPointF(rx + 25 + i * 27, ry + 35 + math.sin(t * .35 + i) * 25), 3, 3)
            p.setBrush(QColor('white'))
            p.drawEllipse(QPointF(rx + size / 2, ry + size / 2), 3, 3)
        p.end()


class Window(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('Direct Lite · Desktop Preview')
        self.resize(1280, 800)
        self.setMinimumSize(1000, 680)
        self.game = 'ROB RUN'
        self.config = new_config()
        self.controls = {}
        self.catalog_controls = {}
        self.clock = 0.0
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)
        self.statusBar().showMessage('DEMO ONLY · No process access, injection or anti-cheat integration')
        self.splash = QWidget()
        sl = QVBoxLayout(self.splash)
        sl.addStretch()
        title = QLabel('DIRECT <span style="color:#29bfff">LITE</span>')
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet('font-size:38px;font-weight:700;')
        sl.addWidget(title)
        caption = QLabel('Original desktop interface · simulated preview')
        caption.setAlignment(Qt.AlignmentFlag.AlignCenter)
        sl.addWidget(caption)
        self.progress = QProgressBar(); self.progress.setTextVisible(False); self.progress.setMaximumWidth(360)
        sl.addWidget(self.progress, alignment=Qt.AlignmentFlag.AlignHCenter)
        sl.addStretch()
        self.stack.addWidget(self.splash)
        self.products = self.build_products(); self.stack.addWidget(self.products)
        self.workbench = self.build_workbench(); self.stack.addWidget(self.workbench)
        self.timer = QTimer(self); self.timer.setInterval(33); self.timer.timeout.connect(self.tick)
        self.intro = QTimer(self); self.intro.setInterval(50); self.intro.timeout.connect(self.intro_tick)
        self.intro.start()
        self.intro_step = 0

    def intro_tick(self):
        self.intro_step += 1
        self.progress.setValue(min(100, self.intro_step * 100 // 60))
        if self.intro_step >= 60:
            self.intro.stop(); self.stack.setCurrentWidget(self.products)

    def build_products(self):
        page = QWidget(); lay = QVBoxLayout(page); lay.setContentsMargins(36, 30, 36, 30)
        title = QLabel('DIRECT LITE / PRODUCTS'); title.setStyleSheet('font-size:25px;font-weight:700;color:#58caff')
        lay.addWidget(title)
        lay.addWidget(QLabel('Choose a profile. All profiles currently use simulated data; no game integration is installed.'))
        for game in GAMES:
            card = QGroupBox(game); row = QHBoxLayout(card)
            row.addWidget(QLabel('Desktop menu + overlay preview\nNo subscription or expiry · source included'), 1)
            launch = QPushButton('Open preview'); launch.clicked.connect(lambda checked=False, g=game: self.open_profile(g))
            row.addWidget(launch); lay.addWidget(card)
        lay.addStretch()
        return page

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
        self.scene.update()

    def catalog_color(self, key):
        color = QColorDialog.getColor(QColor(self.config['catalog'][key]), self, 'Choose color')
        if color.isValid(): self.catalog_change(key, color.name()); self.sync()

    def catalog_pane(self, tab):
        pane = QWidget(); layout = QVBoxLayout(pane)
        selector = QComboBox(); selector.addItems(list(CATALOG[tab])); layout.addWidget(selector)
        caption = QLabel('Reference settings · preferences only unless reflected in the simulated scene')
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
        back = QPushButton('‹ Products'); back.clicked.connect(self.back)
        top.addWidget(back)
        self.profile_label = QLabel('ROB RUN / DESKTOP PREVIEW'); self.profile_label.setStyleSheet('font-size:21px;font-weight:700;')
        top.addWidget(self.profile_label, 1)
        self.start = QPushButton('Pause preview'); self.start.clicked.connect(self.toggle_preview); top.addWidget(self.start)
        outer.addLayout(top)
        notice = QLabel('SIMULATED DATA · These controls affect the preview only. No live game features are connected.')
        notice.setStyleSheet('padding:10px;background:#152b3d;color:#77d6ff;border-radius:6px;')
        outer.addWidget(notice)
        body = QHBoxLayout(); outer.addLayout(body, 1)
        tabs = QTabWidget(); tabs.setMinimumWidth(360); tabs.setMaximumWidth(420); body.addWidget(tabs)
        for name in ['Aimbot', 'Visuals', 'World', 'Misc']:
            tabs.addTab(self.catalog_pane(name), name)
        settings = QWidget(); settings_layout = QVBoxLayout(settings)
        for label, fn in [('Save profile', self.save), ('Load profile', self.load), ('Export JSON', self.export), ('Import JSON', self.import_json), ('Reset preview settings', self.reset)]:
            button = QPushButton(label); button.clicked.connect(fn); settings_layout.addWidget(button)
        settings_layout.addWidget(QLabel('Settings are stored separately for each profile.\nThere is no licence check or expiration.\nThe app never accesses a game process.'))
        settings_layout.addWidget(self.catalog_pane('Settings'), 1); tabs.addTab(settings, 'Settings')
        right = QTabWidget(); body.addWidget(right, 1)
        self.scene = Scene(self); right.addTab(self.scene, 'Scene preview')
        lobby = QWidget(); lobby_layout = QVBoxLayout(lobby)
        search = QLineEdit(); search.setPlaceholderText('Filter simulated players...'); lobby_layout.addWidget(search)
        self.roster = QListWidget(); lobby_layout.addWidget(self.roster)
        self.demo_names = ['Demo Settler · settler · 45 m', 'Demo Citizen · citizen · 87 m', 'Demo Robber · robber · 129 m', 'Demo Cop · cop · 171 m']
        search.textChanged.connect(self.filter_roster); self.filter_roster('')
        right.addTab(lobby, 'Lobby & friends · demo')
        return root

    def change(self, key, value):
        self.config[key] = value; self.scene.update()

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
        self.scene.update()

    def open_profile(self, game):
        self.intro.stop(); self.game = game; self.config = new_config()
        path = settings_path(game)
        if path.exists():
            try: self.config = clean_config(json.loads(path.read_text(encoding='utf-8')))
            except (OSError, ValueError): self.statusBar().showMessage('Saved settings could not be loaded; using defaults. DEMO ONLY.')
        self.profile_label.setText(f'{game} / DESKTOP PREVIEW')
        self.sync(); self.stack.setCurrentWidget(self.workbench); self.timer.start(); self.start.setText('Pause preview')

    def back(self):
        self.timer.stop(); self.stack.setCurrentWidget(self.products)

    def tick(self):
        self.clock += .033
        if self.scene.isVisible(): self.scene.update()

    def toggle_preview(self):
        if self.timer.isActive(): self.timer.stop(); self.start.setText('Resume preview')
        else: self.timer.start(); self.start.setText('Pause preview')

    def filter_roster(self, value):
        self.roster.clear(); self.roster.addItems([name for name in self.demo_names if value.lower() in name.lower()])

    def save(self):
        try:
            path = settings_path(self.game); path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(self.config, indent=2), encoding='utf-8')
            self.statusBar().showMessage(f'{self.game} preview settings saved. DEMO ONLY.')
        except OSError as error: QMessageBox.warning(self, 'Save failed', str(error))

    def load(self):
        self.read_file(settings_path(self.game))

    def read_file(self, path):
        try: self.config = clean_config(json.loads(Path(path).read_text(encoding='utf-8'))); self.sync()
        except (OSError, ValueError) as error: QMessageBox.warning(self, 'Load failed', str(error))

    def export(self):
        path, _ = QFileDialog.getSaveFileName(self, 'Export preview settings', 'DirectLite.json', 'JSON (*.json)')
        if path:
            try: Path(path).write_text(json.dumps(self.config, indent=2), encoding='utf-8')
            except OSError as error: QMessageBox.warning(self, 'Export failed', str(error))

    def import_json(self):
        path, _ = QFileDialog.getOpenFileName(self, 'Import preview settings', '', 'JSON (*.json)')
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
