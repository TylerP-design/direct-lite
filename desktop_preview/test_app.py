import os
import tempfile
import unittest
from pathlib import Path

os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
from PySide6.QtWidgets import QApplication
from main import Window, GAMES, DEFAULTS, clean_config, settings_path
from catalog import CATALOG, specifications, clean_catalog


class AppChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QApplication.instance() or QApplication([])

    def test_settings_validation(self):
        data = clean_config({'fov': 9999, 'skeleton': 'yes', 'max_distance': float('inf'), 'accent': 'broken'})
        self.assertEqual(data['fov'], 300)
        self.assertEqual(data['skeleton'], DEFAULTS['skeleton'])
        self.assertEqual(data['max_distance'], DEFAULTS['max_distance'])
        self.assertEqual(data['accent'], DEFAULTS['accent'])
        with self.assertRaises(ValueError):
            clean_config([])

    def test_profiles_persistence_and_pause(self):
        previous = os.environ.get('APPDATA')
        with tempfile.TemporaryDirectory() as folder:
            os.environ['APPDATA'] = folder
            window = Window()
            try:
                paths = set()
                for index, game in enumerate(GAMES):
                    window.open_profile(game)
                    window.change('fov', 70 + index)
                    window.save()
                    paths.add(settings_path(game))
                self.assertEqual(len(paths), len(GAMES))
                for index, game in enumerate(GAMES):
                    window.open_profile(game)
                    self.assertEqual(window.config['fov'], 70 + index)
                    self.assertTrue(window.timer.isActive())
                    window.toggle_preview()
                    self.assertFalse(window.timer.isActive())
                window.filter_roster('cop')
                self.assertEqual(window.roster.count(), 1)
                self.assertIn('demo', window.roster.item(0).text().lower())
                window.back()
                self.assertFalse(window.timer.isActive())
            finally:
                window.close()
                if previous is None: os.environ.pop('APPDATA', None)
                else: os.environ['APPDATA'] = previous

    def test_reference_settings_persist(self):
        previous = os.environ.get('APPDATA')
        with tempfile.TemporaryDirectory() as folder:
            os.environ['APPDATA'] = folder
            window = Window()
            try:
                window.open_profile('ROB RUN')
                self.assertEqual(set(window.catalog_controls), set(specifications()))
                key = 'Aimbot/Main/Type'
                window.catalog_controls[key].setCurrentText('Camera')
                window.catalog_controls['World/Main / Loot/Minimum Loot Value'].setValue(750)
                window.save()
                window.reset()
                self.assertEqual(window.config['catalog'][key], 'Silent')
                window.load()
                self.assertEqual(window.config['catalog'][key], 'Camera')
                self.assertEqual(window.catalog_controls[key].currentText(), 'Camera')
                self.assertEqual(window.config['catalog']['World/Main / Loot/Minimum Loot Value'], 750)
                invalid = clean_catalog({'Aimbot/Main/Aimbot Hitchance':999,'Settings/Appearance/Accent Color':'invalid'})
                self.assertEqual(invalid['Aimbot/Main/Aimbot Hitchance'],100)
                self.assertEqual(invalid['Settings/Appearance/Accent Color'],'#29bfff')
            finally:
                window.close()
                if previous is None: os.environ.pop('APPDATA',None)
                else: os.environ['APPDATA'] = previous


if __name__ == '__main__':
    unittest.main()
