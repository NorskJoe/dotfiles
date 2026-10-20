
Import-Module posh-git

# Tab shows a menu when there are multiple completions; Tab/Shift+Tab/arrows to move, Enter to pick
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function MenuComplete
