"C:\Program Files (x86)\NPVR\imageGrabLite.exe" --oid %3
@echo on
cd "C:\comskip"
rem comskip "%newfile%" >> comskip.log

echo %date%,%time% - PostProcessing.bat invoked on %1 recorded from channel %2 >>processing.log
set num1=%2 / 10
rem need to add a pause to avoid race conditions
echo --- sleeping %num1% seconds to avoid simultaneous execution >>processing.log

timeout "num1"

rem check how many comskips are running; if 1 or more are running wait 1 minute and check again
rem the third parameter passed in npvr 1.5.36 and later is a unique recording oid number, so it makes a good filename to store the temporary count
:check
tasklist | find /c "comskip" > %3.txt
set /p count= <%3.txt
if %count% geq 1 (
echo ...%count% comskips running now, waiting 1 minute >>processing.log
timeout 60
goto check
)
del %3.txt

echo %date%,%time% - invoking comskip on %1 >>processing.log
comskip %1
echo %date%,%time% - comskip finished with %1 >>processing.log
echo %date%,%time% - Executing PowerShell Command with %3 >>processing.log
PowerShell.exe -WindowStyle Hidden -noProfile -ExecutionPolicy Bypass -File C:\support\TVRenameScripts\RenameFiles-NextPVR.ps1 %3
:end