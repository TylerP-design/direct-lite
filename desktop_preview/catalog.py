"""Settings visible in the supplied reference screenshots. No game integration."""
import math
import re


def b(name, default=False): return (name, 'bool', default)
def n(name, default, low, high): return (name, 'number', default, low, high)
def s(name, default, choices): return (name, 'choice', default, choices)
def t(name, default=''): return (name, 'text', default)
def c(name, default='#82dfff'): return (name, 'color', default)

CATEGORIES = ['Settler', 'Citizen', 'Robber', 'Cop', 'Clan Battle Member', 'Prisoner', 'Huber']
VISUAL = [b('Enabled', True), b('Visible Check'), b('Skeleton', True), b('Box', True),
          b('Name', True), b('Clan Tag'), b('Held Item'),
          t('Indicators', 'Reloading, In Vehicle, Armor, Crouching, Sprinting'),
          b('Distance', True), n('Max Distance', 1500, 50, 2000), c('Color')]
WORLD_MAIN = ['Loot', 'Bodybags', 'Vehicles', 'Alarms', 'Cameras', 'Cargo', 'Containers',
              'ATMs', 'Doors', 'Hide Spots', 'Money At Fence']
WORLD_BASE = ['Overview', 'Buildings', 'Storage', 'Cargo', 'Defenses', 'Workbenches', 'Garages']
CATALOG = {
    'Aimbot': {
        'Main': [b('Enabled'), s('Keybind', 'Mouse 2', ['Mouse 1','Mouse 2','Mouse 4','Mouse 5','Shift','Alt']),
                 s('Type', 'Silent', ['Silent','Camera']), t('Targets', ', '.join(CATEGORIES)),
                 t('Aim Points','Head, Chest, Neck'), n('Aim Radius',249,20,500), b('Ignore Knocked'),
                 b('Visible Check'), n('Aimbot Hitchance',100,0,100), b('Aimbot Max Distance'), n('Max Distance',500,50,2000)],
        'Aimbot Visuals': [b('FOV Circle',True),b('Dynamic FOV Circle'),b('Target Line',True),b('Only When Active'),c('FOV Color','#ffffff'),c('Line Color','#ffffff')],
    },
    'Visuals': {name: list(VISUAL) for name in CATEGORIES},
    'World': {},
    'Misc': {
        'Misc': [b('Battle Mode'),t('Battle Mode Keybind','None'),b('FOV Changer'),n('Field Of View',104,40,120),
                 b('Zoom'),t('Zoom Keybind','None'),n('Zoom Field Of View',30,10,80),
                 b('Freecam'),t('Freecam Keybind','None'),n('Freecam Speed',9,1,50)],
        'Other': [b('Instant Loot Search')],
    },
    'Settings': {
        'Appearance': [c('Accent Color','#29bfff'),s('Menu Keybind','Insert',['Insert','Home','F8','F9','Right Shift']),
                       s('Top Font','Verdana 12',['Verdana 12','Segoe UI 12','Arial 12']),b('Top Outline',True),
                       s('Bottom Font','Verdana 12',['Verdana 12','Segoe UI 12','Arial 12']),b('Bottom Outline',True),
                       s('General Font','Verdana 12',['Verdana 12','Segoe UI 12','Arial 12']),b('General Outline',True)],
        'Configs': [t('Config Name','Default')],
    },
}
CATALOG['Visuals']['Radar'] = [b('Enabled',True),b('Names'),b('Distance'),n('Range',500,50,2000),n('Size',200,100,500),c('Color')]
CATALOG['Visuals']['Extra Player Visuals'] = [b('Offscreen Indicators'),b('Health Bar',True),b('Armor Bar'),b('Target Highlight')]
for name in WORLD_MAIN:
    rows = [b('Enabled'),b('Name',True),b('Distance',True),n('Max Distance',500,50,2000),c('Color')]
    if name == 'Loot':
        rows += [b('Value',True),s('Filter By','Category',['Category','Value']),n('Minimum Loot Value',0,0,100000)]
        for category, color in [('Weapons','#ed8b91'),('Ammo','#d7bb86'),('Armor','#77a9ef'),('Equipment','#78c8cf'),
                                ('Medicine','#88d8b1'),('Grenades','#f6ba74'),('Keys','#bd93f9'),('Tools','#b9c4d7'),
                                ('Cash','#8fdaa9'),('Valuables','#e7d381'),('Other','#aaaaaa')]:
            rows += [b(category,True),c(category+' Color',color)]
    CATALOG['World']['Main / '+name] = rows
for name in WORLD_BASE:
    CATALOG['World']['Base / '+name] = [b('Enabled'),b('Name',True),b('Distance',True),b('Owner',True),b('Clan',True),b('Modules'),b('Status',True),n('Max Distance',500,50,2000),c('Color','#bd93f9')]


def specifications():
    return {f'{tab}/{group}/{row[0]}': row for tab, groups in CATALOG.items() for group, rows in groups.items() for row in rows}


def clean_catalog(data):
    if not isinstance(data, dict): data = {}
    result = {}
    for key, row in specifications().items():
        _, kind, default, *bounds = row
        value = data.get(key, default)
        if kind == 'bool': value = value if type(value) is bool else default
        elif kind == 'number':
            value = min(bounds[1],max(bounds[0],int(value))) if type(value) in (int,float) and math.isfinite(value) else default
        elif kind == 'choice': value = value if isinstance(value,str) and value in bounds[0] else default
        elif kind == 'color': value = value if isinstance(value,str) and re.fullmatch(r'#[0-9a-fA-F]{6}',value) else default
        else: value = value[:500] if isinstance(value,str) else default
        result[key] = value
    return result
