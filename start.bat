@echo off
chcp 65001
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0AudioEnhanceTool.ps1"
pause