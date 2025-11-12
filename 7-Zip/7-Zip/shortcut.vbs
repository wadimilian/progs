On Error Resume Next

Public Function Help
  MsgBox "Скрипт для управления ярлыками v1.8" & Chr (13) & Chr (13) & _
         "    Создание ярлыка:" & Chr (13) & _
         "        shortcut  ""полное_имя_файла[;аргументы[;стиль окна]]""  ""путь""  [""имя""  [""описание""  [""иконка""]]]" & Chr (13) & Chr (13) & _
         "    Удаление ярлыка:" & Chr (13) & _
         "        shortcut  """"  ""путь""  ""имя""" & Chr (13) & Chr (13) & _
         "    Удаление ярлыка-папки:" & Chr (13) & _
         "        shortcut  """"  ""путь""  ""*""" & Chr (13) & Chr (13) & _
         "    Стиль открытия окна:" & Chr (13) & _
         "        1 - Обычный" & Chr (13) & _
         "        3 - На весь экран" & Chr (13) & _
         "        7 - Свёрнутое" & Chr (13) & Chr (13) & _
         "    Параметр ""путь"" понимает значения:" & Chr (13) & _
         "        AllUsersDesktop" & Chr (13) & _
         "        AllUsersPrograms" & Chr (13) & _
         "        Desktop" & Chr (13) & _
         "        Programs" & Chr (13) & _
         "        QuickLaunch" & Chr (13) & Chr (13) & _
         "(C) SMKSoft, 2024"
  WScript.Quit 1
End Function

Public Function GetShortcutPath (s)
  Set objWshShell             = WScript.CreateObject ("WScript.Shell")
  Set colEnvironmentVariables = objWshShell.Environment ("Volatile")

  GetShortcutPath = s
  If InStr (s, "AllUsersDesktop") > 0 Then
    GetShortcutPath=Replace (s, "AllUsersDesktop", objWshShell.SpecialFolders ("AllUsersDesktop"))
  Else
    If InStr (s, "AllUsersPrograms") > 0 Then
      GetShortcutPath=Replace (s, "AllUsersPrograms", objWshShell.SpecialFolders ("AllUsersPrograms"))
    Else
      If InStr (s, "Desktop") > 0 Then
        GetShortcutPath=Replace (s, "Desktop", objWshShell.SpecialFolders ("Desktop"))
      Else
        If InStr (s, "Programs") > 0 Then
          GetShortcutPath=Replace (s, "Programs", objWshShell.SpecialFolders ("Programs"))
        Else
          If InStr (s, "QuickLaunch") > 0 Then
            GetShortcutPath=Replace (s, "QuickLaunch", colEnvironmentVariables.Item ("APPDATA") & "\Microsoft\Internet Explorer\Quick Launch")
          End If
        End If
      End If
    End If
  End If
End Function

Public Function SpecialFolder (s)
  Set objWshShell             = WScript.CreateObject ("WScript.Shell")
  Set colEnvironmentVariables = objWshShell.Environment ("Volatile")

  SpecialFolder=False
  If s = objWshShell.SpecialFolders   ("AllUsersDesktop" )                                               Then SpecialFolder = True
  If s = objWshShell.SpecialFolders   ("AllUsersPrograms")                                               Then SpecialFolder = True
  If s = objWshShell.SpecialFolders   ("Desktop"         )                                               Then SpecialFolder = True
  If s = objWshShell.SpecialFolders   ("Programs"        )                                               Then SpecialFolder = True
  If s = colEnvironmentVariables.Item ("APPDATA"         ) & "\Microsoft\Internet Explorer\Quick Launch" Then SpecialFolder = True
End Function


Set objFSO      = WScript.CreateObject ("Scripting.FileSystemObject")
Set objWshShell = WScript.CreateObject ("WScript.Shell")

FileFullName = Split (Wscript.Arguments.Item (0), ";") (0)
Arguments    = Split (Wscript.Arguments.Item (0), ";") (1)
WindowStyle  = Split (Wscript.Arguments.Item (0), ";") (2): If Len (WindowStyle) = 0 Then WindowStyle = 1
ShortcutPath = Wscript.Arguments.Item (1): If Len (ShortcutPath) = 0 Then Help
ShortcutName = Wscript.Arguments.Item (2): If Len (ShortcutName) = 0 Then ShortcutName = objFSO.GetBaseName (FileFullName)
ShortcutDesc = Wscript.Arguments.Item (3)
ShortcutIcon = Wscript.Arguments.Item (4): If Len (ShortcutIcon) = 0 Then ShortcutIcon = FileFullName &",0"
ShortcutPath = GetShortcutPath (ShortcutPath)

If Len (FileFullName) = 0 Then
  If objFSO.FolderExists (ShortcutPath) Then
    If ShortcutName = "*" Then
      ' Delete Shortcut Folder, if ShortcutName = "*"
      objFSO.DeleteFolder (ShortcutPath)
    Else
      ' Delete Shortcut
      objFSO.DeleteFile (ShortcutPath &"\"& ShortcutName &".lnk")
      Set objFolder = objFSO.GetFolder (ShortcutPath)
      ' Delete Shortcut Folder, if it is not a Special Folder, and it is Empty
      If Not SpecialFolder (ShortcutPath) And objFolder.Files.Count = 0 And objFolder.SubFolders.Count = 0 Then objFSO.DeleteFolder (ShortcutPath)
    End If
  End If
Else
  ' Create Shortcut
  objFSO.CreateFolder (ShortcutPath)
  Set objWshShortcut = objWshShell.CreateShortcut (ShortcutPath &"\"& ShortcutName &".lnk")
  objWshShortcut.WorkingDirectory = objFSO.GetParentFolderName (FileFullName) ' Рабочая папка
  objWshShortcut.TargetPath       = FileFullName                              ' Полное имя файла
  objWshShortcut.IconLocation     = ShortcutIcon                              ' Полное имя иконки
  objWshShortcut.Arguments        = Arguments                                 ' Аргументы командной строки
  objWshShortcut.Description      = ShortcutDesc                              ' Комментарий
  objWshShortcut.WindowStyle      = WindowStyle                               ' Стиль открытия окна: 1-Обычный; 3-На весь экран; 7-Свёрнутое
' objWshShortcut.Hotkey           = "CTRL+SHIFT+F"                            ' Клавиши быстрого вызова
  objWshShortcut.Save                                                         ' Сохранение ярлыка
End If
