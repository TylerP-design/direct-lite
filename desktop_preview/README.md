# Direct Lite Desktop Preview

Original Python/Qt desktop interface inspired by the supplied screenshots, with a navy/cyan design. All data and visuals are simulated. This is not a working ROB RUN cheat, injector, live game overlay, or EAC integration. It does not open game processes, read memory, send game input, modify files, or bypass a licence. No subscription or expiry is implemented.

## Run on Windows

Install Python 3.10 or newer, including the Python launcher. Extract this ZIP and open a terminal in the extracted folder:

```
py -3 -m pip install -r requirements.txt
py -3 main.py
```

After installing dependencies, `run_windows.bat` opens the app. Startup shows a roughly three-second introduction, then the profile picker. All five game profiles are explicitly labelled as previews. Use the controls to change the simulated skeletons, boxes, names, distance limits, FOV circle, target line, radar and loot labels. Pause the animation from the top bar.

Profiles store settings separately under `%APPDATA%\DirectLitePreview`. Import/export accepts validated JSON settings, never executable code.

## Build your own Windows EXE

Run `build_windows.bat` on Windows. It installs PyInstaller and builds `dist\DirectLitePreview.exe`. The supplied package contains source and build instructions, not a prebuilt or Windows-tested EXE. Dependency installation and building require internet access; the app itself has no network code.

## What remains

The updated interface contains the reference categories under Aimbot, Visuals, World, Misc and Settings. Player categories, main/base world categories, loot colors/filters, keybind preferences, aim preferences and font choices are persisted per profile. The category selector exposes each section without rendering all controls on screen simultaneously. Most are stored preferences only, explicitly labelled; selected common visuals update the simulated scene. Font and keybind preferences do not add system-wide shortcuts or change a game. No pretend network integration or functional aim code is behind these fields.

A supported, independently developed data source would be needed for real game information. There is no hidden integration behind these controls. The program does not use or execute the uploaded ZBrush.exe, and does not claim to be undetected.
