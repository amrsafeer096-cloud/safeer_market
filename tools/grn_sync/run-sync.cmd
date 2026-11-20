@echo off
cd /d "%~dp0"
if not exist logs mkdir logs
py -3 sync_receipts.py >> logs\sync.log 2>&1
