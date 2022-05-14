# Run Automatically

### How to run the script automatically:

The recommended way to run this script is with task scheduler. You can find it by searching "task" in the start menu or by running the command `Taskschd.msc` in the run box.

1. In the task scheduler create a new task.
    1. (we are using "create basic task..." for this how to).
2. Name it something that you would recognize such as "Spigot Auto Update".
    2. (The description is optional. I generally recommend filling in some context here).
3. Make sure that the trigger is set to "Daily".
4. Set the time of day that the task will be executed.
    4. Generally a time when people are not on your server is a good time.
5. Make sure that "Start a Program" is selected.
6. To execute the script you will need to specify `powershell -file "C:\Path\to script\autoupdate.ps1"`.
7. Push "No" on the box that pops up next.
8. Before you push "finish" check the box that says "Open the Properties dialog for this task when I click Finish".
9. Push "Finish".
10. go to the actions tab and edit the action.
11. In the "Add arguments (optional)" box add the options you need your script to process E.G. `-BuildVersion "1.11" -ServerStartScript "start.bat"`.
12. press "OK" then "No" to the box that will pop up.
13. Go to the conditions tab and uncheck the Start only is connected to AC power option.
14. Go to settings and uncheck the "Stop the task if it runs longer than:" option.
15. Press OK and you're finished!
