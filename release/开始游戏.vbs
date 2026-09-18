Option Explicit
Dim shell, files, launcher, sibling, fallback
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
sibling = files.BuildPath(files.GetParentFolderName(WScript.ScriptFullName), "tools\launch.ps1")
fallback = files.BuildPath(files.GetParentFolderName(WScript.ScriptFullName), "..\spire-godot\tools\launch.ps1")
If files.FileExists(sibling) Then
  launcher = sibling
Else
  launcher = files.GetAbsolutePathName(fallback)
End If
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & launcher & Chr(34), 0, False
