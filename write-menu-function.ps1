﻿Function Write-Menu {

<#
.SYNOPSIS
	Display custom menu in the PowerShell console.
.DESCRIPTION
	This cmdlet writes numbered and colored menues in the PS console window
	and returns the choiced entry.
.PARAMETER Menu
	Menu entries.
.PARAMETER PropertyToShow
	If your menu entries are objects and not the strings
	this is property to show as entry.
.PARAMETER Prompt
	User prompt at the end of the menu.
.PARAMETER Header
	Menu title (optional).
.PARAMETER Shift
	Quantity of <TAB> keys to shift the menu right.
.PARAMETER TextColor
	Menu text color.
.PARAMETER HeaderColor
	Menu title color.
.PARAMETER AddExit
	Add 'Exit' as very last entry.
.EXAMPLE
	PS C:\> Write-Menu -Menu "Open","Close","Save" -AddExit -Shift 1
	Simple manual menu with 'Exit' entry and 'one-tab' shift.
.EXAMPLE
	PS C:\> Write-Menu -Menu (Get-ChildItem 'C:\Windows\') -Header "`t`t-- File list --`n" -Prompt 'Select any file'
	Folder content dynamic menu with the header and custom prompt.
.EXAMPLE
	PS C:\> Write-Menu -Menu (Get-Service) -Header ":: Services list ::`n" -Prompt 'Select any service' -PropertyToShow DisplayName
	Display local services menu with custom property 'DisplayName'.
.EXAMPLE
      PS C:\> Write-Menu -Menu (Get-Process |select *) -PropertyToShow ProcessName |fl
      Display full info about choicen process.
.INPUTS
	[string[]] [pscustomobject[]] or any!!! type of array.
.OUTPUTS
	[The same type as input object] Single menu entry.
.NOTES
	Author       ::	Roman Gelman.
	Version 1.0  ::	21-Apr-2016  :: Release.
.LINK
	http://www.ps1code.com/single-post/2016/04/21/How-to-create-interactive-dynamic-Menu-in-PowerShell
#>

[CmdletBinding()]

Param (

	[Parameter(Mandatory,Position=0)]
		[Alias("MenuEntry","List")]
	$Menu
	,
	[Parameter(Mandatory=$false,Position=1)]
	[string]$PropertyToShow = 'Name'
	,
	[Parameter(Mandatory=$false,Position=2)]
		[ValidateNotNullorEmpty()]
	[string]$Prompt = 'Pick a choice'
	,
	[Parameter(Mandatory=$false,Position=3)]
		[Alias("MenuHeader")]
	[string]$Header = ''
	,
	[Parameter(Mandatory=$false,Position=4)]
		[ValidateRange(0,5)]
		[Alias("Tab","MenuShift")]
	[int]$Shift = 0
	,
	#[Enum]::GetValues([System.ConsoleColor])
	[Parameter(Mandatory=$false,Position=5)]
		[ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed","DarkMagenta",
		"DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]
		[Alias("Color","MenuColor")]
	[string]$TextColor = 'White'
	,
	[Parameter(Mandatory=$false,Position=6)]
		[ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed","DarkMagenta",
		"DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]
	[string]$HeaderColor = 'Yellow'
	,
	[Parameter(Mandatory=$false,Position=7)]
		[ValidateNotNullorEmpty()]
		[Alias("Exit","AllowExit")]
	[switch]$AddExit
)

Begin {

	$ErrorActionPreference = 'Stop'
	If ($Menu -isnot 'array') {Throw "The menu entries must be array or objects"}
	If ($AddExit) {$MaxLength=8} Else {$MaxLength=9}
	If ($Menu.Length -gt $MaxLength) {$AddZero=$true} Else {$AddZero=$false}
	[hashtable]$htMenu = @{}
}

Process {

	### Write menu header ###
	If ($Header -ne '') {Write-Host $Header -ForegroundColor $HeaderColor}
	
	### Create shift prefix ###
	If ($Shift -gt 0) {$Prefix = [string]"`t"*$Shift}
	
	### Build menu hash table ###
	For ($i=1; $i -le $Menu.Length; $i++) {
		If ($AddZero) {
			If ($AddExit) {$lz = ([string]($Menu.Length+1)).Length - ([string]$i).Length}
			Else          {$lz = ([string]$Menu.Length).Length - ([string]$i).Length}
			$Key = "0"*$lz + "$i"
		} Else {$Key = "$i"}
		$htMenu.Add($Key,$Menu[$i-1])
		If ($Menu[$i] -isnot 'string' -and ($Menu[$i-1].$PropertyToShow)) {
			Write-Host "$Prefix[$Key] $($Menu[$i-1].$PropertyToShow)" -ForegroundColor $TextColor
		} Else {Write-Host "$Prefix[$Key] $($Menu[$i-1])" -ForegroundColor $TextColor}
	}
	If ($AddExit) {
		[string]$Key = $Menu.Length+1
		$htMenu.Add($Key,"Exit")
		Write-Host "$Prefix[$Key] Exit" -ForegroundColor $TextColor
	}
	
	### Pick a choice ###
	Do {
		$Choice = Read-Host -Prompt $Prompt
		If ($AddZero) {
			If ($AddExit) {$lz = ([string]($Menu.Length+1)).Length - $Choice.Length}
			Else          {$lz = ([string]$Menu.Length).Length - $Choice.Length}
			If ($lz -gt 0) {$KeyChoice = "0"*$lz + "$Choice"} Else {$KeyChoice = $Choice}
		} Else {$KeyChoice = $Choice}
	} Until ($htMenu.ContainsKey($KeyChoice))
}

End {return $htMenu.get_Item($KeyChoice)}

} #EndFunction Write-Menu


#Function to set windows on top
#Requires -Version 2.0 

$signature = @"
	
	[DllImport("user32.dll")]  
	public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);  

	public static IntPtr FindWindow(string windowName){
		return FindWindow(null,windowName);
	}

	[DllImport("user32.dll")]
	public static extern bool SetWindowPos(IntPtr hWnd, 
	IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);

	[DllImport("user32.dll")]  
	public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); 

	static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
	static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

	const UInt32 SWP_NOSIZE = 0x0001;
	const UInt32 SWP_NOMOVE = 0x0002;

	const UInt32 TOPMOST_FLAGS = SWP_NOMOVE | SWP_NOSIZE;

	public static void MakeTopMost (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_TOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}

	public static void MakeNormal (IntPtr fHandle)
	{
		SetWindowPos(fHandle, HWND_NOTOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
	}
"@

