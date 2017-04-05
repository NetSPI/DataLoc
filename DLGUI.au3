#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Etc\Cake.ico
#AutoIt3Wrapper_Outfile=DataLoc_x86.exe
#AutoIt3Wrapper_Outfile_x64=DataLoc_x64.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Description=DB Data locator
#AutoIt3Wrapper_Res_Fileversion=0.1.0.57
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /sf /sv /mo /rm
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
#include <Date.au3>
#include <Array.au3>
#include <WinAPI.au3>
#include <String.au3>
#include <Constants.au3>
#include <GUIListBox.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <StringConstants.au3>
#include <WindowsConstants.au3>
#include "Lib\MetroGUI-UDF\MetroGUI_UDF.au3"

Global Const $SQL_OK=0,$SQL_ERROR=1
Global $SQLObjErr,$SQL_LastConnection=-1,$SQLErr,$sMSG_Time
RegisterErrorHandler()
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;		Create GUI
;-----------------------------------------------------------------------
_SetTheme("LightBlue")
_Metro_EnableHighDPIScaling()
$Form1=_Metro_CreateGUI("DB Data Loc",700,360,-1,-1,True)
$aControl_Buttons=_Metro_AddControlButtons(True,True,True,True,True)

;Create an Array containing menu button names
Dim $MenuButtonsArray[3]=["Settings","About","Exit"]

$Group1=GUICtrlCreateGroup("",10,25,250,90)
GUICtrlSetResizing($Group1,768+2+32)
;RHOST
	$Label1=GUICtrlCreateLabel("RHOST:",15,40)
	GUICtrlSetResizing($Label1, 768+2+32)

	$Input1=GUICtrlCreateInput("",60,35,195,20)
	GUICtrlSetResizing($Input1, 768+2+32)
	GUICtrlSetTip($Input1,"Example: 10.16.5.13\MSSQL2008")
;Login / Password
	$Label2=GUICtrlCreateLabel("L/P:",15,65)
	GUICtrlSetResizing($Label2, 768+2+32)
	;Login
	$Input2=GUICtrlCreateInput("",40,60,105,20)
	GUICtrlSetResizing($Input2, 768+2+32)
	GUICtrlSetTip($Input2,"Username for SQL auth")
	;Password
	$Input3=GUICtrlCreateInput("",150,60,105,20,0x0020)
	GUICtrlSetResizing($Input3, 768+2+32)
	GUICtrlSetTip($Input3,"Password for SQL auth")
;Toggle auth type
	$Toggle1=_Metro_CreateOnOffToggle("Auth: Win", "Auth: SQL",15,85,130,26)
	GUICtrlSetResizing($Toggle1,768+2+32)
;Connect/Disconnect button
	$Button1=_Metro_CreateButton("Connect",150,85,105,22)
	GUICtrlSetResizing($Button1,768+2+32)

;Database selector
$Label3=GUICtrlCreateLabel("Database:",10,125)
GUICtrlSetResizing($Label3,768+2+32)
;Database selection drop down
$Combo1=GUICtrlCreateCombo("",60,120,200,25)
GUICtrlSetResizing($Combo1,768+2+32)
GUICtrlSetState($Combo1,$GUI_Disable)

;Table selection list view
$ListView1=GUICtrlCreateListView("Table|Rows",10,150,250,201)
GUICtrlSetResizing($ListView1,256+2+32+64)
GUICtrlSetState($ListView1,$GUI_Disable)

;Column selection list view
$ListView2=GUICtrlCreateListView("Column|Type|Length",265,32,430,290)
GUICtrlSetResizing($ListView2,2+4+32+64)
GUICtrlSetState($ListView2,$GUI_Disable)

;Scan Button
$Button2=_Metro_CreateButton("Scan",605,327,90,23)
GUICtrlSetResizing($Button2,4+64+256+512)
GUICtrlSetState($Button2,$GUI_Disable)

;Status
$Input4=GUICtrlCreateInput("",265,326,335,25)
GUICtrlSetResizing($Input4,2+4+64+512)
GUICtrlSetState($Input4,$GUI_Disable)

GUISetState(@SW_SHOW)

;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;		Main loop
;-----------------------------------------------------------------------
Global $agOPTIONS[10]
Local $aOPTIONS[12],$oADODB=-1,$aListView1Items[2],$aListView2Items[2],$ListView1Last="",$ListView2Last=""

	If FileExists(@ScriptDir&"\dataloc.ini")=1 Then
		;Load ini
		$aOPTIONS[1]=IniRead(@ScriptDir&"\dataloc.ini","DB","RHOST","")        ;RHOST
		$aOPTIONS[4]=IniRead(@ScriptDir&"\dataloc.ini","DB","WINAUTH","false") ;WINAUTH
		If $aOPTIONS[4]="true" Then _Metro_ToggleCheck($Toggle1)
		$aOPTIONS[5]==IniRead(@ScriptDir&"\dataloc.ini","DB","DBUSER","*")     ;DBUSER
		$aOPTIONS[6]="*"         ;DBPASS
		$aOPTIONS[7]="*"         ;DB
		$aOPTIONS[8]="*"         ;TABLE
		$aOPTIONS[9]="*"         ;COLUMN
		$aOPTIONS[10]="cc"       ;DATATYPE

		$agOPTIONS[1]="true"     ;USE INI
	Else
		;Use hard coded defaults
		$aOPTIONS[1]=GUICtrlRead($Input1) ;RHOST
		$aOPTIONS[4]="false"     ;WINAUTH
		$aOPTIONS[5]="*"         ;DBUSER
		$aOPTIONS[6]="*"         ;DBPASS
		$aOPTIONS[7]="*"         ;DB
		$aOPTIONS[8]="*"         ;TABLE
		$aOPTIONS[9]="*"         ;COLUMN
		$aOPTIONS[10]="cc"       ;DATATYPE

		$agOPTIONS[1]="false"    ;USE INI
		$agOPTIONS[2]=10         ;Per-Column Timeout in min.
		$agOPTIONS[3]=1          ;Use Per-Column Timeout 1=true
	EndIf
	$aListView1Items[0]=0
	$aListView2Items[0]=0
While 1
	;Enable mouse over detection
	_Metro_HoverCheck_Loop($Form1)

	;Clear old messages from status bar
	If _DateDiff('s',$sMSG_Time,_NowCalc()) > 5 Then cout("")

	;Check GUI for user interaction
	$nMsg=GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE,$aControl_Buttons[0]
			;CLOSE_BUTTON
			_Metro_GUIDelete($Form1) ;Delete GUI/release resources
			_SQL_Close($oADODB)
			Exit
		Case $aControl_Buttons[1]
			;MAXIMIZE_BUTTON
			GUISetState(@SW_MAXIMIZE)
		Case $aControl_Buttons[2]
			;RESTORE_BUTTON
			GUISetState(@SW_RESTORE)
		Case $aControl_Buttons[3]
			;MINIMIZE_BUTTON
			GUISetState(@SW_MINIMIZE)
		Case $aControl_Buttons[4],$aControl_Buttons[5]
			;FULLSCREEN_BUTTON
			_Metro_FullscreenToggle($Form1, $aControl_Buttons)
		Case $aControl_Buttons[6]
			;MENU_BUTTON
			Local $MenuSelect=_Metro_MenuStart($Form1,$aControl_Buttons[6],150,$MenuButtonsArray,"Segoe UI",9,0) ; Opens the metro Menu. See decleration of $MenuButtonsArray above.
			Switch $MenuSelect ;Above function returns the index number of the selected button from the provided buttons array.
				Case "0" ;Settings
					_SettingsGUI()
					_GUIDisable($Form1)
				Case "1" ;About
					_AboutGUI()
					_GUIDisable($Form1)
				Case "2" ;Exit
					_Metro_GUIDelete($Form1)
					_SQL_Close($oADODB)
					Exit
			EndSwitch
		Case $Toggle1 ;Toggle authentication type
			If _Metro_ToggleIsChecked($Toggle1) Then
				;SQL Auth
				$aOPTIONS[4]="false"
				_Metro_ToggleUnCheck($Toggle1)
				GUICtrlSetState($Input2,$GUI_Enable)
				GUICtrlSetState($Input3,$GUI_Enable)
			Else
				;Win Auth
				$aOPTIONS[4]="true"
				_Metro_ToggleCheck($Toggle1)
				GUICtrlSetState($Input2,$GUI_Disable)
				GUICtrlSetState($Input3,$GUI_Disable)
			EndIf
		Case $Button1 ;Connect to database
			GUICtrlSetState($Button1,$GUI_Disable)
			$aOPTIONS[1]=GUICtrlRead($Input1) ;RHOST
			$aOPTIONS[5]=GUICtrlRead($Input2) ;DBUSER
			$aOPTIONS[6]=GUICtrlRead($Input3) ;DBPASS
			Local $oADODB=_SQL_Startup()
			ConnectToServer($oADODB,$aOPTIONS)
			If $SQLErr="" Then
				$aListView1Items[0]=ClearListView($ListView1,$aListView1Items)
				$aListView2Items[0]=ClearListView($ListView2,$aListView2Items)
				Local $aResults=_SQL_GetDB($aOPTIONS,"databases")
				If UBound($aResults) > 1 Then
					Local $ComboList="|Select All|"
					For $a=1 To UBound($aResults)-1
						$ComboList=$ComboList&$aResults[$a][0]&"|"
					Next
					$ComboList=StringTrimRight($ComboList,1)
					GUICtrlSetData($Combo1,$ComboList,"Select All")
					GUICtrlSetState($Combo1,$GUI_Enable)
					$aOPTIONS[7]="Select All"
				Else
					GUICtrlSetState($Combo1,$GUI_Enable)
				EndIf
				GUICtrlSetState($Button2,$GUI_Enable)
			EndIf
			GUICtrlSetState($Button1,$GUI_Enable)
		Case $Combo1 ;Database drop down menu
			;Clear old table data
			$aListView1Items[0]=ClearListView($ListView1,$aListView1Items)
			$aListView2Items[0]=ClearListView($ListView2,$aListView2Items)
			$aOPTIONS[7]=GUICtrlRead($Combo1)
			$aOPTIONS[8]="*"         ;TABLE
			$aOPTIONS[9]="*"         ;COLUMN
			$ListView1Last=""
			$ListView2Last=""

			If GUICtrlRead($Combo1)<>"Select All" Then
				;List tables
				Local $aResults=_SQL_GetDB($aOPTIONS,"tables")

				If UBound($aResults) > 1 Then
					ReDim $aListView1Items[UBound($aResults)]
					For $a=1 To UBound($aResults)-1
						$aListView1Items[0]+=1
						$aListView1Items[$a]=GUICtrlCreateListViewItem($aResults[$a][2]&"|"&$aResults[$a][3],$ListView1)
					Next
				EndIf
			EndIf
		Case $Button2 ;Start scanning for data
			GUICtrlSetState($Button1,$GUI_Disable)
			GUICtrlSetState($Button2,$GUI_Disable)
			GUICtrlSetState($ListView1,$GUI_Disable)
			GUICtrlSetState($ListView2,$GUI_Disable)
			cout("Staring payment card search")
			Local $aTargetData=FindData($oADODB,$aOPTIONS)
			cout("Scan complete")
			_ArraySort($aTargetData,1,1,0,1)
			_ArrayDisplay($aTargetData,"Payment Card Data","",0,"|","Match|Confidence|Cell Data|DB.Schema.Table.Column")
			GUICtrlSetState($Button1,$GUI_Enable)
			GUICtrlSetState($Button2,$GUI_Enable)
			GUICtrlSetState($ListView1,$GUI_Enable)
			GUICtrlSetState($ListView2,$GUI_Enable)
		Case $nMsg >=$aListView1Items[1] And $nMsg <=$aListView1Items[0]+$aListView1Items[1]-1 And $aListView1Items[0] > 0;Greater or EQ than first list view item and less than or = last item
			Local $aLV_Indices = _GUICtrlListView_GetSelectedIndices($ListView1,True)
			If $aLV_Indices[0] > 0 And $aLV_Indices[1] <> $ListView1Last Then
				$ListView1Last=$aLV_Indices[1]

				;Get selected listview item data
				Local $aTable1Item=_GUICtrlListView_GetItemTextArray($ListView1,$aLV_Indices[1])
				If $aTable1Item[0] >= 1 Then

					;Remove old column data from listview 2 if exists
					$aListView2Items[0]=ClearListView($ListView2,$aListView2Items)
					$aOPTIONS[8]="*"         ;TABLE
					$aOPTIONS[9]="*"         ;COLUMN
					$ListView2Last=""

					;Query DB for column data associated with selected table
					$aOPTIONS[8]=$aTable1Item[1]  ;TABLE
					Local $aResults=_SQL_GetDB($aOPTIONS,"columns")

					;Populate column list view
					If UBound($aResults) > 1 Then
						ReDim $aListView2Items[UBound($aResults)]
						$aListView2Items[0]=0
						For $a=1 To UBound($aResults)-1
							$aListView2Items[0]+=1
							$aListView2Items[$a]=GUICtrlCreateListViewItem($aResults[$a][3]&"|"&$aResults[$a][7]&"|"&$aResults[$a][8],$ListView2)
						Next
					EndIf
				EndIf
			EndIf
		Case $nMsg >=$aListView2Items[1] And $nMsg <= $aListView2Items[0]+$aListView2Items[1]-1 And $aListView2Items[0] > 0
			;Set target column
			Local $aLV_Indices = _GUICtrlListView_GetSelectedIndices($ListView2,True)
			If $aLV_Indices[0] > 0 And $aLV_Indices[1] <> $ListView2Last Then
				$ListView2Last=$aLV_Indices[1]

				;Get selected listview item data
				Local $aTable2Item=_GUICtrlListView_GetItemTextArray($ListView2,$aLV_Indices[1])
				If $aTable2Item[0] >= 1 Then
					$aOPTIONS[9]=$aTable2Item[1]  ;COLUMN
				EndIf
			EndIf
	EndSwitch
WEnd


;#######################################################################
;		_SettingsGUI - settings GUI menu
;-----------------------------------------------------------------------
Func _SettingsGUI()
	Local $Form2=_Metro_CreateGUI("Settings", 600, 400, -1, -1, True)

	;Add control buttons
	Local $aControl_Buttons_Settings=_Metro_AddControlButtons(True, True, True, True)

	Local $Button1 = _Metro_CreateButton("Close", 250, 340, 100, 40)
	GUICtrlSetResizing($Button1, 768 + 8)
	GUISetState(@SW_SHOW)

	While 1
		_Metro_HoverCheck_Loop($Form2) ;Add hover check in loop
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $aControl_Buttons_Settings[0], $Button1
				;CLOSE_BUTTON
				_Metro_GUIDelete($Form2) ;Delete GUI/release resources, make sure you use this when working with multiple GUIs!
				Return 0
			Case $aControl_Buttons_Settings[1]
				;MAXIMIZE_BUTTON
				GUISetState(@SW_MAXIMIZE)
			Case $aControl_Buttons_Settings[2]
				;RESTORE_BUTTON
				GUISetState(@SW_RESTORE)
			Case $aControl_Buttons_Settings[3]
				;MINIMIZE_BUTTON
				GUISetState(@SW_MINIMIZE)
			Case $aControl_Buttons_Settings[4],$aControl_Buttons_Settings[5]
				;FULLSCREEN_BUTTON
				_Metro_FullscreenToggle($Form2,$aControl_Buttons_Settings)
		EndSwitch
	WEnd
EndFunc

;#######################################################################
;		_AboutGUI - about GUI
;-----------------------------------------------------------------------
Func _AboutGUI()
	Local $Form3=_Metro_CreateGUI("About", 600, 400, -1, -1, True)

	;Add control buttons
	Local $aControl_Buttons_About=_Metro_AddControlButtons(True, True, True, True)

	Local $Button1 = _Metro_CreateButton("Close", 250, 340, 100, 40)
	GUICtrlSetResizing($Button1, 768 + 8)
	GUISetState(@SW_SHOW)

	While 1
		_Metro_HoverCheck_Loop($Form3) ;Add hover check in loop
		$nMsg=GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE,$aControl_Buttons_About[0],$Button1
				;CLOSE_BUTTON
				_Metro_GUIDelete($Form3) ;Delete GUI/release resources, make sure you use this when working with multiple GUIs!
				Return 0
			Case $aControl_Buttons_About[1]
				;MAXIMIZE_BUTTON
				GUISetState(@SW_MAXIMIZE)
			Case $aControl_Buttons_About[2]
				;RESTORE_BUTTON
				GUISetState(@SW_RESTORE)
			Case $aControl_Buttons_About[3]
				;MINIMIZE_BUTTON
				GUISetState(@SW_MINIMIZE)
			Case $aControl_Buttons_About[4],$aControl_Buttons_About[5]
				;FULLSCREEN_BUTTON
				_Metro_FullscreenToggle($Form3,$aControl_Buttons_About)
		EndSwitch
	WEnd
EndFunc

;#######################################################################
;		ClearListView - clear listview data
;-----------------------------------------------------------------------
Func ClearListView($oControlID,$aItems)
	GUICtrlSetState($oControlID,$GUI_Disable)
	If $aItems[0] > 0 Then
		For $a=1 To $aItems[0]
			GUICtrlDelete($aItems[$a])
		Next
		$aItems[0]=0
	EndIf
	GUICtrlSetState($oControlID,$GUI_Enable)
	Return $aItems[0]
EndFunc

;#######################################################################
;		ConnectToServer - init DB connection
;-----------------------------------------------------------------------
Func ConnectToServer($oADODB,$aOPTIONS)
	$SQLErr=""
	;Verify DB host has been specified
	If $aOPTIONS[1]="" Then ;No DB host specified
		$SQLErr="No Host Specified"
		Cout($SQLErr)
		MsgBox(0,"Error","No DB Host Specified",10)
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf

	;Verify DB object was created
	If IsObj($oADODB)=0 Then
		$SQLErr="Invalid ADODB.Connection object"
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf

	;Find SQL driver
	Local $sDriver="{SQL Server}" ;Check for SQL driver
	Local $sTemp = StringMid($sDriver,2,StringLen($sDriver)- 2)
	Local $sKey="HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers",$sVal=RegRead($sKey,$sTemp)
	If @error or $sVal="" Then
		$SQLErr="No SQL driver found"
		Cout($SQLErr)
		MsgBox(0,"Error","No SQL driver found.  Install MSSQL Server Native Client",120)
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf

	;Attempt to connect to database
	Cout("attempting to connect to "&$aOPTIONS[1])

	;Build connection string
	Local $cString="DRIVER="&$sDriver&";SERVER="&$aOPTIONS[1]
	If $aOPTIONS[4]="false" Then ;use SQL auth
		$cString=$cString&";uid="&$aOPTIONS[5]&";pwd="&$aOPTIONS[6]&";"
	Else ;use win auth
		$cString=$cString&";Trusted_Connection=Yes;"
	EndIf

	;Open connection
	_SQL_ConnectionTimeout($oADODB,0)
	$oADODB.Open($cString)
	If Not @error Then
		_SQL_CommandTimeout($oADODB,900)
		Return SetError($SQL_OK,0,$SQL_OK)
	Else
		$SQLErr="Connection Error"
		Cout($SQLErr)
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	Return $oADODB
EndFunc

;#######################################################################
;		_SQL_GetDB - fetch databases, tables, or columns
;-----------------------------------------------------------------------
Func _SQL_GetDB($aOPTIONS,$Target="databases",$oADODB=-1)
	$SQLErr=""
	If $oADODB=-1 Then $oADODB=$SQL_LastConnection
	If IsObj($oADODB)=0 Then
		$SQLErr="Invalid ADODB.Connection object"
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf

	Local $aResults[1][1],$iRows,$iColumns,$SQL_Query,$loc,$aExcludes

	;Build SQL Query
	Switch StringLower($Target)
		Case "databases"
			$aExcludes=GetExcludes("Databases")
			$SQL_Query="USE master;SELECT NAME FROM sysdatabases "
			If $aExcludes[0]>0 Then
				$SQL_Query=$SQL_Query&"WHERE "
				For $a=1 To $aExcludes[0]
					$SQL_Query=$SQL_Query&"(NAME NOT LIKE '"&$aExcludes[$a]&"') AND "
				Next
				$SQL_Query=StringTrimRight($SQL_Query,4);remove trailing AND
			EndIf
			$SQL_Query=$SQL_Query&"ORDER BY NAME;"
		Case "tables"
			$aExcludes=GetExcludes("Tables")
			$SQL_Query='USE '&$aOPTIONS[7]&';'& _
			"SELECT '[' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + ']' "& _
			"AS fulltable_name, SCHEMA_NAME(t.schema_id) AS schema_name, t.name AS table_name, i.rows "& _
			"FROM sys.tables AS t INNER JOIN sys.sysindexes AS i ON t.object_id = i.id AND i.indid < 2 "& _
			"WHERE (ROWS > 0) "
			If $aExcludes[0]>0 Then
				$SQL_Query=$SQL_Query&"AND "
				For $a=1 To $aExcludes[0]
					$SQL_Query=$SQL_Query&"(t.name NOT LIKE '"&$aExcludes[$a]&"') AND "
				Next
				$SQL_Query=StringTrimRight($SQL_Query,4);remove trailing AND
			EndIf
			$SQL_Query=$SQL_Query&"ORDER BY TABLE_NAME;"
		Case "columns"
			$aExcludes=GetExcludes("DataTypes")
			$SQL_Query='USE '&$aOPTIONS[7]&';SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE CHARACTER_MAXIMUM_LENGTH > 14 '
			If $aExcludes[0]>0 Then
				$SQL_Query=$SQL_Query&"AND DATA_TYPE NOT IN ("
				For $a=1 To $aExcludes[0]
					$SQL_Query=$SQL_Query&"'"&$aExcludes[$a]&"',"
				Next
				$SQL_Query=StringTrimRight($SQL_Query,1)
				$SQL_Query=$SQL_Query&") "
			EndIf
			$SQL_Query=$SQL_Query&"AND TABLE_NAME='"&$aOPTIONS[8]&"' "

			$SQL_Query=$SQL_Query&'OR CHARACTER_MAXIMUM_LENGTH < 1 '
			If $aExcludes[0]>0 Then
				$SQL_Query=$SQL_Query&"AND DATA_TYPE NOT IN ("
				For $a=1 To $aExcludes[0]
					$SQL_Query=$SQL_Query&"'"&$aExcludes[$a]&"',"
				Next
				$SQL_Query=StringTrimRight($SQL_Query,1)
				$SQL_Query=$SQL_Query&") "
			EndIf
			$SQL_Query=$SQL_Query&"AND TABLE_NAME='"&$aOPTIONS[8]&"'"

			$SQL_Query=$SQL_Query&" ORDER BY COLUMN_NAME;"
	EndSwitch

	;Query Database
	_SQL_GetData2D($oADODB,$SQL_Query,$aResults,$iRows,$iColumns)

	Return $aResults
EndFunc

;#######################################################################
;		FindData - search extraction target for DATATYPE
;-----------------------------------------------------------------------
Func FindData($oADODB,$aOPTIONS)
	Local $aTargetData[1][4],$aResults
	$aTargetData[0][0]=0

	;Build array of target databases for scanning
	Local $aDataBases=DefineScanTargets("databases",$aOPTIONS)

	For $a=1 To UBound($aDataBases)-1 ;Loop through all DB targets
		$aOPTIONS[7]=$aDataBases[$a]
		If UBound($aDataBases)>2 Then $aOPTIONS[8]="*" ;TABLE

		;Build array of target Tables for the selected Database
		Local $aTables=DefineScanTargets("tables",$aOPTIONS)

		If $aTables[1][0]<>"" Then
			For $b=1 To UBound($aTables)-1 ;Loop through all TABLE targets
				$aOPTIONS[8]=$aTables[$b][0]
				If UBound($aTables)>2 Then $aOPTIONS[9]="*" ;COLUMN

				;Build array of target Columns for the selected Database/Table
				Local $aColumns=DefineScanTargets("columns",$aOPTIONS)

				If $aColumns[1][0]<>"" Then
					For $c=1 To UBound($aColumns)-1 ;Loop through all COLUMN targets
						$aOPTIONS[9]=$aColumns[$c][0]
						;We have target DB|TABLE|COLUMN time to scan

						;Move column data into 1d array
						Local $aColumn[4]
						$aColumn[0]=$aColumns[$c][0] ;Name
						$aColumn[1]=$aColumns[$c][1] ;DataType
						$aColumn[2]=$aColumns[$c][2] ;Length
						$aColumn[3]=$aColumns[$c][3] ;Schema
						$aTables[$b][2]="["&$aColumns[$c][3]&"].["&$aTables[$b][0]&"]" ;Schema|TableName

						;Pre-process scan target data  DataBase|Schema|Table|Column
						Cout("Pre-Proc: "&$aDataBases[$a]&"|"&$aColumn[3]&"|"&$aTables[$b][0]&"|"&$aColumns[$c][0]&@CRLF)
						MSSQLPreMatch($aDataBases[$a],$aTables[$b][2],$aColumn)
						If StringInStr($SQLErr,"80030009") Then
							Cout("Unable to create temp table"&@CRLF)
							MsgBox(0,"SQL Error","Unable to create temp table",120)
							return ;this could use a slower method of data collection instead of just quiting
						EndIf

						;Pull remaining data over the wire for post-processing
						Local $PullCount=0
						Switch $aColumn[2] ;Cell length
							Case 1 To 20
								$PullCount=5000
							Case 21 To 50
								$PullCount=4000
							Case 51 To 100
								$PullCount=2500
							Case 101 To 500
								$PullCount=1800
							Case 501 To 1000
								$PullCount=1200
							Case 1001 To 2000
								$PullCount=800
							Case Else
								$PullCount=300
						EndSwitch

						Local $ColumnProcStart=_NowCalc()
						For $e=1 To $aTables[$b][1] Step $PullCount ;Loop through all records in #dataloc
							Local $sQuery="SELECT * FROM #dataloc WHERE (RowNumber >="&$e&" AND RowNumber <="&$e+$PullCount-1&") ORDER BY RowNumber;"
							Local $aPreProc[1][1],$iRows=0,$iColumns=0
							_SQL_GetData2D($oADODB,$sQuery,$aPreProc,$iRows,$iColumns)
							If $iRows>1 And $iColumns>1 Then
								Cout("Post-Proc: "&$aDataBases[$a]&"|"&$aTables[$b][0]&"|"&$aColumns[$c][0]&"| rows "&$e&"-"&$e+$PullCount-1&@CRLF)
								Local $aTempTargetData=PostProcessing($aOPTIONS,$aPreProc)
								If $aTempTargetData[0][0]<>"0" Then
									For $g=1 To UBound($aTempTargetData)-1
										If $aTempTargetData[$g][0]<>"" Then
											$aTargetData[0][0]+=1
											ReDim $aTargetData[$aTargetData[0][0]+1][4]
											$aTargetData[$aTargetData[0][0]][0]=$aTempTargetData[$g][0] ;Match
											$aTargetData[$aTargetData[0][0]][1]=$aTempTargetData[$g][1] ;Confidence
											$aTargetData[$aTargetData[0][0]][2]=$aTempTargetData[$g][2] ;Full Cell
											$aTargetData[$aTargetData[0][0]][3]=$aDataBases[$a]&"."&$aColumn[3]&"."&$aTables[$b][0]&"."&$aColumn[0] ;Location
										EndIf
									Next
								EndIf
							Else
								ExitLoop
							EndIf

							;Column Timeout
							If _DateDiff('n',$ColumnProcStart,_NowCalc()) >= $agOPTIONS[2] And $agOPTIONS[3]=1 Then ExitLoop
						Next
					Next
				EndIf
			Next
		EndIf
	Next
	_SQL_Execute($oADODB,"IF (EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME "& _
						"LIKE '#dataloc%')) BEGIN DROP TABLE #dataloc END;")
	Return $aTargetData
EndFunc

;#######################################################################
;		DefineScanTargets - build an array of targets for scanning
;-----------------------------------------------------------------------
Func DefineScanTargets($Type,$aOPTIONS)
	Local $aResults
	Switch StringLower($Type)
		Case "databases"
			;Build an array of databases for scanning
			If $aOPTIONS[7] = "Select All" Then ;No DB targeted SCAN IT ALL!
				;Get Databases
				$aResults = _SQL_GetDB($aOPTIONS,"databases")
				If UBound($aResults) > 1 Then
					Local $aDataSet[UBound($aResults)]
					For $d = 1 To UBound($aResults)-1
						$aDataSet[$d] = $aResults[$d][0]
					Next
				Else ;No valid scan targets
					Local $aDataSet[2]
					Cout("No databases found")
				EndIf
			Else ;Single target
				Local $aDataSet[2]
				$aDataSet[1] = $aOPTIONS[7]
			EndIf
		Case "tables"
			;Build an array of tables for selected database
			$aResults = _SQL_GetDB($aOPTIONS,"tables")
			If UBound($aResults) > 1 Then
				If $aOPTIONS[8] = "*" Then ;No TABLE targeted SCAN THEM ALL!
					Local $aDataSet[UBound($aResults)][3]
					For $d = 1 To UBound($aResults)-1
						$aDataSet[$d][0] = $aResults[$d][2] ;Name
						$aDataSet[$d][1] = $aResults[$d][3] ;Row Count
						$aDataSet[$d][2] = $aResults[$d][0] ;Full Table Name
					Next
				Else ;Target defined.  Build single target array
					Local $aDataSet[2][3]
					For $d = 1 To UBound($aResults)-1
						;Search for selected item and gather additional details
						If $aResults[$d][2] = $aOPTIONS[8] Then
							$aDataSet[1][0] = $aResults[$d][2] ;Name
							$aDataSet[1][1] = $aResults[$d][3] ;Row Count
							$aDataSet[1][2] = $aResults[$d][0] ;Full Table Name
							ExitLoop
						EndIf
					Next
				EndIf
			Else
				;Tables - No valid scan targets
				Local $aDataSet[2][3]
			EndIf
		Case "columns"
			;Build an array of columns for selected table
			$aResults = _SQL_GetDB($aOPTIONS,"columns")
			If UBound($aResults) > 1 Then
				If $aOPTIONS[9] = "*" Then ;No COLUMN targeted SCAN THEM ALL!
					Local $aDataSet[UBound($aResults)][4]
					For $d=1 To UBound($aResults)-1
						$aDataSet[$d][0] = $aResults[$d][3] ;Name
						$aDataSet[$d][1] = $aResults[$d][7] ;Type
						$aDataSet[$d][2] = $aResults[$d][8] ;Length
						$aDataSet[$d][3] = $aResults[$d][1];Schema
					Next
				Else ;Target defined.  Build single item array
					Local $aDataSet[2][4]
					For $d = 1 To UBound($aResults)-1
						;Search for selected item and gather additional details
						If $aResults[$d][3] = $aOPTIONS[9] Then
							$aDataSet[1][0] = $aResults[$d][3] ;Name
							$aDataSet[1][1] = $aResults[$d][7] ;Type
   							$aDataSet[1][2] = $aResults[$d][8] ;Length
							$aDataSet[1][3] = $aResults[$d][1];Schema
							ExitLoop
						EndIf
					Next
				EndIf
			Else
				;Columns - No valid scan targets
				Local $aDataSet[2][4]
			EndIf
	EndSwitch
	Return $aDataSet
EndFunc

;#######################################################################
;		PostProcessing - $aPreProc RowNumber|ColumnName[0][1]&CellData[1][1]
;-----------------------------------------------------------------------
Func PostProcessing($aOPTIONS,$aPreProc)
	Local $aTargetData[1][3] ;Match|Confidence|OriginalCellData
	$aTargetData[0][0]="0"

	Local $aRegexPattern[5]
	;American Express starts with 34 or 37 and has 15 digits
	$aRegexPattern[1]="(?<![0-9])3\D{0,4}(4|7)(\D{0,4}\d){13}[^0-9]"
	;Discover begin with 6011 or 65. All have 16 digits.
	$aRegexPattern[2]="(?<![0-9])6\D{0,4}(5(\D{0,4}\d){14}(\D?|$)|0\D{0,4}1\D{0,4}1(\D{0,4}\d){12})[^0-9]"
	;MasterCard  start with 50 through 55. 16 digits
	$aRegexPattern[3]="(?<![0-9])5\D{0,4}(0-5)(\D{0,4}\d){14}[^0-9]"
	;Visa All cards start with 4 length is 13-16 digits. Only checking for 16 since 13 digit cards expired a long time ago.
	$aRegexPattern[4]="(?<![0-9])4(\D{0,4}\d){15}[^0-9]"

	For $a=1 To UBound($aPreProc)-1
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],@CR,"")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],@LF,"")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#34;",'"')
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#38;","&")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#39;","'")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#40;","(")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#41;",")")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#60;","<")
		$aPreProc[$a][1]=StringReplace($aPreProc[$a][1],"&#62;",">")
		For $b = 1 To UBound($aRegexPattern)-1
			;Find all possable matches
			Local $aRegexResults=StringRegExp($aPreProc[$a][1],$aRegexPattern[$b],4)
			If @error=0 Then
				;Cycle through all maches from the specific cell
				For $c=0 To UBound($aRegExResults)-1
					Local $aMatch=$aRegExResults[$c]
					Local $NumericMatch=StringRegExpReplace($aMatch[0],"\D","")
					If _LuhnCheck($NumericMatch)="True" Then
						Local $aAnalysisTarget[3]
						$aAnalysisTarget[0]=$NumericMatch      ;Match
						$aAnalysisTarget[1]=50                 ;Confidence
						$aAnalysisTarget[2]=$aPreProc[$a][1]   ;FullCellContents

					;Score Finding
						$aAnalysisTarget[1]=ConfidenceDelimiters($aAnalysisTarget[1],$aMatch[0])
						$aAnalysisTarget[1]=ConfidenceKeyWords($aAnalysisTarget[0],$aAnalysisTarget[1],$aAnalysisTarget[2])
						$aAnalysisTarget[1]=ConfidenceIINCheck($aAnalysisTarget[0],$aAnalysisTarget[1])
						$aAnalysisTarget[1]=ConfidenceMiscTests($aAnalysisTarget[1],$aMatch[0],$aAnalysisTarget[2])

						;Add finding if threshhold met
						If $aAnalysisTarget[1] > 1 Then
							If $aAnalysisTarget[1] > 99 Then $aAnalysisTarget[1]=99
							$aTargetData[0][0]+=1
							_ArrayAdd($aTargetData,$aAnalysisTarget[0]&"|"&$aAnalysisTarget[1]&"|"&$aAnalysisTarget[2])
						EndIf

					EndIf
				Next
			EndIf
		Next
	Next
	Return $aTargetData
EndFunc

;#######################################################################
;		ConfidenceMiscTests - Adjust score based on additional patterns
;-----------------------------------------------------------------------
Func ConfidenceMiscTests($Score,$FullMatch,$CellData)
	Local $Delimiters=StringRegExpReplace($FullMatch,"\d","")
	$Delimiters=StringStripWS($Delimiters,8)

	;Trim extras
	If IsNumber(StringLeft($FullMatch,1))=0 Then $FullMatch=StringTrimLeft($FullMatch,1)
	If IsNumber(StringRight($FullMatch,1))=0 Then $FullMatch=StringTrimRight($FullMatch,1)
	;Escape specials
	$FullMatch=StringReplace($FullMatch,"\","\\")
	$FullMatch=StringReplace($FullMatch,".","\.")
	$FullMatch=StringReplace($FullMatch,"^","\^")
	$FullMatch=StringReplace($FullMatch,"$","\$")
	$FullMatch=StringReplace($FullMatch,"|","\|")
	$FullMatch=StringReplace($FullMatch,"[","\[")
	$FullMatch=StringReplace($FullMatch,"(","\(")
	$FullMatch=StringReplace($FullMatch,"{","\{")
	$FullMatch=StringReplace($FullMatch,"*","\*")
	$FullMatch=StringReplace($FullMatch,"+","\+")
	$FullMatch=StringReplace($FullMatch,"?","\?")
	$FullMatch=StringReplace($FullMatch,"#","\#")
	$FullMatch=StringReplace($FullMatch,"]","\]")
	$FullMatch=StringReplace($FullMatch,")","\)")
	$FullMatch=StringReplace($FullMatch,"}","\}")

	If StringRegExp(StringLower($Delimiters),"[a-z]\D",0)=1 Then $Score+=-40 ;Reduce score if letters exist as delimiters
	If StringRegExp($CellData,"[0-9][^0-9]"&$FullMatch,0)=1 Then $Score+=-50 ;
	If StringRegExp($CellData,$FullMatch&"\D[0-9]{3}\D",0)=1 Then $Score+=5  ;
	Return $Score
EndFunc

;#######################################################################
;		ConfidenceKeyWords - Adjust score based on Cell data key words
;-----------------------------------------------------------------------
Func ConfidenceKeyWords($NumericMatch,$Score,$CellData)

	;Card specific checks
	Switch StringLeft($NumericMatch,1)
		Case 3 ;American Express
			If StringInStr($CellData,"amex") > 0 Then $Score+=10
			If StringInStr($CellData,"american") > 0 Then $Score+=5
			If StringInStr($CellData,"express") > 0 Then $Score+=5
		Case 4 ;Visa
			If StringInStr($CellData,"visa") > 0 Then $Score+=10
		Case 5 ;MasterCard
			If StringInStr($CellData,"mastercard") > 0 Then $Score+=10
		Case 6 ;Discover
			If StringInStr($CellData,"discover") > 0 Then $Score+=10
	EndSwitch

	;Generic checks
	If StringInStr($CellData," cc") > 0 Then $Score+=5     ;
	If StringInStr($CellData,"aaa") > 0 Then $Score+=-25   ;Triple A membership number
	If StringInStr($CellData,"billing") > 0 Then $Score+=5 ;
	If StringInStr($CellData,"card") > 0 Then $Score+=5    ;
	If StringInStr($CellData,"credit") > 0 Then $Score+=5  ;
	If StringInStr($CellData,"cvv") > 0 Then $Score+=10    ;
	If StringInStr($CellData,"payment") > 0 Then $Score+=5 ;

	Return $Score
EndFunc

;#######################################################################
;		ConfidenceDelimiters - Adjust score based on number and type of delimiters
;-----------------------------------------------------------------------
Func ConfidenceDelimiters($Score,$Match)
	;Find the total number of spaces used by delimiters
	Local $Delimiters=StringRegExpReplace($Match,"\d","")
	$Delimiters=StringStripWS($Delimiters,8)

	;Find the number of unique delimiter types "-/+" = 3 for example
	Local $DelimTypeCount=GetDelimiterTypeCount($Delimiters)

	;Adjust score based on number and type of delimiters
	If StringLen($Delimiters) <= 4 Then
		Switch $DelimTypeCount
			Case 0
				$Score+=15
			Case 1
				$Score+=10
			Case 2
				$Score+=5
			Case 3
				$Score+=-20
			Case Else
				$Score+=-25
		EndSwitch
	Else
		Switch $DelimTypeCount
			Case 1
				$Score+=15
			Case 2
				$Score+=-10
			Case 3
				$Score+=-30
			Case Else
				$Score+=-40
		EndSwitch
	EndIf

	Return $Score
EndFunc

;#######################################################################
;		ConfidenceIINCheck - Adjust score based known issuer ID in card number
;-----------------------------------------------------------------------
;The first 6 digits of a credit card number are known as the Issuer Identification Number (IIN)
Func ConfidenceIINCheck($ExactMatch,$Score)
	Local $MatchIIN, $bMF=0, $aIINList[1]

	;6 digit checks
	$aIINList=IINGetList(StringLeft($ExactMatch,1),6)
	$MatchIIN=StringLeft($ExactMatch,6)
	For $a=0 To UBound($aIINList)-1
		If $MatchIIN=$aIINList[$a] Then
			$Score+=10
			$bMF=1
			ExitLoop
		EndIf
	Next

	If $bMF=0 Then
		;4 digit checks
		$aIINList=IINGetList(StringLeft($ExactMatch,1),4)
		$MatchIIN=StringLeft($ExactMatch,4)
		For $a=0 To UBound($aIINList)-1
			If $MatchIIN=$aIINList[$a] Then
				$Score+=5
				$bMF=1
				ExitLoop
			EndIf
		Next
	EndIf

	;No match
	If $bMF=0 Then $Score+=-5
	Return $Score
EndFunc

;#######################################################################
;		IINGetList - return a 0 based array of IINs of specified length and starting digit
;-----------------------------------------------------------------------
;IIN Lists sourced from:
;http://www.stevemorse.org/ssn/List_of_Bank_Identification_Numbers.html
Func IINGetList($FirstDigit,$Length)
	Switch $FirstDigit
		Case 3 ;American Express
			Switch $Length
				Case 6
					Local $aIINList[57]
					$aIINList[0]=337941	;PL	Bank Millennium	American Express Gold Credit Card
					$aIINList[1]=370266	;US	American Express	Prepaid Card
					$aIINList[2]=372301	;CA	American Express	Gift Card
					$aIINList[3]=372395  ;	American Express	Blue Cash Express Card
					$aIINList[4]=372550	;	American Express	Starwood Preferred Guest hotel loyalty credit card
					$aIINList[5]=372734	;	American Express	Blue for Business credit (small business)
					$aIINList[6]=372741	;US	American Express	SERVE Preferred Client Card
					$aIINList[7]=372888	;US	American Express	Gold Card
					$aIINList[8]=372863	;US	American Express	Platinum Card
					$aIINList[9]=373275	;	American Express	Business
					$aIINList[10]=374283	;UK	American Express	Preferred Rewards Gold Card
					$aIINList[11]=374288	;UK	American Express	Centurion Charge Card
					$aIINList[12]=374289	;UK	American Express	Platinum Charge Card
					$aIINList[13]=374314	;US	Bank of America	American Express
					$aIINList[14]=374322	;US	Bank of America	American Express
					$aIINList[15]=374326	;US	American Express	Gift Card
					$aIINList[16]=374328	;US	American Express	Gift Card
					$aIINList[17]=374345	;US	Citibank	American Express Cards
					$aIINList[18]=374350	;US	Citibank	American Airlines credit card
					$aIINList[19]=374604	;	American Express	Platinum Credit Card (UK)
					$aIINList[20]=374614	;	American Express	British Airways Premium Plus card
					$aIINList[21]=374622	;FR	American Express	Optima Credit Card
					$aIINList[22]=374654	;DE	American Express	Blue Card
					$aIINList[23]=374660	;	American Express	[BMW] card
					$aIINList[24]=374661	;	American Express	BMW card
					$aIINList[25]=374671	;	American Express	Blue card
					$aIINList[26]=374691	;UK	American Express	Platinum credit card
					$aIINList[27]=374693	;UK	American Express	Platinum credit card
					$aIINList[28]=374716	;US	FIA Card Services	Fidelity Rewards American Express card
					$aIINList[29]=374801	;FI	American Express	Platinum Charge card
					$aIINList[30]=374970	;FR	American Express	Air France KLM Flying Blue co-branded Gold Charge Card
					$aIINList[31]=374996	;FR	American Express	Corporate Card
					$aIINList[32]=375142	;CN	American Express	Tencent Holdings TenPay Prepaid Card
					$aIINList[33]=375415  ;AU	Commonwealth Bank of Australia
					$aIINList[34]=375416  ;AU	Commonwealth Bank of Australia	Platinum card
					$aIINList[35]=375549  ;ES	Swedbank	American Express Blue/Gold
					$aIINList[36]=375622	;TR	Garanti Bank	American Express Green Card
					$aIINList[37]=375628	;TR	Garanti Bank	American Express Shop&Miles co-branded Gold Card
					$aIINList[38]=375790	;SE	American Express	Corporate card
					$aIINList[39]=376211	;SG		Singapore Airlines Krisflyer American Express Gold Credit Card
					$aIINList[40]=376317	;SG	UOB	PRVI Miles
					$aIINList[41]=376966	;CN	China CITIC Bank	American Express Card
					$aIINList[42]=376968	;CN	China CITIC Bank	American Express Gold Card
					$aIINList[43]=370286	;CN	China Merchants Bank	American Express Gold Card
					$aIINList[44]=377032	;VE		American Express Corp-Banca / Banco Occidental de Descuento
					$aIINList[45]=377064	;UK	Lloyds TSB	Airmiles Premier American Express Card
					$aIINList[46]=377100	;HK	American Express	Platinum credit card
					$aIINList[47]=377130	;UK	MBNA Europe Bank (Bank of America)	bmi Credit Card
					$aIINList[48]=377165	;HK	Citibank (Hong Kong)	Citibank Cash Back American Express® Card
					$aIINList[49]=377311	;UK	MBNA Europe Bank (Bank of America)	bmi plus Credit Card
					$aIINList[50]=377311	;UK	MBNA Europe Bank (Bank of America)	Virgin Atlantic Credit Card
					$aIINList[51]=377441	;NZ	American Express	Black Card
					$aIINList[52]=377445	;NZ		BMW American Express Card
					$aIINList[53]=377687	;UK	Lloyds TSB	Avios Premier American Express Card (Project Verde)
					$aIINList[54]=377705	;AU	American Express Australia Limited	David Jones Storecard with Rewards
					$aIINList[55]=377826	;CL	Banco Santander	Club de Lectores El Mercurio
					$aIINList[56]=377878	;AU	National Australia Bank
				Case 4
					Local $aIINList[26]
					$aIINList[0]=3712	;	American Express	Costco Wholesale Executive Card
					$aIINList[1]=3713	;	American Express	Delta SkyMiles Platinum Card
					$aIINList[2]=3715	;	American Express	Centurion Card
					$aIINList[3]=3717	;	American Express	Platinum Card
					$aIINList[4]=3723	;	American Express	Costco Wholesale Platinum Card
					$aIINList[5]=3727	;CA	American Express	Gold Air Miles Card
					$aIINList[6]=3732	;CA	American Express	Blue Airmiles cash back card
					$aIINList[7]=3733	;CA	American Express	Blue Airmiles Card / SPG Credit Card / Aeroplan Plus Platinum / Business Platinum Charge Card
					$aIINList[8]=3735	;CA	American Express	Gold Cash Back Card / Platinum Charge Card
					$aIINList[9]=3742	;UK	American Express	Charge Card
					$aIINList[10]=3743	;UK	American Express	International Euro Charge Card
					$aIINList[11]=3745	;UK	American Express	International Dollar Charge Card
					$aIINList[12]=3750	;DE	American Express	American Express Germany Products
					$aIINList[13]=3751	;FI	American Express
					$aIINList[14]=3752	;IT	American Express
					$aIINList[15]=3753	;NL	American Express
					$aIINList[16]=3758	;CH	American Express	Corporate card
					$aIINList[17]=3759	;HK		American Express Cathay Pacific Credit Card
					$aIINList[18]=3760	;AU		American Express Card Australia and American Express UK Nectar Credit Card
					$aIINList[19]=3763	;HK	American Express
					$aIINList[20]=3770	;UK	Lloyds TSB	Airmiles American Express Card
					$aIINList[21]=3764	;	American Express	Credit Card
					$aIINList[22]=3766	;MX	American Express, Platinum, Sri Lanka	Charge card
					$aIINList[23]=3767	;MX	American Express	Platinum credit card
					$aIINList[24]=3772	;	American Express	Starwood Preferred Guest hotel loyalty credit card
					$aIINList[25]=3797	;US	American Express	Delta SkyMiles Gold Card
			EndSwitch
		Case 4 ;Visa
			Switch $Length
				Case 6
					Local $aIINList[791]
					$aIINList[0]=499904 ;- Bank of New Zealand VISA Platinum Credit Card
					$aIINList[1]=400115 ;- Visa Electron Barclays
					$aIINList[2]=400121 ;- Electron IRL
					$aIINList[3]=400273 ;- Bank of Palestine
					$aIINList[4]=400344 ;- CapitalOne Platinum
					$aIINList[5]=400610 ;- META Bank, (Rewards 660 Visa) Credit Limit Between $200 & $2000
					$aIINList[6]=400837 ;- Electron GWK Bank NV
					$aIINList[7]=400838 ;- Electron GWK Bank NV
					$aIINList[8]=400839 ;- Electron GWK Bank NV
					$aIINList[9]=400975 ;- Citi Bank Hong Kong
					$aIINList[10]=400917 ;- Visa Infinite by Citibank Peru
					$aIINList[11]=400937 ;- Bank of China Great Wall International Card Corporate (CN)
					$aIINList[12]=400938 ;- Bank of China Great Wall International Card Corporate Gold (CN)
					$aIINList[13]=400941 ;- Bank of China Great Wall International Card (CN)
					$aIINList[14]=400942 ;- Bank of China Great Wall International Card Gold (CN)
					$aIINList[15]=400944 ;- Associated Bank (Citibank (South Dakota) N.A.)
					$aIINList[16]=401106 ;- McCoy Federal Credit Union VISA debit card
					$aIINList[17]=401171 ;- Delta Community Credit Union Visa
					$aIINList[18]=401180 ;- Suntrust Bank Debit Card
					$aIINList[19]=401343 ;- Tesco Bank Bonus Visa
					$aIINList[20]=401344 ;- Tesco Bank Clubcard Visa
					$aIINList[21]=401612 ;- Banco Tequendama Visa CREDIT PLATINUM CARD (Colombia)
					$aIINList[22]=401773 ;- Electron IRL
					$aIINList[23]=401786 ;- Deutsche Postbank AG (Germany); Plus ATM Card
					$aIINList[24]=401795 ;- NAB Visa Debit Card (Australia)
					$aIINList[25]=402360 ;- Visa Electron from Poste Italiane (Italy) brand name "PostePay", Max. balance 3000
					$aIINList[26]=402367 ;- Hana SK Card (KR) Visa Platinum Check Card
					$aIINList[27]=402396 ;- Vanquis Bank Visa credit card (UK)
					$aIINList[28]=402802 ;- Handelsbanken Visa Credit/Debit Card
					$aIINList[29]=402856 ;- Citi Bank (Hong Kong)
					$aIINList[30]=403216 ;- Navy Federal Credit Union
					$aIINList[31]=403594 ;- credit cards issued by Deutsche Postbank AG (Germany)
					$aIINList[32]=403675 ;- Visa Classic Debit Krasnodar Regional Investment Bank
					$aIINList[33]=403677 ;- Visa Electron Debit Krasnodar Regional Investment Bank
					$aIINList[34]=403766 ;- U.S. Bank National Association, Visa Credit Card
					$aIINList[35]=403897 ;- Avangard Bank, Visa Credit/Debit Card
					$aIINList[36]=404195 ;- MetaBank, Visa Prepaid Card (USA)
					$aIINList[37]=404137 ;- Greater Building Society Visa Debit Card (Australia)
					$aIINList[38]=404146 ;- National Development Bank Visa Classic (Sri Lanka)
					$aIINList[39]=404159 ;- China CITIC Bank Visa Platinum (China)
					$aIINList[40]=404527 ;- Cabela's World's Foremost Bank
					$aIINList[41]=404586 ;- Open Bank, Russia ;- Visa Platinum Transaero Card
					$aIINList[42]=404645 ;- US Bank Visa Debit Card (USA)
					$aIINList[43]=405623 ;- Bank Respublika (Azerbaijan)
					$aIINList[44]=405625 ;- OGPF Bank (Ot Gusaa Posle Fostata) Debit Electron Cyprus
					$aIINList[45]=405670 ;- BRE Bank (mBank) Visa Electron Debit Card (Poland)
					$aIINList[46]=405851 ;- Shinhan Card Visa prepaid card (KR)
					$aIINList[47]=405856 ;- Shinhan Card Visa prepaid card (KR)
					$aIINList[48]=405803 ;- Standard Chartered (Hong Kong)
					$aIINList[49]=405919 ;- HSBC Bank A.S. Debit Electron (Turkey)
					$aIINList[50]=406366 ;- Guangdong Development Bank China Southern Visa UnionPay Duo Credit Card
					$aIINList[51]=406632 ;- VISA Debit ;- LGE Community Credit Union
					$aIINList[52]=406669 ;- Visa,Banco Bradesco, BRAZIL
					$aIINList[53]=406707 ;- Visa, Bank24.ru, Russia
					$aIINList[54]=406742 ;- Entropay Virtual Visa Card USD
					$aIINList[55]=406774 ;- Visa Platinum credit card, Banco Interamericano de Finanzas ;- Interamerican finances bank ;- BIF
					$aIINList[56]=407220 ;- ANZ Frequent Flyer Gold Visa Card
					$aIINList[57]=407264 ;- Heritage Bank VISA (Australia)
					$aIINList[58]=407441 ;- CitiBank Patriot Memory Promo Debit Card
					$aIINList[59]=407444 ;- CSL Plasma and Other Various Plasma Donation Centers
					$aIINList[60]=407714 ;- Visa Gift Card
					$aIINList[61]=408461 ;- Visa ;- BIA Niger ;- Morocco
					$aIINList[62]=408586 ;- TD U.S. Dollar
					$aIINList[63]=409311 ;- Branch Banking & Trust Classic Credit Card USA
					$aIINList[64]=409617 ;- First Czech;-Russian bank, Russia, Visa Gold Czech Airlines
					$aIINList[65]=409908 ;- Visa(card brand), Debit(card type), Classic(card level), Regional federal credit union (=Regional F.C.U,bank name)
					$aIINList[66]=410162 ;- Entropay Virtual Visa
					$aIINList[67]=410489 ;- Bancorp prepaid (USA)
					$aIINList[68]=410504 ;- Bank Negara Indonesia (ID) Visa Credit Card
					$aIINList[69]=410505 ;- Bank Negara Indonesia (ID) Visa Credit Card
					$aIINList[70]=410506 ;- Bank Negara Indonesia (ID) Visa Credit Card
					$aIINList[71]=410635 ;- Columbus Bank & Trust Company, (Aspire Visa Gold Card)
					$aIINList[72]=410636 ;- Columbus Bank & Trust Company, (Aspire Visa Gold Card)
					$aIINList[73]=410637 ;- Columbus Bank & Trust Company, (Aspire Visa Gold Card)
					$aIINList[74]=410638 ;- Columbus Bank & Trust Company, (Aspire Visa Gold Card)
					$aIINList[75]=410639 ;- Columbus Bank & Trust Company, (Aspire Visa Gold Card)
					$aIINList[76]=410651 ;- SR;-BANK1 (NOR) ;- Visa Credit Card
					$aIINList[77]=410654 ;- Ithala Limited (South Africa) VISA Electron
					$aIINList[78]=410773 ;- CRDB Bank (Tanzania) VISA Debit Card
					$aIINList[79]=410894 ;- Branch Banking and Trust (BB&T)
					$aIINList[80]=410897 ;- The Golden 1 Credit Union (US) Visa Classic
					$aIINList[81]=411016 ;- BANESCO (former BancUnion Visa). Visa Platinum ;- Venezuela.
					$aIINList[82]=411298 ;- Lloyds TSB (UK) ;- Visa Credit Card
					$aIINList[83]=411636 ;- Irish Life & Permanent PLC Visa Debit Classic
					$aIINList[84]=411773 ;- Bank of America (US; formerly Fleet) Temporary VISA Debit Card (Embossed name ;- Preferred Customer)
					$aIINList[85]=411911 ;- DBS (SG) ;- Live Fresh Platinum Visa Credit Card
					$aIINList[86]=411945 ;- Masterbank (Russia), Visa Infinite
					$aIINList[87]=411986 ;- Banca Transilvania ;- Visa Credit Card
					$aIINList[88]=412134 ;- Pennsylvania State Employees Credit Union (PSECU) Credit Card
					$aIINList[89]=412174 ;- Capital One Platinum
					$aIINList[90]=412266 ;- TD Bank Gift Card
					$aIINList[91]=412722 ;- The International Bank of Azerbaijan
					$aIINList[92]=412921 ;- Visa Electron
					$aIINList[93]=412922 ;- Visa Electron
					$aIINList[94]=412923 ;- Visa Electron
					$aIINList[95]=412983 ;- MBNA (Europe) University of Cambridge VISA Credit Card
					$aIINList[96]=412984 ;- Sovereign Bank ;- Visa Debit Card
					$aIINList[97]=412985 ;- Sovereign Bank ;- Visa Debit Card
					$aIINList[98]=413002 ;- Ally Bank (US) Visa Classic Check Card
					$aIINList[99]=413433 ;- Sovereign Bank Business Check Card
					$aIINList[100]=413718 ;- Bank Mandiri ;- Visa Platinum Credit Card (Indonesia)
					$aIINList[101]=414049 ;- Banca Transilvania ;- Visa Electron
					$aIINList[102]=414051 ;- Bank of Georgia (GE) ;- Visa Orange Debit Card
					$aIINList[103]=414099 ;- Budapest Bank, Visa Electron, Hungary
					$aIINList[104]=414588 ;- Guaranty Bank Visa Debit card USA
					$aIINList[105]=414711 ;- Citibank (American Airlines) Visa Signature Credit Card
					$aIINList[106]=414716 ;- Bank of America (US) ;- Alaska Airlines Signature Visa Credit Card
					$aIINList[107]=414718 ;- Wells Fargo Bank 1;-800;-228;-1122
					$aIINList[108]=414720 ;- Chase (US, formerly Bank One) ;- Chase Sapphire or Holiday Inn Priority Club Rewards Visa Credit Card
					$aIINList[109]=414740 ;- Chase ;- Amazon.com Rewards Card Visa Signature Credit Card
					$aIINList[110]=414746 ;- Citibank (SG) ;- PremierMiles Visa Signature Credit Card
					$aIINList[111]=414780 ;- US Bank
					$aIINList[112]=414840 ;- Chase ;- Amazon.com Rewards Card Visa Signature Credit Card
					$aIINList[113]=414950 ;- OJSC RAIFFEISEN BANK AVAL (UA) ;- Visa
					$aIINList[114]=414951 ;- OJSC RAIFFEISEN BANK AVAL (UA) ;- Visa
					$aIINList[115]=414983 ;- Plumas Bank (California, US) ;- Visa Check Card
					$aIINList[116]=415045 ;- Kredyt Bank Visa Business Electron (Poland)
					$aIINList[117]=415055 ;- Le Crédit Lyonnais, France ;- Visa Cleo
					$aIINList[118]=415231 ;- Bancomer Debit Card
					$aIINList[119]=415461 ;- Raiffeisen Bank (CZ) ;- Visa Debit
					$aIINList[120]=415786 ;- Fifth and Third Bank ;- 1;-800;-991;-9911
					$aIINList[121]=415874 ;- TD Bank (USA)
					$aIINList[122]=415929 ;- Cahoot (UK) ;- Visa Credit Card
					$aIINList[123]=415981 ;- Sovereign Bank ;- Visa Debit Card
					$aIINList[124]=416039 ;- ING Bank Śląski (PL) ;- Visa Electron
					$aIINList[125]=416451 ;- Fortis Bank (PL) ;- Visa Electron
					$aIINList[126]=416724 ;- Wells Fargo Bank Debit Visa USA
					$aIINList[127]=416896 ;- Inteligo (PL) ;- Visa Electron
					$aIINList[128]=417008 ;- Bank of America (USA; Formerly Fleet) ;- Business Visa Card
					$aIINList[129]=417009 ;- Bank of America (USA; Formerly Fleet) ;- Business Visa Card
					$aIINList[130]=417010 ;- Bank of America (USA; Formerly Fleet) ;- Business Visa Card
					$aIINList[131]=417011 ;- Bank of America (USA; Formerly Fleet) ;- Business Visa Card
					$aIINList[132]=417935 ;- Visa Electron
					$aIINList[133]=417968 ;- Visa credit card ;- Banregio (Mexico)
					$aIINList[134]=418122 ;- National Development Bank Visa prepaid (Sri Lanka)
					$aIINList[135]=418169 ;- CitiBank China Rewards (US Dollars Card)
					$aIINList[136]=418221 ;- TD Bank in the United States
					$aIINList[137]=418224 ;- New Zealand Post (NZ) ;- Visa Loaded Card
					$aIINList[138]=418236 ;- Korea Exchange Bank ;- KEB VISA Signature Card
					$aIINList[139]=418238 ;- UOB (SG) ;- Visa Platinum Debit Card
					$aIINList[140]=418370 ;- Green Dot Prepaid Visa debit card
					$aIINList[141]=418850 ;- Italy (Italy) ;- Visa Card
					$aIINList[142]=419000 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[143]=419001 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[144]=419002 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[145]=419003 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[146]=419004 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[147]=419005 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[148]=419006 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[149]=419007 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[150]=419008 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[151]=419009 ;- U.S. Bank (US) WorldPerks VISA Credit Card
					$aIINList[152]=419661 ;- DongA Bank Vietnam ;- Visa credit Card
					$aIINList[153]=419672 ;- MetaBank ;- Visa debit Prepaid
					$aIINList[154]=419740 ;- Visa Electron
					$aIINList[155]=419741 ;- Visa Electron
					$aIINList[156]=419773 ;- Visa Electron
					$aIINList[157]=419774 ;- Visa Electron
					$aIINList[158]=419775 ;- Visa Electron
					$aIINList[159]=419776 ;- Visa Electron
					$aIINList[160]=420567 ;- Volkswagen Bank direct VISA Credit Card (Germany) 67
					$aIINList[161]=420571 ;- Forex Bank Visa Credit Card Sweden
					$aIINList[162]=420719 ;- US Bank debit card.
					$aIINList[163]=420767 ;- Chase VISA debit card
					$aIINList[164]=420792 ;- Banque Invik Everywhere Money prepaid debit Visa Electron card (LU/SE)
					$aIINList[165]=420841 ;- Banque Invik Visa debit card
					$aIINList[166]=420984 ;- Bank of Lee's Summit, VISA Debit
					$aIINList[167]=421323 ;- ICICI Bank visa Gold Debit/ATM Card (India)
					$aIINList[168]=421324 ;- IndusInd Bank Debit Card (India)
					$aIINList[169]=421325 ;- UTI Bank Prepaid Visa Card
					$aIINList[170]=421337 ;- Allahabad Bank Debit Card, India
					$aIINList[171]=421338 ;- Chequera Debit Card City (El Salvador)
					$aIINList[172]=421355 ;- Interbank ;- Banco Internacional del Peru Debit Card (Peru)
					$aIINList[173]=421402 ;- Citizens Bank of Canada/Vancouver City Savings Credit Union Visa Gift Card
					$aIINList[174]=421420 ;- BC Card Check Card issued by Woori Bank
					$aIINList[175]=421458 ;- Canara Bank
					$aIINList[176]=421473 ;- ING Direct (Spain) Visa Debit Card
					$aIINList[177]=421494 ;- Asia Commercial Bank Vietnam ;- Visa Debit Card
					$aIINList[178]=421630 ;- ICICI Bank Visa Gold debit/ATM Card (India)
					$aIINList[179]=421689 ;- Commercial Bank, Sri Lanka ;- VISA Debit (Electronic)
					$aIINList[180]=421764 ;- Bank of America VISA Debit Card
					$aIINList[181]=421765 ;- Bank of America VISA Debit Card
					$aIINList[182]=421766 ;- Bank of America VISA Debit Card
					$aIINList[183]=422050 ;- SAMBIL MALL Servitebca Visa Prepaid Card (Issued by Venezolano de Credito).
					$aIINList[184]=422061 ;- Banco Santander (Brasil) S.A.
					$aIINList[185]=422127 ;- Standard Chartered Bank (Nigeria) Visa Platinum Debit Card
					$aIINList[186]=422189 ;- GE Money (PL) ;- Visa credit card
					$aIINList[187]=422287 ;- Raiffeisen bank (Russia), Visa Classic
					$aIINList[188]=422629 ;- HSBC Bank (Turkey) VISA Credit Card
					$aIINList[189]=422695 ;- Chase Bank (British Airways) Visa Signature Credit Card
					$aIINList[190]=422699 ;- Pro Credit Bank Ltd, Kosovo, VISA
					$aIINList[191]=422727 ;- Citibank Korea BC VISA Check Card
					$aIINList[192]=422833 ;- o2 money card (managed by Natwest) Prepay card
					$aIINList[193]=423347 ;- Patelco Credit Union
					$aIINList[194]=423837 ;- Sampopank (Estonia), Visa Premier / Gold
					$aIINList[195]=423953 ;- St George Bank Visa Debit (Australia)
					$aIINList[196]=423966 ;- Suffolk County National Bank Visa Debit (NY)
					$aIINList[197]=424201 ;- Landesbank Baden;-Württemberg Payback Premium
					$aIINList[198]=424327 ;- Skandiabanken Visa Credit Card (NO)
					$aIINList[199]=424339 ;- Skandiabanken Betal & Kreditkort Visa credit card (SE)
					$aIINList[200]=424395 ;- Luottokunta Visa Gold (FI)
					$aIINList[201]=424604 ;- US Bank USA GOVT VISA Procurment Card
					$aIINList[202]=424631 ;- Chase Bank USA VISA Business Credit Card
					$aIINList[203]=424671 ;- Ing Bank Slaski SA (Poland)
					$aIINList[204]=425435 ;- Washington Mutual (formerly Fleet) VISA Debit Card
					$aIINList[205]=425436 ;- Washington Mutual (formerly Fleet) VISA Debit Card
					$aIINList[206]=425522 ;- Columbus Bank and Trust, AVS=866;-443;-6669
					$aIINList[207]=425569 ;- Trade Bank of Iraq
					$aIINList[208]=425907 ;- Wells Fargo Business Platinum Check Visa Card
					$aIINList[209]=425908 ;- Wells Fargo Business Platinum Check Visa Card
					$aIINList[210]=425914 ;- Compass Bank, Visa, Business Platinum Check Card, Debit
					$aIINList[211]=426140 ;- BM Bank (UA)
					$aIINList[212]=426354 ;- Comdirect Bank (Germany) Visa Credit Card, Natwest UK Visa
					$aIINList[213]=426376 ;- Standard Chartered Bank Bangladesh
					$aIINList[214]=426393 ;- Natwest UK Visa Credit card
					$aIINList[215]=426428 ;- Bank of America (formerly MBNA) Platinum Visa Credit Card
					$aIINList[216]=426429 ;- Bank of America (formerly MBNA) Platinum Visa Credit Card
					$aIINList[217]=426451 ;- Bank of America (formerly MBNA) Platinum Visa Credit Card
					$aIINList[218]=426452 ;- Bank of America (formerly MBNA) Platinum Visa Credit Card
					$aIINList[219]=426465 ;- Bank of America (formerly MBNA) Platinum Visa Credit Card
					$aIINList[220]=426488 ;- Code Credit Union (Dayton, Ohio)
					$aIINList[221]=426501 ;- HHonors Platinum Visa Credit Card (Barclaycard)
					$aIINList[222]=426502 ;- RISE Visa credit card issued by R Raphael & Sons (UK)
					$aIINList[223]=426503 ;- shout Visa credit card issued by R Raphael & Sons (UK)
					$aIINList[224]=426510 ;- Solutions Finance Credit Card (Barclaycard)
					$aIINList[225]=426534 ;- Citibank Australia Visa Platinum Card
					$aIINList[226]=426556 ;- HSBC Bank VISA Credit Card (Australia)
					$aIINList[227]=426557 ;- HSBC Bank VISA Credit Card (Australia)
					$aIINList[228]=426558 ;- HSBC Bank VISA Credit Card (Australia)
					$aIINList[229]=426588 ;- UOB Platinum Visa Credit Card (Singapore)
					$aIINList[230]=426569 ;- CitiBank Platinum Visa Credit Card (Singapore)
					$aIINList[231]=426579 ;- Bank Of Ayudhya Visa Debit Card (Thailand)
					$aIINList[232]=426638 ;- Nordstrom FSB Classic Visa Credit Card
					$aIINList[233]=426655 ;- Chase (formerly Bank One) Visa Credit Card
					$aIINList[234]=426656 ;- Chase (formerly Bank One) Visa Credit Card
					$aIINList[235]=426684 ;- CAPITAL ONE BANK Credit Card
					$aIINList[236]=426684 ;- Countrywide Visa Credit Card (2008)
					$aIINList[237]=426684 ;- Chase +1 Student Visa Card (2008)
					$aIINList[238]=426692 ;- Capital One, Platinum
					$aIINList[239]=426698 ;- First Command Financial Planning, Inc.
					$aIINList[240]=427010 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[241]=427019 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[242]=427020 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[243]=427028 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[244]=427029 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[245]=427030 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[246]=427038 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[247]=427039 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[248]=427062 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[249]=427064 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[250]=427085 ;- Industrial and Commercial Bank of China Visa Credit Card
					$aIINList[251]=427208 ;- Mercedes Benz Bank
					$aIINList[252]=427229 ;- VTB24 (Russia), Visa Classic (Un)embossed
					$aIINList[253]=427342 ;- Lloyds TSB Business Debit Card
					$aIINList[254]=427557 ;- RBC Centura Bank Visa Debit Card (Pocket Check Card)
					$aIINList[255]=427741 ;- Santander Consumer Bank
					$aIINList[256]=427760 ;- Citibank, Russia
					$aIINList[257]=427843 ;- Alamzergienbank, Russia, Visa Classic
					$aIINList[258]=428208 ;- Chase Debit Visa
					$aIINList[259]=428915 ;- BRE Bank (MultiBank) Visa Platinum / Aquarius Credit Card (Poland)
					$aIINList[260]=428332 ;- Maybank;-issued Maybankard Visa Debit Card (Malaysia)
					$aIINList[261]=428333 ;- Prezzy card (New Zealand Post)
					$aIINList[262]=428418 ;- ASB Bank (New Zealand) Visa Debit Card
					$aIINList[263]=428434 ;- Citizens Bank of Canada (Canada) Prepaid Visa Gift Card
					$aIINList[264]=428454 ;- Kiwibank (New Zealand) Visa Debit Card
					$aIINList[265]=429158 ;- Bank of Moscow (Russia) Visa Electron Social Security Card
					$aIINList[266]=429420 ;- Digital Federal Credit Union (DCU) Visa Check Card
					$aIINList[267]=429475 ;- Regions Bank Visa Debit Card
					$aIINList[268]=429531 ;- Scott Credit Union, Visa Debit Card
					$aIINList[269]=429805 ;- First National Bank of Omaha and affiliate Visa Debit Cards
					$aIINList[270]=429812 ;- First National Bank of Omaha and affiliate Visa Debit Cards
					$aIINList[271]=430092 ;- Standard Chartered Platinum VISA Credit Card (Singapore)
					$aIINList[272]=430252 ;- Bank of Cyprus Greece Prepaid Visa
					$aIINList[273]=430536 ;- Bank of America (formerly Fleet) Visa Credit Card
					$aIINList[274]=430544 ;- Bank of America (formerly Fleet) Visa Credit Card
					$aIINList[275]=430546 ;- Bank of America (formerly Fleet) Visa Credit Card
					$aIINList[276]=430550 ;- Bank of America (formerly Fleet) Visa Credit Card
					$aIINList[277]=430594 ;- Bank of America (formerly Fleet) Visa Credit Card
					$aIINList[278]=430552 ;- Summit Federal Credit Union Visa Debit Card
					$aIINList[279]=430567 ;- Tesco Bank Classic Visa
					$aIINList[280]=430586 ;- Pennsylvania State Employees' Credit Union Check Card
					$aIINList[281]=430605 ;- Affinity Plus Federal Credit Union Debit Card (USA)
					$aIINList[282]=430679 ;- PenFed Credit Union (USA)
					$aIINList[283]=430763 ;- Wells Fargo Debit (USA)
					$aIINList[284]=431170 ;- Rizal Commercial Banking Corporation Visa Credit Card (PH)
					$aIINList[285]=431178 ;- Citibank Taiwan (TW)
					$aIINList[286]=431239 ;- Citibank Australia VISA Debit Card (AU)
					$aIINList[287]=431261 ;- IWBank Visa
					$aIINList[288]=431262 ;- IWBank Visa Electron
					$aIINList[289]=431301 ;- Wells Fargo Bank Preferred Visa & Visa Signature Credit Cards
					$aIINList[290]=431305 ;- Wells Fargo Bank Preferred Visa & Visa Signature Credit Cards
					$aIINList[291]=431307 ;- Wells Fargo Bank Preferred Visa & Visa Signature Credit Cards
					$aIINList[292]=431308 ;- Wells Fargo Bank Preferred Visa & Visa Signature Credit Cards
					$aIINList[293]=431406 ;- Visa Card, USA
					$aIINList[294]=431500 ;- Visa Card Wachovia / Wells Fargo (USA)
					$aIINList[295]=431732 ;- Plains Commerce, (Total Visa), Small Credit Limit, Credit Repair Card
					$aIINList[296]=431784 ;- China Construction Bank (Asia) VISA Platinum Credit Card (Hong Kong)
					$aIINList[297]=431930 ;- Halifax Ireland VISA Debit card
					$aIINList[298]=431931 ;- Ulster Bank VISA Debit Card, Republic of Ireland
					$aIINList[299]=431932 ;- Ulster Bank VISA Debit Card, Republic of Ireland
					$aIINList[300]=431935 ;- Permanent TSB VISA Debit Card, Republic of Ireland
					$aIINList[301]=431940 ;- Bank of Ireland VISA Debit Card, Republic of Ireland
					$aIINList[302]=431949 ;- Bank of Ireland VISA Credit Card, Republic of Ireland
					$aIINList[303]=431947 ;- Allied Irish Banks VISA Debit Card, Republic of Ireland
					$aIINList[304]=432158 ;- BA Finance/Credit Europe bank (Russia), Visa Classic "Auchan" card
					$aIINList[305]=432624 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[306]=432625 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[307]=432626 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[308]=432627 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[309]=432628 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[310]=432629 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[311]=432630 ;- Bank of America (formerly Fleet National Bank) Visa Check Card, Debit
					$aIINList[312]=432732 ;- Metabank Debit Card
					$aIINList[313]=432845 ;- Sovereign Bank Check Card
					$aIINList[314]=432901 ;- BRE Bank (MultiBank) Visa Classic Aquarius PayWawe Debit Card (Poland)
					$aIINList[315]=432919 ;- Cartasi Eura Visa Electron (Italy)
					$aIINList[316]=432937 ;- BRE Bank (MultiBank) Visa Electron Aquarius Debit Card (Poland)
					$aIINList[317]=432938 ;- BRE Bank (MultiBank) Visa Classic Aquarius Debit Card (Poland)
					$aIINList[318]=432995 ;- TCF Visa Debit Card (USA)
					$aIINList[319]=433388 ;- Citibank Credit Card (Hong Kong)
					$aIINList[320]=433445 ;- BBVA Puerto Rico ;- Visa Electron
					$aIINList[321]=433507 ;- MBNA ;- Visa
					$aIINList[322]=433687 ;- National Australia Bank Business Payments Visa Business Card
					$aIINList[323]=433948 ;- Barclays & Times Card Visa Gold Credit Card (India)
					$aIINList[324]=433950 ;- Barclays & Yatra.com Platinum Credit Card (India)
					$aIINList[325]=433991 ;- Palm Desert National Bank as Cingular Wireless' rebate debit card
					$aIINList[326]=434254 ;- Best Bank
					$aIINList[327]=434255 ;- Bank of America
					$aIINList[328]=434256 ;- Wells Fargo Debit
					$aIINList[329]=434257 ;- Wells Fargo Debit
					$aIINList[330]=434258 ;- Wells Fargo Debit
					$aIINList[331]=434493 ;- Visa Gift Card
					$aIINList[332]=435225 ;- Nordea Bank Visa Electron Debit Card (Poland)
					$aIINList[333]=435237 ;- Target Visa Card
					$aIINList[334]=435680 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[335]=435681 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[336]=435682 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[337]=435683 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[338]=435684 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[339]=435685 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[340]=435686 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[341]=435687 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[342]=435688 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[343]=435689 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[344]=435690 ;- Bank of America, Visa, Platinum Check Card, Debit
					$aIINList[345]=435744 ;- ShenZhen Development Bank, Visa, Classic, Credit (China)
					$aIINList[346]=435760 ;- Compass Bank, Visa, Business Check Card, Debit
					$aIINList[347]=435899 ;- Gift card, U.S. Bank N.A., Metabank
					$aIINList[348]=436501 ;- CitiBank (Malaysia)
					$aIINList[349]=436802 ;- Visa Pre Paid US
					$aIINList[350]=436338 ;- Landesbank Berlin AG (ADAC VISA Gold)
					$aIINList[351]=436610 ;- Chase (formerly First USA)
					$aIINList[352]=436611 ;- Chase (formerly First USA)
					$aIINList[353]=436612 ;- Chase (formerly First USA)
					$aIINList[354]=436613 ;- Chase (formerly First USA)
					$aIINList[355]=436614 ;- Chase (formerly First USA)
					$aIINList[356]=436615 ;- Chase (formerly First USA)
					$aIINList[357]=436616 ;- Chase (formerly First USA)
					$aIINList[358]=436617 ;- Chase (formerly First USA)
					$aIINList[359]=436667 ;- Chase (formerly First USA)
					$aIINList[360]=436618 ;- U.S. Bank Visa debit card
					$aIINList[361]=436742 ;- China Construction Bank Debit Card
					$aIINList[362]=436773 ;- National Bank of New Zealand Visa Credit Card
					$aIINList[363]=437737 ;- Barclay Debit Card (India)
					$aIINList[364]=437748 ;- SBI Cards credit card (India)
					$aIINList[365]=438088 ;- Bank of China Visa Unionpay Gold Credit Card
					$aIINList[366]=438437 ;- Bank of East Asia VISA Platinum Credit Card (Hong Kong)
					$aIINList[367]=438617 ;- China Construction Bank (Asia) Finance Credit Card
					$aIINList[368]=438676 ;- Shinhan Card VISA Platinum Card
					$aIINList[369]=438755 ;- San Diego County Credit Union Visa Card
					$aIINList[370]=438857 ;- Chase Bank (United Airlines) Visa credit card
					$aIINList[371]=439188 ;- China Merchants Bank ;- Visa Credit Card Infinite Credit limit
					$aIINList[372]=439225 ;- China Merchants Bank Visa Credit Card
					$aIINList[373]=439226 ;- China Merchants Bank Visa Credit Card
					$aIINList[374]=439227 ;- China Merchants Bank Visa Credit Card
					$aIINList[375]=439239 ;- Suncorp Bank Australia Visa Credit Card
					$aIINList[376]=440025 ;- BC card Check card issued by Hana SK Card
					$aIINList[377]=440210 ;- Citibank Handlowy (PL) ;- Visa Silver
					$aIINList[378]=440211 ;- Citibank Handlowy (PL) ;- Visa Gold
					$aIINList[379]=440260 ;- Allied Irish Banks "Click" Visa Card
					$aIINList[380]=440318 ;- Fidelity Rewards Visa Signature (issued by FIA Card Services)
					$aIINList[381]=440319 ;- Schwab Bank Invest First Visa Signature
					$aIINList[382]=440396 ;- Home Trust Company (Canada)
					$aIINList[383]=440626 ;- Slovenská sporiteľňa Visa Electron
					$aIINList[384]=440752 ;- ČSOB (CZ) ;- Visa Classic
					$aIINList[385]=440753 ;- ČSOB (CZ) ;- Visa Electron
					$aIINList[386]=440783 ;- Co;-operative Bank (KE) ;- Visa
					$aIINList[387]=441104 ;- Chase Debit Card
					$aIINList[388]=441297 ;- First Bankcard (US)
					$aIINList[389]=441709 ;- MetaBank Visa Gift Card
					$aIINList[390]=441712 ;- First USA Bank, N.A.
					$aIINList[391]=441822 ;- 1st National Bank of Omaha
					$aIINList[392]=442162 ;- MBNA EUROPE BANK LIMITED Classic Visa Credit Card
					$aIINList[393]=442261 ;- Banco Santander (Brasil) S.A.
					$aIINList[394]=442394 ;- Hong Kong Standard Chartered Bank Priority Banking Visa Infinite Credit Card
					$aIINList[395]=442518 ;- Wells Fargo Platinum Visa
					$aIINList[396]=442729 ;- China CITIC Bank Gold Visa Debit Card
					$aIINList[397]=442730 ;- China CITIC Bank Platinum Visa Debit Card
					$aIINList[398]=442742 ;- JP Morgan business visa debit card
					$aIINList[399]=442790 ;- Citizens Bank (RBS) Platinum Visa Debit Card
					$aIINList[400]=442860 ;- VISA CARD, The Security National Bank & Trust Company of Norman
					$aIINList[401]=443060 ;- PNC Bank
					$aIINList[402]=443084 ;- Hume Building Society
					$aIINList[403]=443233 ;- Shinhan Card (former LG Card)
					$aIINList[404]=443420 ;- Teachers Mutual Bank Visa Debit card
					$aIINList[405]=443438 ;- Credit Union Australia ;- Visa Debit Card
					$aIINList[406]=443464 ;- Five Star Bank
					$aIINList[407]=443469 ;- Police and Nurses Credit Union Debit Visa(Aust)
					$aIINList[408]=444238 ;- SMP bank (Russia) Visa Classic
					$aIINList[409]=444400 ;- First US Bank
					$aIINList[410]=444512 ;- Fifth Third Bank
					$aIINList[411]=444796 ;- VISA CREDIT CARD, Credit One Bank,N.A.
					$aIINList[412]=445093 ;- HSBC Vietnam ;- VISA Credit Card
					$aIINList[413]=445094 ;- HSBC Vietnam ;- VISA Credit Card
					$aIINList[414]=445479 ;- Keytrade Bank Visa Classic Credit Card
					$aIINList[415]=445480 ;- Keytrade Bank Visa Gold Credit Card
					$aIINList[416]=445785 ;- CREDIT Union Card Services, INC, Debit, Prepaid, Visa (United States)
					$aIINList[417]=446053 ;- Prepaid card, US Bank Visa Classic Debit Card USA
					$aIINList[418]=446106 ;- MetaBank Visa Debit USA
					$aIINList[419]=446153 ;- BRE Bank (CZ) ;- mBank Visa Gold Credit Card
					$aIINList[420]=446155 ;- BRE Bank (CZ) ;- mBank Visa Electron
					$aIINList[421]=446157 ;- BRE Bank (PL) ;- mBank Visa Electron
					$aIINList[422]=446157 ;- BRE Bank (CZ) ;- mBank Visa Classic Debit Card
					$aIINList[423]=446158 ;- BRE Bank (PL) ;- mBank Visa Electron
					$aIINList[424]=446261 ;- Lloyds TSB (UK) ;- Visa Debit Card (for Personal and Business Accounts)
					$aIINList[425]=446268 ;- Cahoot (UK) ;- Visa Debit
					$aIINList[426]=446272 ;- Lloyds TSB (UK) ;- Platinum Account Visa Debit Card
					$aIINList[427]=446274 ;- Lloyds TSB (UK) ;- Premier Visa Debit Card (with £250 Cheque guarantee limit)
					$aIINList[428]=446277 ;- Abbey (bank) ;- Business Banking Visa Debit Card
					$aIINList[429]=446278 ;- Halifax (UK) ;- Visa debit card
					$aIINList[430]=446279 ;- Bank of Scotland (UK) ;- Visa debit card
					$aIINList[431]=446291 ;- Halifax (UK) ;- Visa Gold debit card
					$aIINList[432]=446867 ;- Banco de Chile (Chile) ;- Visa Platinum Card
					$aIINList[433]=447211 ;- HSBC ;- Gold Visa Credit Card (Indonesia)
					$aIINList[434]=447320 ;- BC VISA Check Card issued by Woori Bank
					$aIINList[435]=447452 ;- Union Bank & Trust Company Visa debit card
					$aIINList[436]=447692 ;- HSBC India Visa Silver Credit Card (India)
					$aIINList[437]=447746 ;- ICICI Bank credit card (India)
					$aIINList[438]=447747 ;- ICICI Bank Visa Gold Credit Card (India)
					$aIINList[439]=447817 ;- Promsvyazbank, Russia ;- Visa Gold Transaero Card
					$aIINList[440]=447935 ;- National City Bank Visa Debit Card
					$aIINList[441]=447994 ;- GAP Visa Credit Card (issued by GE Capital Retail Bank)
					$aIINList[442]=447995 ;- Old Navy Visa Credit Card
					$aIINList[443]=448027 ;- Cuaranty Bank (United States);- Classic, Debit, Visa
					$aIINList[444]=448125 ;- BC Card VISA Check Card issued by Hana SK Card
					$aIINList[445]=448156 ;- Chase Bank / MyECount.com Sprint Wireless' rebate debit card
					$aIINList[446]=448336 ;- mBank (PL) ;- Visa credit card
					$aIINList[447]=448336 ;- BRE Bank (PL) ;- mBank Visa Classic
					$aIINList[448]=448360 ;- Getin Noble Bank Visa Electron Debit Card (OpenFinance.PL) (Poland)
					$aIINList[449]=448445 ;- Lloyds Bank ;- Visa Credit Card
					$aIINList[450]=449352 ;- Nationwide Building Society Visa Credit Card
					$aIINList[451]=449364 ;- Valley Bank
					$aIINList[452]=449533 ;- Bank of America (USA), National Association ;- Classic, Debit, Visa
					$aIINList[453]=449914 ;- Shinhan Card check card from former LG Card
					$aIINList[454]=450003 ;- CIBC Infinite Aerogold (VISA credit card)
					$aIINList[455]=450060 ;- CIBC Aerogold (VISA credit card)
					$aIINList[456]=450065 ;- CIBC Platinum (VISA credit card)
					$aIINList[457]=450198 ;- MBNA UK;-issued Visa Credit Card (inc. BMI airline card)
					$aIINList[458]=450405 ;- Æon Credit Service Credit Card
					$aIINList[459]=450605 ;- Bendigo Bank Visa Blue Debit Card
					$aIINList[460]=450634 ;- Yapı ve Kredi Bankası World Visa Debit Card
					$aIINList[461]=450722 ;- Bank Islam Malaysia Berhad VISA Classic Credit Card;-i (International)
					$aIINList[462]=450742 ;- Landsbanki Visa Card (Iceland)
					$aIINList[463]=450823 ;- Lloyds TSB VISA
					$aIINList[464]=450875 ;- Co;-operative Bank Visa Debit Card (formerly Visa Electron)
					$aIINList[465]=450878 ;- Banco de Chile Visa Credit Card
					$aIINList[466]=450979 ;- Santander Rio Argentina ;- classic visa card
					$aIINList[467]=451291 ;- Bank of China ;- Visa Credit Card
					$aIINList[468]=451368 ;- Banco BCI Nova VISA Debito (Chile)
					$aIINList[469]=451503 ;- Royal Bank of Canada (CA) ;- VISA
					$aIINList[470]=451811 ;- Industrial and Commercial Bank of China Credit Card (China)
					$aIINList[471]=451834 ;- DBS Bank Credit Card (Hong Kong)
					$aIINList[472]=451845 ;- Shinhan Bank VISA Check Card
					$aIINList[473]=452088 ;- TD Bank CAD VISA infinite
					$aIINList[474]=453030 ;- NAB Gold Affinity
					$aIINList[475]=453224 ;- CBA Visa Awards Credit Card (Australia)
					$aIINList[476]=453231 ;- Banco Mercantil Venezuela Visa Card
					$aIINList[477]=453801 ;- ScotiaBank ;- Visa Gold
					$aIINList[478]=453826 ;- ScotiaBank ;- Visa Infinite
					$aIINList[479]=453893 ;- GE Consumer Finance VISA Card
					$aIINList[480]=453904 ;- Nordea (SE) ;- Visa Electron
					$aIINList[481]=453925 ;- Bank of Ireland ;- Visa Credit
					$aIINList[482]=453978 ;- Barclays Bank (UK) ;- Connect Visa Debit Card
					$aIINList[483]=453979 ;- Barclays Bank (UK) ;- Connect Visa Debit Card
					$aIINList[484]=453980 ;- permanent tsb Visa Credit Card
					$aIINList[485]=453997 ;- Friulcassa / CartaSi (IT) ;- Visa Card
					$aIINList[486]=453998 ;- CartaSi (IT) ;- Visa Card
					$aIINList[487]=454117 ;- Lawson CS Card (Japan)
					$aIINList[488]=454153 ;- Saison Card International (Japan)
					$aIINList[489]=454166 ;- KDDI / KDDI Card Saison VISA (Japan)
					$aIINList[490]=454202 ;- Rakuten Bank Debit Card Classic (Japan)
					$aIINList[491]=454271 ;- Mizuho bank / UC VISA (Japan)
					$aIINList[492]=454287 ;- East Japan Railway Company / view card VISA (Japan)
					$aIINList[493]=454305 ;- RBS Visa Credit Card
					$aIINList[494]=454312 ;- First Direct (UK) ;- Visa Credit Card
					$aIINList[495]=454313 ;- Nationwide Building Society (UK) ;- Visa Debit Card
					$aIINList[496]=454337 ;- Iceland, Sparsjodur Kopavogs Bank ;- VISA CREDIT CARD
					$aIINList[497]=454361 ;- First Direct (a division of HSBC UK) Visa Debit Card
					$aIINList[498]=454417 ;- Slovenská sporiteľňa Visa
					$aIINList[499]=454434 ;- First Trust Bank (UK) ;- Visa Debit Card
					$aIINList[500]=454469 ;- Landesbank Berlin AG ;- Visa Credit Card
					$aIINList[501]=454495 ;- Co;-operative Bank (UK) ;- Visa Credit Card
					$aIINList[502]=454605 ;- Citibank Australia (AU) Visa Card
					$aIINList[503]=454617 ;- ING DiBa (Frankfurt, Germany) ;- classic Visa credit card
					$aIINList[504]=454642 ;- Banco Galicia Argentina ;- classic Visa credit card
					$aIINList[505]=454718 ;- UOB (SG) A*STAR VISA Corporate Gold Credit Card
					$aIINList[506]=454742 ;- Santander (Previously Abbey (bank)) Visa Debit Card
					$aIINList[507]=454749 ;- BHW (DE) ;- Visa Charge Card
					$aIINList[508]=454867 ;- ASB Bank Visa Credit Card (New Zealand)
					$aIINList[509]=454869 ;- Westpac New Zealand Visa Credit
					$aIINList[510]=454889 ;- Hong Kong Hang Seng Bank (classic card)
					$aIINList[511]=455025 ;- Cooperative Bank (UK) ;- Visa
					$aIINList[512]=455047 ;- Westpac New Zealand VISA
					$aIINList[513]=455121 ;- GM;-Visa Card (CAD) issued by TDCanada Trust
					$aIINList[514]=455271 ;- Bank of East Asia Classic Credit Card (Hong Kong)
					$aIINList[515]=455272 ;- Bank of East Asia Gold Credit Card (Hong Kong)
					$aIINList[516]=455451 ;- ICICI Bank Visa Platinum Debit Card (India)
					$aIINList[517]=455479 ;- MegaFon virtual card (Russia)
					$aIINList[518]=455503 ;- Bancomer Azul Clásica Credit Card (México)
					$aIINList[519]=455701 ;- National Australia Bank (AU) ;- GOLD VISA Credit Card
					$aIINList[520]=455702 ;- National Australia Bank VISA (AU) ;- Credit Card
					$aIINList[521]=455707 ;- Hang Seng Bank Credit Card
					$aIINList[522]=455788 ;- Visa gold debit card BCP;-Banco de Crédito del Perú.
					$aIINList[523]=456079 ;- Hong Kong HSBC USD Visa Gold Credit Card
					$aIINList[524]=456351 ;- (CN)Bank of China Debit card (China UnionPay)
					$aIINList[525]=456403 ;- Bank of Melbourne 1 (AU; now Westpac) ;- Visa Debit Card
					$aIINList[526]=456406 ;- Challenge Bank (AU; now Westpac) ;- Visa Debit Card
					$aIINList[527]=456413 ;- DEFENCE FORCE CREDIT UNION VISA DEBIT CARD (Australia)
					$aIINList[528]=456414 ;- CREDIT UNION AUSTRALIA VISA DEBIT (Australia)
					$aIINList[529]=456432 ;- SUNCORP METWAY VISA DEBIT CARD (Australia)
					$aIINList[530]=456443 ;- BENDIGO BANK LTD ;- BASIC BLACK VISA CREDIT CARD (Australia)
					$aIINList[531]=456445 ;- STATE BANK VICTORIA ;- VISA DEBIT CARD (now Commonwealth Bank Australia)
					$aIINList[532]=456448 ;- BANK OF QUEENSLAND VISA CREDIT CARD (Australia)
					$aIINList[533]=456453 ;- ANZ Bank VISA Gift Card (Australia)
					$aIINList[534]=456462 ;- ANZ Bank VISA Credit Card (Australia)
					$aIINList[535]=456468 ;- ANZ Bank VISA Credit Card Frequent Flyer Platinum (Australia)
					$aIINList[536]=456469 ;- ANZ Bank VISA Credit Card Gold (Australia)
					$aIINList[537]=456471 ;- Westpac Visa Credit Card (Australia)
					$aIINList[538]=456472 ;- Westpac Bank Altitude Visa Credit Card Platinum (Australia)
					$aIINList[539]=456473 ;- Banco Estado VISA Tarjeta de Credito (Chile)
					$aIINList[540]=456475 ;- Newcastle Permanent Building Society ltd VISA Debit (Australia)
					$aIINList[541]=456480 ;- ANZ Bank Visa Business Card (Australia)
					$aIINList[542]=456491 ;- ASB Bank (New Zealand)
					$aIINList[543]=456715 ;- Citibank (UK) Visa Prepaid card)
					$aIINList[544]=456716 ;- Landsbanki Visa Electron Card (Iceland)
					$aIINList[545]=456726 ;- Santander VISA Debit Card (UK)
					$aIINList[546]=456735 ;- Alliance and Leicester VISA Debit Card (UK)
					$aIINList[547]=456738 ;- Citibank (UK) ;- Visa Debit Card (UK)
					$aIINList[548]=458109 ;- Swedbank Visa Debit Card Sweden
					$aIINList[549]=458123 ;- Bank of Communications/HSBC (CN) Y;-Power Visa Card
					$aIINList[550]=458124 ;- Bank of Communications VISA/China Unionpay (CN)
					$aIINList[551]=458440 ;- HSBC Vietnam ;- VISA Debit Card
					$aIINList[552]=459501 ;- Caxton fx Dollar Traveller Prepaid Visa (issued by R. Raphael & Son plc.)
					$aIINList[553]=460005 ;- MetaBank Debit Card (US)
					$aIINList[554]=461726 ;- Citi Bank (Hong Kong)
					$aIINList[555]=461786 ;- HDFC Bank Credit Card (India)
					$aIINList[556]=461983 ;- Best Buy Reward Zone/Chase (Canada)
					$aIINList[557]=462239 ;- ANZ Visa Debit Card (Australia)
					$aIINList[558]=462263 ;- ING Direct Visa Debit Card (Australia)
					$aIINList[559]=462288 ;- Bangkok Bank Visa Debit Card (Thailand)
					$aIINList[560]=462890 ;- Citibank Korea PremierMiles VISA Signature Card (Korea)
					$aIINList[561]=464006 ;- Public Bank (Hong Kong) VISA Gold Card
					$aIINList[562]=464007 ;- Public Bank (Hong Kong) VISA Classic Card
					$aIINList[563]=464944 ;- HSBC Philippines Debit Card (Philippines)
					$aIINList[564]=465345 ;- FirstBank Debit (Lakewood CO, USA)
					$aIINList[565]=465844 ;- ALLIED IRISH BANK(GB)
					$aIINList[566]=465858 ;- Barclays Visa Debit (UK)
					$aIINList[567]=465859 ;- Barclays Visa Debit (UK)
					$aIINList[568]=465861 ;- Barclays Visa Debit (UK)
					$aIINList[569]=465901 ;- Barclays Visa Debit (UK)
					$aIINList[570]=465904 ;- Santander Visa Debit (UK)
					$aIINList[571]=465921 ;- Barclays Visa Debit (UK)
					$aIINList[572]=465935 ;- Nationwide Building Society Cash Card+ (UK)
					$aIINList[573]=465942 ;- HSBC Visa Debit Card (UK)
					$aIINList[574]=465943 ;- HSBC Visa Debit Card (UK)
					$aIINList[575]=465944 ;- HSBC Visa Debit Card (UK)
					$aIINList[576]=465946 ;- First Direct Debit Card (UK)
					$aIINList[577]=465995 ;- Teller A.S. CREDIT PLATINUM Norway Oslo
					$aIINList[578]=466131 ;- The River Bank Debt [Closed by FCIC now Central Bank] (USA)
					$aIINList[579]=467932 ;- HSBC Advance Platinum VISA Credit Card (Hong Kong)
					$aIINList[580]=467937 ;- Lakshmi Vilas Bank (India)
					$aIINList[581]=468524 ;- CitiBusiness Gold CitiBank (Australia)
					$aIINList[582]=468563 ;- JPMorgan Chase ;- Amazon.ca Rewards Card Visa
					$aIINList[583]=468805 ;- Axis Bank Debit Card (India)
					$aIINList[584]=469375 ;- ICICI Limited (India)
					$aIINList[585]=469443 ;- First Bankcard Signature (US)
					$aIINList[586]=469568 ;- Dena Bank Debit Card (India)
					$aIINList[587]=470132 ;- Bank of America HSA Debit Card
					$aIINList[588]=470758 ;- US Bank, Visa Debit, USA
					$aIINList[589]=472409 ;- TD Access Card, VISA Debit, Canada
					$aIINList[590]=472437 ;- Virgin Money Credit Card (Australia)
					$aIINList[591]=472776 ;- MetaBank
					$aIINList[592]=472926 ;- Peoples Trust Vanilla Prepaid Visa Card, Canada
					$aIINList[593]=473099 ;- Wells Fargo Bank, Visa Debit, Iowa USA
					$aIINList[594]=473104 ;- Swiss International Airlines Miles & More Visa Gold (CH)
					$aIINList[595]=473354 ;- Air Academy Federal Credit Union, Colorado USA ;- Visa Debit Card
					$aIINList[596]=473702 ;- Wells Fargo, Visa card, USA
					$aIINList[597]=473909 ;- PSCU FINANCIAL SERVICES INC
					$aIINList[598]=474480 ;- Bank of America Visa Debit, Midwest USA
					$aIINList[599]=475034 ;- Prepaid card, Metabank DEBIT CLASSIC USA
					$aIINList[600]=475050 ;- JPMorgan Chase Visa Credit Card
					$aIINList[601]=475055 ;- JPMorgan Chase Visa Debit Card
					$aIINList[602]=475110 ;- Ulster Bank, Visa Debit, UK (immediate authorisation)
					$aIINList[603]=475114 ;- VISA Debit Platinum, Coutts & Co, UK
					$aIINList[604]=475116 ;- RBS Royal Bank of Scotland, Visa Debit, UK (immediate authorisation)
					$aIINList[605]=475117 ;- RBS Royal Bank of Scotland, Visa Debit, UK
					$aIINList[606]=475118 ;- RBS Royal Bank of Scotland, Visa Debit, UK
					$aIINList[607]=475126 ;- RBS Royal Bank of Scotland, Visa Debit, UK
					$aIINList[608]=475127 ;- Natwest Visa Debit
					$aIINList[609]=475128 ;- Natwest Visa Debit
					$aIINList[610]=475129 ;- Natwest Visa Debit
					$aIINList[611]=475130 ;- Natwest Visa Debit
					$aIINList[612]=475131 ;- Nat West Visa Debit Card
					$aIINList[613]=475132 ;- Nat West Private Banking Visa Debit
					$aIINList[614]=475423 ;- MetaBank VISA TravelMoney, Debit
					$aIINList[615]=475427 ;- MetaBank Rebate Visa Card
					$aIINList[616]=475637 ;- WellsFargo Bank National Association, Visa Debit
					$aIINList[617]=475714 ;- Santander UK Visa Debit card
					$aIINList[618]=475743 ;- O2 Money Card (Ireland), prepaid
					$aIINList[619]=475747 ;- NatWest, VISA Debit, (UK)
					$aIINList[620]=475757 ;- O2 Money Card (UK) Prepaid ;- Virtual Card (Not known if also used for physical cards that are also issued)
					$aIINList[621]=476072 ;- may be HR Block prepaid Visa
					$aIINList[622]=476153 ;- US Bank VISA Signature business card ;- FlexPerks travel rewards
					$aIINList[623]=476225 ;- Bank Of Scotland Visa Debit Card
					$aIINList[624]=476515 ;- Venezolano de Credito Superefectiva Gold Visa Check card.
					$aIINList[625]=476559 ;- South Florida Educational Federal Credit Union Visa Debit Card
					$aIINList[626]=477361 ;- Big Sky Credit Union Visa (Australia)
					$aIINList[627]=477462 ;- Pioneer Trust Bank ;- Visa debit (USA)
					$aIINList[628]=477517 ;- JPMorgan Chase Bank N.A.
					$aIINList[629]=477548 ;- SEB ;- Visa debit (Estonia)
					$aIINList[630]=477596 ;- Sainsbury's Bank (UK) ;- Visa Debit Card
					$aIINList[631]=477597 ;- Capital One (Europe) Plc ;- VISA Credit Card
					$aIINList[632]=477913 ;- Deutsche Bank Visa credit card (Germany)
					$aIINList[633]=477915 ;- BZWBK (PL) ;- Visa Debit Card
					$aIINList[634]=478200 ;- BANK ONE ;- VISA CLASSIC ;-DEBIT
					$aIINList[635]=478657 ;- Nationwide Bank (USA) Visa Buxx
					$aIINList[636]=478825 ;- JPMorganChase Corporate Card
					$aIINList[637]=478880 ;- Umpqua Bank of Oregon Visa Debit Card
					$aIINList[638]=478901 ;- Vancity Visa credit card (Canada)
					$aIINList[639]=478907 ;- Vancity Visa credit card (Canada)
					$aIINList[640]=478986 ;- CIBC US Dollar Visa (Canada)
					$aIINList[641]=478992 ;- Heartland Credit Union (Springfield, IL)
					$aIINList[642]=479000 ;- Bulgarian Postbank VISA Credit card
					$aIINList[643]=479056 ;- First National Bank (South Africa) Visa Electron Debit Card
					$aIINList[644]=479080 ;- Visa Credit card BZWBK Polish bank
					$aIINList[645]=479087 ;- Alfa bank (Russia), Visa Platinum
					$aIINList[646]=479110 ;- Citibank Hong Kong Classic Visa Credit Card
					$aIINList[647]=479111 ;- Citibank Hong Kong Cold Visa Credit Card
					$aIINList[648]=479144 ;- Georgia Federal Credit Union
					$aIINList[649]=479213 ;- TD Banknorth Visa Debit Card
					$aIINList[650]=479293 ;- Abbey International Visa Debit Card
					$aIINList[651]=479348 ;- Vision Banco Visa Debit Card (Paraguay)
					$aIINList[652]=479731 ;- Swedbank Visa Electron (Estonia)
					$aIINList[653]=479769 ;- "Saint;-Petersburg Bank", Russia
					$aIINList[654]=479884 ;- E*Trade Visa Debit Card (U.S.)
					$aIINList[655]=480119 ;- Citigroup Inc. ;- MyECount.com Verizon Wireless' rebate debit card
					$aIINList[656]=480147 ;- Community Business Bank
					$aIINList[657]=480212 ;- Capital ONE FSB Business
					$aIINList[658]=480686 ;- Commonwealth Credit Union Visa Debit Card
					$aIINList[659]=480817 ;- WellsOne Commercial Card
					$aIINList[660]=482840 ;- Bank One (US) ;- Visa Debit Card
					$aIINList[661]=483312 ;-
					$aIINList[662]=483512 ;- Standard Charterd Bank Vietnam ;- Visa Debit Card
					$aIINList[663]=483531 ;- ANZ Bank New Zealand Limited ;- Visa Debit Card
					$aIINList[664]=483583 ;- Sony Finance International, Japan ;- Dual Currency (JPY/USD) Credit Card
					$aIINList[665]=483515 ;- Bank One Revolution VISA Platinum Credit Card (Singapore)
					$aIINList[666]=483564 ;- Canada Post Visa Electron Debit Card
					$aIINList[667]=483593 ;- HSBC Hong Kong business Platinum Credit Card (HK)
					$aIINList[668]=483741 ;- KiwiBank (NZ) Visa Debit Card
					$aIINList[669]=484412 ;- Paypal (UK) ;- Top;-up card (managed by RBS)
					$aIINList[670]=484474 ;- Bank Of Scotland (UK) ;- Visa Electron Card
					$aIINList[671]=484712 ;- Bank One ;- Vanilla Visa Giftcard
					$aIINList[672]=484823 ;- Public Bank Day2Day Visa Debit card (Malaysia)
					$aIINList[673]=485450 ;- HVB VISA Infinite
					$aIINList[674]=485051 ;- Orange County's Credit Union ;- Visa Credit Card
					$aIINList[675]=485342 ;- MBNA ;- Debit Card
					$aIINList[676]=485414 ;- Chukur Bukur Bank ;- Visa Debit Classic Card India
					$aIINList[677]=485415 ;- Chukur Bukur Bank ;- Visa Debit Classic Card India
					$aIINList[678]=485751 ;- Bankia (Spain) Visa Debit Card
					$aIINList[679]=485431 ;- Nonghyup Bank (KR) Visa Check Card
					$aIINList[680]=486213 ;- Capital One ;- Visa Platinum Credit Card
					$aIINList[681]=486239 ;- HSBC Platinum Visa Credit Card (India)
					$aIINList[682]=486290 ;- Australia Post Visa Debit (Australia)
					$aIINList[683]=486311 ;- Bank of China (HK) Visa Infinite
					$aIINList[684]=486412 ;- Lloyds TSB (UK) ;- Visa Card
					$aIINList[685]=486424 ;- VISA Credit Card, Barclays Bank, (UK)
					$aIINList[686]=486442 ;- HSBC (UK) ;- Commercial Visa credit Card
					$aIINList[687]=486912 ;- Plumas Bank California, (US) ;- Visa Business Check Card
					$aIINList[688]=486913 ;- Umpqua Bank of Oregon (US) ;- Visa Business Check Card
					$aIINList[689]=487211 ;- Hollywood Movie Money Certificate (US), issued by MetaBank
					$aIINList[690]=487242 ;- VISA Credit Card (PE), issued by ScotiaBank ;- Peru
					$aIINList[691]=487392 ;- Capital One Visa Gold Credit Card
					$aIINList[692]=487312 ;- Staples (US) Rebate Card, issued by Chase
					$aIINList[693]=488839 ;- Mayo Employees Federal Credit Union ;- Debit ;- USA
					$aIINList[694]=488939 ;- Lakshmi Vilas Bank (India)
					$aIINList[695]=489382 ;- ZoomPass pre;-paid visa card
					$aIINList[696]=489394 ;- Nationwide Building Society (UK) Visa Credit Card
					$aIINList[697]=489396 ;- Nationwide Building Society (UK) Visa Select Credit Card
					$aIINList[698]=490077 ;- RBC Bank (Georgia) N.A. VISA Debit Card (United States)
					$aIINList[699]=490080 ;- RBC Bank (Georgia) N.A. VISA Platinum Credit Card (United States)
					$aIINList[700]=490115 ;- First National Bank VISA South Africa / Cedyna INC Visa Japan
					$aIINList[701]=490220 ;- BC VISA Credit Card issued by Woori Bank
					$aIINList[702]=490285 ;- Public Bank (Hong Kong) VISA Platinum Card
					$aIINList[703]=490292 ;- NAB VISA Gold Debit Card (Australia)
					$aIINList[704]=490603 ;- BC VISA Credit Card issued by Industrial Bank of Korea
					$aIINList[705]=490606 ;- BC VISA Credit Card issued by Kookmin Bank
					$aIINList[706]=490611 ;- BC VISA Credit Card issued by Nonghyup Bank
					$aIINList[707]=490612 ;- BC VISA Credit Card issued by NACF Local Cooperatives
					$aIINList[708]=490620 ;- BC VISA Credit Card issued by Woori Bank
					$aIINList[709]=490623 ;- BC VISA Credit Card issued by SC First Bank
					$aIINList[710]=490625 ;- BC VISA Credit Card issued by Hana SK Card
					$aIINList[711]=490627 ;- BC VISA Credit Card issued by Citibank in Korea
					$aIINList[712]=490646 ;- The Bank Of Tokyo;-Mitsubishi UFJ (Japan)
					$aIINList[713]=490678 ;- BC VISA Credit Card issued by Shinhan Card
					$aIINList[714]=490696 ;- Citibank (Argentina)
					$aIINList[715]=490698 ;- Citibank Gold Credit Card (Argentina)
					$aIINList[716]=490762 ;- credit cards issued by Bayerische Landesbank (Germany) under various brands (e.g. "Bayerische Landesbank", "DKB")
					$aIINList[717]=490841 ;- Banco Espirito Santo Gold Visa Credit Card (Portugal)
					$aIINList[718]=490847 ;- Parex Bank Visa Credit Card
					$aIINList[719]=491002 ;- Citibank (UK) AAdvantage Gold Visa Card
					$aIINList[720]=491511 ;- Banco de Bogotá (Colombia) Visa Electron
					$aIINList[721]=491566 ;- Visa Electron ;- Banco Mercantil del Norte (Mexico)
					$aIINList[722]=491611 ;- Halifax Ireland VISA Credit Card
					$aIINList[723]=491731 ;- Abbey (bank) VISA Electron (UK)
					$aIINList[724]=491754 ;- Halifax (United Kingdom bank) VISA Electron (UK)
					$aIINList[725]=491859 ;- Danske Bank Privatkort Visa Electron debit card (SE)
					$aIINList[726]=492046 ;- Luottokunta issued VISA Gold (Finland)
					$aIINList[727]=492111 ;- HSBC Visa Credit Card (Hong Kong)
					$aIINList[728]=492127 ;- HSBC Visa Credit Card (Bermuda)
					$aIINList[729]=492160 ;- HSBC Visa Credit Card (Singapore)
					$aIINList[730]=492181 ;- Barclaycard Visa Debit Card
					$aIINList[731]=492182 ;- Barclaycard Visa Debit Card
					$aIINList[732]=492183 ;- Barclaycard Visa Debit Card
					$aIINList[733]=492184 ;- Barclaycard Visa Debit Card
					$aIINList[734]=492213 ;- Nedbank VISA Credit Card (ZA)
					$aIINList[735]=492231 ;- NTT FINANCE CORPORATION (Japan)
					$aIINList[736]=492827 ;- Barclays self;-service card (UK)
					$aIINList[737]=492910 ;- Barclaycard Visa Credit Card
					$aIINList[738]=492913 ;- (Barclaycard) Visa Credit Card (UK)
					$aIINList[739]=492940 ;- Barclaycard Visa Credit Card
					$aIINList[740]=492942 ;- Barclaycard Premier and OnePulse (Oyster) Visa Credit Cards with contactless payment (UK)
					$aIINList[741]=492946 ;- Barclaycard Business Visa Credit Card
					$aIINList[742]=492949 ;- Barclaycard Visa Initial Credit Card
					$aIINList[743]=493414 ;- Qantas Staff Credit Union Debit Card (Australia)
					$aIINList[744]=493467 ;- Bank of China Olympics Visa Credit Card (Singapore)
					$aIINList[745]=493468 ;- Bank of China Platinum Visa Credit Card (Singapore)
					$aIINList[746]=493795 ;- Orient Corporation (Japan)
					$aIINList[747]=493838 ;- CrediMax Visa credit card (Bahrain)
					$aIINList[748]=493861 ;- Bank Of China Credit Card VISA Classic (Hong Kong)
					$aIINList[749]=493878 ;- Bank Of China Great Wall Credit Card VISA Classic (Hong Kong)
					$aIINList[750]=493898 ;- Bank Of China Great Wall Credit Card VISA Gold (Hong Kong)
					$aIINList[751]=493881 ;- Bank Of China Credit Card (Hong Kong)
					$aIINList[752]=494052 ;- Commonwealth Bank VISA Credit Card (Australia)
					$aIINList[753]=494053 ;- Commonwealth Bank VISA Credit Card (Gold)(Australia)
					$aIINList[754]=494114 ;- National Bank of Abu Dhabi Cashplus Global Visa Electron (UAE)
					$aIINList[755]=494120 ;- HSBC Visa Gold Debit Card (United Kingdom)
					$aIINList[756]=495055 ;- Corner Visa Debit Card
					$aIINList[757]=496604 ;- HSBC Visa Credit Card (Hong Kong)
					$aIINList[758]=496645 ;- HSBC Visa Gold Credit Card (Singapore)
					$aIINList[759]=496657 ;- Standard Chartered Bank (Hong Kong)
					$aIINList[760]=496696 ;- HSBC Visa Gold Credit Card (Bermuda)
					$aIINList[761]=496698 ;- Bank Islam Malaysia Berhad VISA Premier Credit Card;-i (International)
					$aIINList[762]=497040 ;- La Banque Postale VISA (France)
					$aIINList[763]=497063 ;- La Banque Postale VISA (France)
					$aIINList[764]=497128 ;- Natixis / Banque Populaire (France)
					$aIINList[765]=497160 ;- HSBC Visa Credit Card (France)
					$aIINList[766]=497164 ;- Banque Accord Visa Credit Card (France)
					$aIINList[767]=497203 ;- CREDIT LYONNAIS Visa Credit Card (France)
					$aIINList[768]=497301 ;- Société Générale CB Visa (France)
					$aIINList[769]=497302 ;- Société Générale CB Visa (France)
					$aIINList[770]=497543 ;- Natexis Banques Populaires Visa Credit Card (France)
					$aIINList[771]=497545 ;- Natexis Banques Populaires Visa Credit Card (France)
					$aIINList[772]=497618 ;- Boursorama Visa Credit Card (France)
					$aIINList[773]=497652 ;- Barclays Bank PLC Visa Credit Card (France)
					$aIINList[774]=497671 ;- Credit du Nord Visa Credit Card (France)
					$aIINList[775]=497766 ;- Sachki Sabiram Bank ;- Visa Prachki Namiram prepaid Debit Card (Thailand)
					$aIINList[776]=497912 ;- Boursorama Banque VISA PREMIER/gold credit card (France)
					$aIINList[777]=498041 ;- Sumitomo Mitsui Card Company (Japan)
					$aIINList[778]=498021 ;- Sumitomo Mitsui Card Company (Japan)
					$aIINList[779]=498042 ;- Sumitomo Mitsui Card Company (Japan)
					$aIINList[780]=498022 ;- Pocket visa debit card (Japan)
					$aIINList[781]=498417 ;- Banco do Brasil Ourocard Visa Brasil
					$aIINList[782]=498474 ;- Macquarie Visa Platinum Credit Card
					$aIINList[783]=498542 ;- Banco Caja Social (Colombia) VISA Platinum Credit Card
					$aIINList[784]=498599 ;- ZUNO bank (Raiffeisen group) Cech republic Diamond Card
					$aIINList[785]=498864 ;- The Co;-operative Bank (incl Smile) Visa Debit Virtual GOLD Card (UK in £)
					$aIINList[786]=498857 ;- Citibank Colombia (Visa Debit Card)
					$aIINList[787]=499811 ;- DKB Deutsche Kreditbank AG Visa Debit Charge Card (Germany)
					$aIINList[788]=499897 ;- DKB Deutsche Kreditbank AG VISA credit card (Germany)
					$aIINList[789]=499977 ;- Bank of New Zealand VISA Credit Card
					$aIINList[790]=499985 ;- Bank of New Zealand VISA Gold Credit Card
				Case 4
					Local $aIINList[207]
					$aIINList[0]=4013 ;- Visa Debit Card
					$aIINList[1]=4016 ;- Citybank (El Salvador)
					$aIINList[2]=4018 ;- 1st Financial Bank USA
					$aIINList[3]=4019 ;- Wachovia Bank Visa
					$aIINList[4]=4026 ;- Nordea Bank, VISA Electron
					$aIINList[5]=4028 ;- HSBC Philippine Airlines Mabuhay Miles
					$aIINList[6]=4029 ;- TD Bank Debit Card
					$aIINList[7]=4035 ;- Visa Debit France/Canada
					$aIINList[8]=4037 ;- US Bank Visa (USA)
					$aIINList[9]=4060 ;- CHASE Visa Debit/Credit
					$aIINList[10]=4082 ;- Visa credit card - Aeromexico - Banamex (Banco Nacional de Mexico)
					$aIINList[11]=4117 ;- Bank of America (US; formerly Fleet) VISA Debit Card
					$aIINList[12]=4124 ;- Chase Banking Debit Card
					$aIINList[13]=4128 ;- Citibank (US) Platium Select Dividends VISA Credit Card[citation needed]
					$aIINList[14]=4130 ;- Visa Electron - Banca Afirme (Mexico)
					$aIINList[15]=4143 ;- Capital One - Visa Card
					$aIINList[16]=4146 ;- Urban Trust Bank - Salute Visa Card
					$aIINList[17]=4153 ;- Visa Platinum Japan
					$aIINList[18]=4166 ;- Kotak Mahindra Bank Gold Credit Card
					$aIINList[19]=4172 ;- Crédit Populaire d'Algérie (CPA), Algeria - Visa Gold Card
					$aIINList[20]=4177 ;- BC "Moldindconbank" S.A (Moldova)- Visa Electron
					$aIINList[21]=4185 ;- Washington Mutual (US) - Visa Card
					$aIINList[22]=4213 ;- China Minsheng Bank VISA Debit Card; Landesbank Berlin Xbox Live VISA Prepaid Card (Germany)
					$aIINList[23]=4216 ;- Debit Card Suruga bank (Japan)
					$aIINList[24]=4218 ;- China Minsheng Banking Corporation VISA Credit Card
					$aIINList[25]=4238 ;- Members Credit Union Visa Debit
					$aIINList[26]=4241 ;- Silverton Bank (Gift Card)
					$aIINList[27]=4241 ;- Visa Signature credit card, Scotibank Perú - Bank of nova scotia Perú -Scotiabank
					$aIINList[28]=4251 ;- Fidelity Debit Card issued by PNC
					$aIINList[29]=4256 ;- Bank of America GM Visa Check Card / US Airways Dividend Miles Visa Debit Card
					$aIINList[30]=4257 ;- Barclaycard Commercial
					$aIINList[31]=4259 ;- Banco BICE (Chile) Gold Visa Credit Card
					$aIINList[32]=4276 ;- Sberbank of Russia, Visa Classic/Electron
					$aIINList[33]=4279 ;- Sberbank of Russia, Visa Gold
					$aIINList[34]=4282 ;- Landesbank Berlin (Germany) Visa Credit Card
					$aIINList[35]=4284 ;- Standard Chartered Bank (Platinum), Sri Lanka
					$aIINList[36]=4301 ;- Chase Visa
					$aIINList[37]=4304 ;- Barclays Bank Plc
					$aIINList[38]=4308 ;- Macys Visa
					$aIINList[39]=4311 ;- National City Bank Visa Credit Card
					$aIINList[40]=4315 ;- Silverton Bank NA (closed in 2009)
					$aIINList[41]=4312 ;- Chase Leisure Rewards Visa Business Debit/Check Card
					$aIINList[42]=4318 ;- S-Bank Visa
					$aIINList[43]=4321 ;- Citizens Bank of Canada/Vancouver City Savings Credit Union Visa Gift Card
					$aIINList[44]=4323 ;- Wells Fargo Visa check card
					$aIINList[45]=4342 ;- Bank of America Classic Visa Credit Card
					$aIINList[46]=4343 ;- First Interstate Bank Visa Credit Card
					$aIINList[47]=4344 ;- Landesbank Berlin Holding Visa Credit Card (Amazon.de Credit Card)
					$aIINList[48]=4346 ;- Santander Consumer Bank AS (formerly Bankia Bank ASA) - Gebyrfri Visa, Credit Card (Norway)
					$aIINList[49]=4349 ;- Chase Card Services Canada Marriott Rewards Platinum Visa Card
					$aIINList[50]=4355 ;- U.S. Bank Premiere Line Visa Card
					$aIINList[51]=4356 ;- Target Corporation Visa Credit Card
					$aIINList[52]=4356 ;- Bank of America Visa Debit Card
					$aIINList[53]=4367 ;- China Construction Bank Credit Card
					$aIINList[54]=4377 ;- Panin Bank - Indonesia, Visa, Platinum Card
					$aIINList[55]=4380 ;- Bank of China Olympics Visa Credit Card
					$aIINList[56]=4382 ;- UOB Campus Visa Debit Card (Singapore)
					$aIINList[57]=4384 ;- HSBC Visa Credit Card (India)
					$aIINList[58]=4388 ;- Capital One Visa Credit Card
					$aIINList[59]=4390 ;- ChequeMax (El Salvador)
					$aIINList[60]=4391 ;- Krungthai Bank - Platinum (Thailand)
					$aIINList[61]=4404 ;- (UBP-php)
					$aIINList[62]=4405 ;- Latvijas Krājbanka (LV)
					$aIINList[63]=4408 ;- Chase (AARP)
					$aIINList[64]=4428 ;- BECU Visa
					$aIINList[65]=4430 ;- PNC Bank (Debit Card) (former National City Debit)
					$aIINList[66]=4435 ;- Banner Bank VISA (Debit Card)
					$aIINList[67]=4432 ;- U.S. Bank
					$aIINList[68]=4436 ;- PNC Bank Visa Points
					$aIINList[69]=4451 ;- First Tennessee Bank (USA) VISA Debit Card
					$aIINList[70]=4458 ;- Nationwide Building Society (UK) - Plus (interbank network) Cash Card for use with savings accounts
					$aIINList[71]=4465 ;- Wells Fargo (USA) - Visa Credit Card
					$aIINList[72]=4470 ;- M&I Marshall & Ilsley Bank (USA) - Visa debit Card
					$aIINList[73]=4479 ;- TCF Bank Debit Card
					$aIINList[74]=4481 ;- BC Card VISA Check Card
					$aIINList[75]=4482 ;- TD Bank
					$aIINList[76]=4486 ;- GSA SmartPay 2 - Travel charge card
					$aIINList[77]=4488 ;- Suntrust Bank - Visa Credit Card
					$aIINList[78]=4489 ;- National City Bank Visa Debit Card (Credit Card?)
					$aIINList[79]=4490 ;- Community Trust Bank( Visa Debit Card)
					$aIINList[80]=4492 ;- Vista Federal Credit Union (Walt Disney World) Visa Debit Card
					$aIINList[81]=4493 ;- Nicu Dinu's Bank ( Cernavoda, Romania )
					$aIINList[82]=4500 ;- Canadian Imperial Bank of Commerce (CIBC) Visa & MBNA Quantum Visa Credit Cards
					$aIINList[83]=4502 ;- CIBC VISA
					$aIINList[84]=4503 ;- CIBC VISA
					$aIINList[85]=4504 ;- CIBC VISA
					$aIINList[86]=4505 ;- CIBC VISA
					$aIINList[87]=4506 ;- CIBC VISA Debit
					$aIINList[88]=4506 ;- Marfin Laiki Bank Visa Debit Card
					$aIINList[89]=4507 ;- St George Bank Visa Debit Card
					$aIINList[90]=4508 ;- Visa Electron - Popular Bank (NY) a Branch of Banco Popular Dominicano
					$aIINList[91]=4509 ;- ANZ Bank Visa Credit Card
					$aIINList[92]=4510 ;- Royal Bank of Canada (CA) - Visa
					$aIINList[93]=4511 ;- Seylan Bank, Sri Lanka
					$aIINList[94]=4512 ;- Royal Bank of Canada (CA) - Visa
					$aIINList[95]=4513 ;- Bancolombia (CB)
					$aIINList[96]=4514 ;- Royal Bank of Canada RBC AVION Visa (Platinum/Infinite)
					$aIINList[97]=4516 ;- RBC Banque Royale VISA BUSINESS (Affaires) - VISA
					$aIINList[98]=4519 ;- Royal Bank of Canada (CA) - Client Card (ATM/INTERAC)
					$aIINList[99]=4520 ;- TD Bank CAD VISA
					$aIINList[100]=4529 ;- MetaBank Visa
					$aIINList[101]=4530 ;- VISA Desjardins Group
					$aIINList[102]=4535 ;- Scotiabank - Visa Card
					$aIINList[103]=4536 ;- Scotiabank - Interac Debit Card
					$aIINList[104]=4537 ;- Scotiabank - Visa Card
					$aIINList[105]=4538 ;- Scotiabank - Visa Card
					$aIINList[106]=4540 ;- Carte d'accès Desjardins / VISA Desjardins
					$aIINList[107]=4541 ;- Standard Chartered Manhattan Platinum VISA (India)
					$aIINList[108]=4543 ;- Visa Debit UK
					$aIINList[109]=4544 ;- Banque Laurentienne du Canada / Laurentian Bank of Canada (CA) - Visa
					$aIINList[110]=4545 ;- BANESCO (former BancUnion Visa) - Venezuela.
					$aIINList[111]=4549 ;- Banco Popular de Puerto Rico - Visa credit and debit cards
					$aIINList[112]=4551 ;- Visa debit card BBVA Banco Continental Perú. BBVA group.
					$aIINList[113]=4551 ;- TD Bank/Driver's Rewards CAD VISA
					$aIINList[114]=4552 ;- Cooperative Bank (UK)
					$aIINList[115]=4553 ;- Wing Hang Bank Credit Card (Hong Kong)
					$aIINList[116]=4555 ;- Cooperative Bank Platinum VISA (UK)
					$aIINList[117]=4555 ;- Bank of Ceylon VISA Credit Card (UK)
					$aIINList[118]=4556 ;- Citibank Visa Vodafone (Greece)
					$aIINList[119]=4557 ;- Debit Card Bank of credit (PE)
					$aIINList[120]=4559 ;- CHASE (formerly Washington Mutual/Providian) Platinum VISA Credit Card
					$aIINList[121]=4560 ;- ANZ Visa Debit Card
					$aIINList[122]=4563 ;- BMW VISA ICS International Card Services (The Netherlands)
					$aIINList[123]=4563 ;- Citibank Malaysia (MY) - Visa Credit Card
					$aIINList[124]=4564 ;- BancoEstado - CHILE
					$aIINList[125]=4565 ;- ABSA VISA
					$aIINList[126]=4568 ;- Berliner Bank (DE) - Visa Debit Card
					$aIINList[127]=4569 ;- Skandiabanken VISA Debit Card (NO)
					$aIINList[128]=4570 ;- DZ Bank VISA Credit Card (DE)
					$aIINList[129]=4571 ;- All Danish VISA-cards (Visa/Dankort)
					$aIINList[130]=4579 ;- KB Card VISA Gold Card
					$aIINList[131]=4580 ;- Leumi Card (IL) - Visa Card (Leumi Bank)
					$aIINList[132]=4580 ;- Israeli Credit Cards (ICC) (IL) - Visa Card (Discount Bank and other partners)
					$aIINList[133]=4585 ;- HSBC Bank Australia VISA Debit Card
					$aIINList[134]=4587 ;- Peoples Trust Visa Gift Card
					$aIINList[135]=4599 ;- Caja Madrid, now Bankia (ES)
					$aIINList[136]=4640 ;- Amazon (US)
					$aIINList[137]=4645 ;- Citibank VISA Credit Card (Australia)
					$aIINList[138]=4608 ;- Suncoast Schools Federal Credit Union
					$aIINList[139]=4614 ;- GSA SmartPay 2 - Travel charge card
					$aIINList[140]=4677 ;- Peoples Trust nextwave Titanium+ Prepaid Visa Card (Canada)
					$aIINList[141]=4705 ;- Citibank Hong Kong
					$aIINList[142]=4715 ;- Wachovia VISA
					$aIINList[143]=4718 ;- Target Corporation VISA Gift Card
					$aIINList[144]=4720 ;- HSBC VISA (Platinum/Signature), Sri Lanka
					$aIINList[145]=4736 ;- [GE Money Bank] Walmart Prepaid Visa Debit Card, USA
					$aIINList[146]=4741 ;- Visa Electron - Banco Regional de Monterrey (Mexico)
					$aIINList[147]=4744 ;- Bank of America Visa Debit
					$aIINList[148]=4758 ;- Oregon Community Credit Union
					$aIINList[149]=4760 ;- Bank Niaga (Indonesia) Visa Debit Card
					$aIINList[150]=4761 ;- TCF Bank Saint Paul MN (USA) Visa Debit Card
					$aIINList[151]=4762 ;- TCF Bank Saint Paul MN (USA) Visa Debit Card
					$aIINList[152]=4763 ;- TCF Bank Saint Paul MN (USA) Visa Debit Card
					$aIINList[153]=4764 ;- TCF Bank Saint Paul MN (USA) Visa Debit Card
					$aIINList[154]=4773 ;- Siam Commercial Bank - platinum (Thailand)
					$aIINList[155]=4797 ;- SEB bankas Visa Debit Card (Lithuania)
					$aIINList[156]=4779 ;- Sainsbury's Bank (UK) - Visa Debit Card
					$aIINList[157]=4798 ;- US Bank Visa Select Rewards Business Platinum
					$aIINList[158]=4800 ;- Standard Charterd Bank Vietnam Gold Visa Debit Card
					$aIINList[159]=4807 ;- M&I Visa Credit Card
					$aIINList[160]=4809 ;- Capital One - Visa Platinum Check Card
					$aIINList[161]=4815 ;- Bank of America - Debit Card
					$aIINList[162]=4820 ;- Wings Financial FCU Credit Card (also Metro Community FCU)
					$aIINList[163]=4824 ;- Wirecard Bank Visa Card
					$aIINList[164]=4828 ;- Bank One (US) - Visa Debit Card
					$aIINList[165]=4835 ;- Bank of China (Hong Kong) Visa Platinum Credit Card
					$aIINList[166]=4841 ;- Old National Bank Commercial Debit Card
					$aIINList[167]=4842 ;- Maybank-issued Visa Credit Card (Malaysia)
					$aIINList[168]=4843 ;- Digital FCU Visa Gold Credit Card
					$aIINList[169]=4854 ;- Washington Mutual (US) - Visa Debit Card
					$aIINList[170]=4861 ;- Wings Financial FCU Check Card
					$aIINList[171]=4862 ;- Capital One Visa Credit Card
					$aIINList[172]=4873 ;- Capital One Orbitz Visa Platinum Credit Card
					$aIINList[173]=4867 ;- JP Morgan Chase Bank (US) - Visa Card
					$aIINList[174]=4868 ;- Wells Fargo (US) - Bank N.A. Check Card
					$aIINList[175]=4888 ;- Bank of America UK - Visa Credit Card
					$aIINList[176]=4890 ;- QIWI Bank Visa Card
					$aIINList[177]=4892 ;- [Columbus Bank and Trust Company] Green dot NASCAR Debit Visa Debit card
					$aIINList[178]=4903 ;- Switch (Debit Card)
					$aIINList[179]=4904 ;- Banner Bank VISA (Credit)
					$aIINList[180]=4905 ;- Switch (Debit Card)
					$aIINList[181]=4906 ;- Barclaycard VISA Credit Card (Germany)
					$aIINList[182]=4906 ;- BC VISA Credit Card (Korea)
					$aIINList[183]=4907 ;- Citibank Credit Card (Japan)
					$aIINList[184]=4909 ;- Northern Rock - Building Society - Visa Debit Card (UK)
					$aIINList[185]=4910 ;- HSBC Bank VISA Credit Card (Sri Lanka).
					$aIINList[186]=4911 ;- Switch (Debit Card)
					$aIINList[187]=4912 ;- HSBC UAE
					$aIINList[188]=4913 ;- Visa Electron
					$aIINList[189]=4914 ;- Banrisul Visa
					$aIINList[190]=4915 ;- Republic Bank Limited VISA Credit Card (Trinidad & Tobago)
					$aIINList[191]=4917 ;- Visa Electron
					$aIINList[192]=4918 ;- Caja Madrid VISA Business Credit Card (Spain)
					$aIINList[193]=4919 ;- Charles Schwab Bank VISA Check Card
					$aIINList[194]=4920 ;- Luottokunta issued VISA (Finland); Citibank UAE issued Visa Credit Card
					$aIINList[195]=4921 ;- Lloyds TSB Visa Debit Card
					$aIINList[196]=4925 ;- Visa Debit Card (Norway)
					$aIINList[197]=4929 ;- Visa Debit Card UK
					$aIINList[198]=4931 ;- Visa Citi AA - American Airlines (Dominican Republic)
					$aIINList[199]=4935 ;- Credito Siciliano Visa Electron (Italy)
					$aIINList[200]=4936 ;- Switch (Debit Card)
					$aIINList[201]=4937 ;- Standard Chartered Bank UAE issued Visa credit card
					$aIINList[202]=4960 ;- Emporiki Bank Visa Credit Card (Greece)
					$aIINList[203]=4974 ;- BNP Paribas (France)
					$aIINList[204]=4978 ;- Caisse d'Epargne VISA Credit Card (France)
					$aIINList[205]=4327 ;- North Carolina State Employees' Credit Union VISA Check Card
					$aIINList[206]=4412 ;- Deutsche Bank (DE) Gold Credit Card except 97
			EndSwitch
		Case 5 ;MasterCard
			Switch $Length
				Case 6
					Local $aIINList[1779]
					$aIINList[0]=500235 ;- CA National Bank of Canada ATM/Debit Card
					$aIINList[1]=500766 ;- CA Bank of Montreal ATM/Debit Card
					$aIINList[2]=501007 ;- AU Westpac Banking Corporation Handycard ATM (including Cirrus) and eftpos card
					$aIINList[3]=501008 ;- AU Westpac Banking Corporation Mondex purse card (2000 trial ;- no longer used)
					$aIINList[4]=501012 ;- CA Meridian Credit Union Debit and Exchange Network Card
					$aIINList[5]=502029 ;- ASPIDER Smartcards for Mobile Telecommunications
					$aIINList[6]=502123 ;- KR Kookmin Card Check Card (Maestro Debit Card)
					$aIINList[7]=503615 ;- ZA Standard Bank of South Africa Maestro Debit Card
					$aIINList[8]=504507 ;- Barnes & Noble Gift Card
					$aIINList[9]=504834 ;- IN ING Vysya Bank Maestro Debit/ATM Card
					$aIINList[10]=504837 ;- US Fleet Bank ATM Only Card.
					$aIINList[11]=507704 ;- US Maestro Indiana EBT Card
					$aIINList[12]=507708 ;- US Maestro Wisconsin EBT Card
					$aIINList[13]=507709 ;- US Maestro Kentucky EBT Card
					$aIINList[14]=507711 ;- US Maestro Michigan EBT Card
					$aIINList[15]=507717 ;- US Maestro Texas EBT Card
					$aIINList[16]=507719 ;- US Maestro California EBT Card
					$aIINList[17]=507720 ;- US Maestro West Virginia EBT Card∤
					$aIINList[18]=510000 ;- RO Amro Bank
					$aIINList[19]=510001 ;- GR Agricultural Bank of Greece
					$aIINList[20]=510002 ;- EE Estonia Credit Bank
					$aIINList[21]=510003 ;- KR Samsung Card Co
					$aIINList[22]=510005 ;- TR HSBC
					$aIINList[23]=510008 ;- NL VSB International
					$aIINList[24]=510009 ;- CH Europay
					$aIINList[25]=510010 ;- PL Powszchny Bank Kredytowy Warszawie
					$aIINList[26]=510011 ;- CH Europay
					$aIINList[27]=510013 ;- ES SEMP
					$aIINList[28]=510014 ;- ES SEMP
					$aIINList[29]=510015 ;- GR Agricultural Bank of Greece
					$aIINList[30]=510016 ;- GR Agricultural Bank of Greece
					$aIINList[31]=510017 ;- ES Fimestic Bank
					$aIINList[32]=510018 ;- PL PKO Savings Bank
					$aIINList[33]=510019 ;- HU Budapest Bank Ltd Investment Card, embossed.
					$aIINList[34]=510021 ;- CH Europay
					$aIINList[35]=510022 ;- CH Europay
					$aIINList[36]=510023 ;- CH Europay
					$aIINList[37]=510024 ;- ES SEMP
					$aIINList[38]=510025 ;- ES SEMP
					$aIINList[39]=510029 ;- NL VSB International
					$aIINList[40]=510030 ;- FI SEB Kort
					$aIINList[41]=510034 ;- ES Fimestic Bank
					$aIINList[42]=510035 ;- BY Belarus Bank
					$aIINList[43]=510036 ;- AD Sabadell Bank of Andorra
					$aIINList[44]=510037 ;- GR General Bank of Greece
					$aIINList[45]=510038 ;- RU Bank of Trade Unions Solidarity and Social Investment (Solidarnost)
					$aIINList[46]=510039 ;- RU Bank of Trade Unions Solidarity and Social Investment (Solidarnost)
					$aIINList[47]=510040 ;- US 5-Star Bank
					$aIINList[48]=510060 ;- ES SEMP
					$aIINList[49]=510061 ;- ES SEMP
					$aIINList[50]=510062 ;- ES SEMP
					$aIINList[51]=510087 ;- ES Santander Bank Debit Card
					$aIINList[52]=510136 ;- CZ CitiBank Gold Credit Card
					$aIINList[53]=510142 ;- CZ CitiBank
					$aIINList[54]=510197 ;- UBS AG MasterCard
					$aIINList[55]=510241 ;- UK RBS
					$aIINList[56]=510259 ;- PL Alior Sync MasterCard Debit Card
					$aIINList[57]=510782 ;- US FirstMerit Corporation MasterCard Debit Card
					$aIINList[58]=510840 ;- The Bancorp Bank Higher One MasterCard Debit Card
					$aIINList[59]=510875 ;- US Lake Michigan Credit Union MasterCard Debit Card
					$aIINList[60]=510982 ;- US USAA USAA Cash Rewards Debit MasterCard
					$aIINList[61]=511000 ;- US Chase Manhattan Bank USA
					$aIINList[62]=511001 ;- US Chase Manhattan Bank USA
					$aIINList[63]=511002 ;- US Chase Manhattan Bank USA
					$aIINList[64]=511003 ;- US Chase Manhattan Bank USA
					$aIINList[65]=511004 ;- US Chase Manhattan Bank USA
					$aIINList[66]=511005 ;- US Chase Manhattan Bank USA
					$aIINList[67]=511006 ;- US Chase Manhattan Bank USA
					$aIINList[68]=511007 ;- US Chase Manhattan Bank USA
					$aIINList[69]=511008 ;- US Chase Manhattan Bank USA
					$aIINList[70]=511009 ;- US Chase Manhattan Bank USA
					$aIINList[71]=511010 ;- US Chase Manhattan Bank USA
					$aIINList[72]=511011 ;- US Chase Manhattan Bank USA
					$aIINList[73]=511012 ;- US Chase Manhattan Bank USA
					$aIINList[74]=511013 ;- US Chase Manhattan Bank USA
					$aIINList[75]=511014 ;- US Chase Manhattan Bank USA
					$aIINList[76]=511015 ;- US Chase Manhattan Bank USA
					$aIINList[77]=511016 ;- US Chase Manhattan Bank USA
					$aIINList[78]=511017 ;- US Chase Manhattan Bank USA
					$aIINList[79]=511018 ;- US Chase Manhattan Bank USA
					$aIINList[80]=511019 ;- US Chase Manhattan Bank USA
					$aIINList[81]=511020 ;- US Chase Manhattan Bank USA
					$aIINList[82]=511021 ;- US Chase Manhattan Bank USA
					$aIINList[83]=511022 ;- US Chase Manhattan Bank USA
					$aIINList[84]=511023 ;- US Chase Manhattan Bank USA
					$aIINList[85]=511024 ;- US Chase Manhattan Bank USA
					$aIINList[86]=511025 ;- US Chase Manhattan Bank USA
					$aIINList[87]=511026 ;- US Chase Manhattan Bank USA
					$aIINList[88]=511027 ;- US Chase Manhattan Bank USA
					$aIINList[89]=511028 ;- US Chase Manhattan Bank USA
					$aIINList[90]=511029 ;- US Chase Manhattan Bank USA
					$aIINList[91]=511030 ;- US Chase Manhattan Bank USA
					$aIINList[92]=511031 ;- US Chase Manhattan Bank USA
					$aIINList[93]=511032 ;- US Chase Manhattan Bank USA
					$aIINList[94]=511033 ;- US Chase Manhattan Bank USA
					$aIINList[95]=511034 ;- US Chase Manhattan Bank USA
					$aIINList[96]=511035 ;- US Chase Manhattan Bank USA
					$aIINList[97]=511036 ;- US Chase Manhattan Bank USA
					$aIINList[98]=511037 ;- US Chase Manhattan Bank USA
					$aIINList[99]=511038 ;- US Chase Manhattan Bank USA
					$aIINList[100]=511039 ;- US Chase Manhattan Bank USA
					$aIINList[101]=511040 ;- US Chase Manhattan Bank USA
					$aIINList[102]=511041 ;- US Chase Manhattan Bank USA
					$aIINList[103]=511042 ;- US Chase Manhattan Bank USA
					$aIINList[104]=511043 ;- US Chase Manhattan Bank USA
					$aIINList[105]=511044 ;- US Chase Manhattan Bank USA
					$aIINList[106]=511045 ;- US Chase Manhattan Bank USA
					$aIINList[107]=511046 ;- US Chase Manhattan Bank USA
					$aIINList[108]=511047 ;- US Chase Manhattan Bank USA
					$aIINList[109]=511048 ;- US Chase Manhattan Bank USA
					$aIINList[110]=511049 ;- US Chase Manhattan Bank USA
					$aIINList[111]=511050 ;- US Chase Manhattan Bank USA
					$aIINList[112]=511051 ;- US Chase Manhattan Bank USA
					$aIINList[113]=511052 ;- US Chase Manhattan Bank USA
					$aIINList[114]=511053 ;- US Chase Manhattan Bank USA
					$aIINList[115]=511054 ;- US Chase Manhattan Bank USA
					$aIINList[116]=511055 ;- US Chase Manhattan Bank USA
					$aIINList[117]=511056 ;- US Chase Manhattan Bank USA
					$aIINList[118]=511057 ;- US Chase Manhattan Bank USA
					$aIINList[119]=511058 ;- US Chase Manhattan Bank USA
					$aIINList[120]=511059 ;- US Chase Manhattan Bank USA
					$aIINList[121]=511060 ;- US Chase Manhattan Bank USA
					$aIINList[122]=511061 ;- US Chase Manhattan Bank USA
					$aIINList[123]=511062 ;- US Chase Manhattan Bank USA
					$aIINList[124]=511063 ;- US Chase Manhattan Bank USA
					$aIINList[125]=511064 ;- US Chase Manhattan Bank USA
					$aIINList[126]=511065 ;- US Chase Manhattan Bank USA
					$aIINList[127]=511066 ;- US Chase Manhattan Bank USA
					$aIINList[128]=511067 ;- US Chase Manhattan Bank USA
					$aIINList[129]=511068 ;- US Chase Manhattan Bank USA
					$aIINList[130]=511069 ;- US Chase Manhattan Bank USA
					$aIINList[131]=511070 ;- US Chase Manhattan Bank USA
					$aIINList[132]=511071 ;- US Chase Manhattan Bank USA
					$aIINList[133]=511072 ;- US Chase Manhattan Bank USA
					$aIINList[134]=511073 ;- US Chase Manhattan Bank USA
					$aIINList[135]=511074 ;- US Chase Manhattan Bank USA
					$aIINList[136]=511075 ;- US Chase Manhattan Bank USA
					$aIINList[137]=511076 ;- US Chase Manhattan Bank USA
					$aIINList[138]=511077 ;- US Chase Manhattan Bank USA
					$aIINList[139]=511078 ;- US Chase Manhattan Bank USA
					$aIINList[140]=511079 ;- US Chase Manhattan Bank USA
					$aIINList[141]=511080 ;- US Chase Manhattan Bank USA
					$aIINList[142]=511081 ;- US Chase Manhattan Bank USA
					$aIINList[143]=511082 ;- US Chase Manhattan Bank USA
					$aIINList[144]=511083 ;- US Chase Manhattan Bank USA
					$aIINList[145]=511084 ;- US Chase Manhattan Bank USA
					$aIINList[146]=511085 ;- US Chase Manhattan Bank USA
					$aIINList[147]=511086 ;- US Chase Manhattan Bank USA
					$aIINList[148]=511087 ;- US Chase Manhattan Bank USA
					$aIINList[149]=511088 ;- US Chase Manhattan Bank USA
					$aIINList[150]=511089 ;- US Chase Manhattan Bank USA
					$aIINList[151]=511090 ;- US Chase Manhattan Bank USA
					$aIINList[152]=511091 ;- US Chase Manhattan Bank USA
					$aIINList[153]=511092 ;- US Chase Manhattan Bank USA
					$aIINList[154]=511093 ;- US Chase Manhattan Bank USA
					$aIINList[155]=511094 ;- US Chase Manhattan Bank USA
					$aIINList[156]=511095 ;- US Chase Manhattan Bank USA
					$aIINList[157]=511096 ;- US Chase Manhattan Bank USA
					$aIINList[158]=511097 ;- US Chase Manhattan Bank USA
					$aIINList[159]=511098 ;- US Chase Manhattan Bank USA
					$aIINList[160]=511099 ;- US Chase Manhattan Bank USA
					$aIINList[161]=511100 ;- US Chase Manhattan Bank USA
					$aIINList[162]=511101 ;- US Chase Manhattan Bank USA
					$aIINList[163]=511102 ;- US Chase Manhattan Bank USA
					$aIINList[164]=511103 ;- US Chase Manhattan Bank USA
					$aIINList[165]=511104 ;- US Chase Manhattan Bank USA
					$aIINList[166]=511105 ;- US Chase Manhattan Bank USA
					$aIINList[167]=511106 ;- US Chase Manhattan Bank USA
					$aIINList[168]=511107 ;- US Chase Manhattan Bank USA
					$aIINList[169]=511108 ;- US Chase Manhattan Bank USA
					$aIINList[170]=511109 ;- US Chase Manhattan Bank USA
					$aIINList[171]=511110 ;- US Chase Manhattan Bank USA
					$aIINList[172]=511111 ;- US Chase Manhattan Bank USA
					$aIINList[173]=511112 ;- US Chase Manhattan Bank USA
					$aIINList[174]=511113 ;- US Chase Manhattan Bank USA
					$aIINList[175]=511114 ;- US Chase Manhattan Bank USA
					$aIINList[176]=511115 ;- US Chase Manhattan Bank USA
					$aIINList[177]=511116 ;- US Chase Manhattan Bank USA
					$aIINList[178]=511117 ;- US Chase Manhattan Bank USA
					$aIINList[179]=511118 ;- US Chase Manhattan Bank USA
					$aIINList[180]=511119 ;- US Chase Manhattan Bank USA
					$aIINList[181]=511120 ;- US Chase Manhattan Bank USA
					$aIINList[182]=511121 ;- US Chase Manhattan Bank USA
					$aIINList[183]=511122 ;- US Chase Manhattan Bank USA
					$aIINList[184]=511123 ;- US Chase Manhattan Bank USA
					$aIINList[185]=511124 ;- US Chase Manhattan Bank USA
					$aIINList[186]=511125 ;- US Chase Manhattan Bank USA
					$aIINList[187]=511126 ;- US Chase Manhattan Bank USA
					$aIINList[188]=511127 ;- US Chase Manhattan Bank USA
					$aIINList[189]=511128 ;- US Chase Manhattan Bank USA
					$aIINList[190]=511129 ;- US Chase Manhattan Bank USA
					$aIINList[191]=511130 ;- US Chase Manhattan Bank USA
					$aIINList[192]=511131 ;- US Chase Manhattan Bank USA
					$aIINList[193]=511132 ;- US Chase Manhattan Bank USA
					$aIINList[194]=511133 ;- US Chase Manhattan Bank USA
					$aIINList[195]=511134 ;- US Chase Manhattan Bank USA
					$aIINList[196]=511135 ;- US Chase Manhattan Bank USA
					$aIINList[197]=511136 ;- US Chase Manhattan Bank USA
					$aIINList[198]=511137 ;- US Chase Manhattan Bank USA
					$aIINList[199]=511138 ;- US Chase Manhattan Bank USA
					$aIINList[200]=511139 ;- US Chase Manhattan Bank USA
					$aIINList[201]=511140 ;- US Chase Manhattan Bank USA
					$aIINList[202]=511141 ;- US Chase Manhattan Bank USA
					$aIINList[203]=511142 ;- US Chase Manhattan Bank USA
					$aIINList[204]=511143 ;- US Chase Manhattan Bank USA
					$aIINList[205]=511144 ;- US Chase Manhattan Bank USA
					$aIINList[206]=511145 ;- US Chase Manhattan Bank USA
					$aIINList[207]=511146 ;- US Chase Manhattan Bank USA
					$aIINList[208]=511147 ;- US Chase Manhattan Bank USA
					$aIINList[209]=511148 ;- US Chase Manhattan Bank USA
					$aIINList[210]=511149 ;- US Chase Manhattan Bank USA
					$aIINList[211]=511150 ;- US Chase Manhattan Bank USA
					$aIINList[212]=511151 ;- US Chase Manhattan Bank USA
					$aIINList[213]=511152 ;- US Chase Manhattan Bank USA
					$aIINList[214]=511153 ;- US Chase Manhattan Bank USA
					$aIINList[215]=511154 ;- US Chase Manhattan Bank USA
					$aIINList[216]=511155 ;- US Chase Manhattan Bank USA
					$aIINList[217]=511156 ;- US Chase Manhattan Bank USA
					$aIINList[218]=511157 ;- US Chase Manhattan Bank USA
					$aIINList[219]=511158 ;- US Chase Manhattan Bank USA
					$aIINList[220]=511159 ;- US Chase Manhattan Bank USA
					$aIINList[221]=511160 ;- US Chase Manhattan Bank USA
					$aIINList[222]=511161 ;- US Chase Manhattan Bank USA
					$aIINList[223]=511162 ;- US Chase Manhattan Bank USA
					$aIINList[224]=511163 ;- US Chase Manhattan Bank USA
					$aIINList[225]=511164 ;- US Chase Manhattan Bank USA
					$aIINList[226]=511165 ;- US Chase Manhattan Bank USA
					$aIINList[227]=511166 ;- US Chase Manhattan Bank USA
					$aIINList[228]=511167 ;- US Chase Manhattan Bank USA
					$aIINList[229]=511168 ;- US Chase Manhattan Bank USA
					$aIINList[230]=511169 ;- US Chase Manhattan Bank USA
					$aIINList[231]=511170 ;- US Chase Manhattan Bank USA
					$aIINList[232]=511171 ;- US Chase Manhattan Bank USA
					$aIINList[233]=511172 ;- US Chase Manhattan Bank USA
					$aIINList[234]=511173 ;- US Chase Manhattan Bank USA
					$aIINList[235]=511174 ;- US Chase Manhattan Bank USA
					$aIINList[236]=511175 ;- US Chase Manhattan Bank USA
					$aIINList[237]=511176 ;- US Chase Manhattan Bank USA
					$aIINList[238]=511177 ;- US Chase Manhattan Bank USA
					$aIINList[239]=511178 ;- US Chase Manhattan Bank USA
					$aIINList[240]=511179 ;- US Chase Manhattan Bank USA
					$aIINList[241]=511180 ;- US Chase Manhattan Bank USA
					$aIINList[242]=511181 ;- US Chase Manhattan Bank USA
					$aIINList[243]=511182 ;- US Chase Manhattan Bank USA
					$aIINList[244]=511183 ;- US Chase Manhattan Bank USA
					$aIINList[245]=511184 ;- US Chase Manhattan Bank USA
					$aIINList[246]=511185 ;- US Chase Manhattan Bank USA
					$aIINList[247]=511186 ;- US Chase Manhattan Bank USA
					$aIINList[248]=511187 ;- US Chase Manhattan Bank USA
					$aIINList[249]=511188 ;- US Chase Manhattan Bank USA
					$aIINList[250]=511189 ;- US Chase Manhattan Bank USA
					$aIINList[251]=511190 ;- US Chase Manhattan Bank USA
					$aIINList[252]=511191 ;- US Chase Manhattan Bank USA
					$aIINList[253]=511192 ;- US Chase Manhattan Bank USA
					$aIINList[254]=511193 ;- US Chase Manhattan Bank USA
					$aIINList[255]=511194 ;- US Chase Manhattan Bank USA
					$aIINList[256]=511195 ;- US Chase Manhattan Bank USA
					$aIINList[257]=511196 ;- US Chase Manhattan Bank USA
					$aIINList[258]=511197 ;- US Chase Manhattan Bank USA
					$aIINList[259]=511198 ;- US Chase Manhattan Bank USA
					$aIINList[260]=511199 ;- US Chase Manhattan Bank USA
					$aIINList[261]=511200 ;- US Chase Manhattan Bank USA
					$aIINList[262]=511201 ;- US Chase Manhattan Bank USA
					$aIINList[263]=511202 ;- US Chase Manhattan Bank USA
					$aIINList[264]=511203 ;- US Chase Manhattan Bank USA
					$aIINList[265]=511204 ;- US Chase Manhattan Bank USA
					$aIINList[266]=511205 ;- US Chase Manhattan Bank USA
					$aIINList[267]=511206 ;- US Chase Manhattan Bank USA
					$aIINList[268]=511207 ;- US Chase Manhattan Bank USA
					$aIINList[269]=511208 ;- US Chase Manhattan Bank USA
					$aIINList[270]=511209 ;- US Chase Manhattan Bank USA
					$aIINList[271]=511210 ;- US Chase Manhattan Bank USA
					$aIINList[272]=511211 ;- US Chase Manhattan Bank USA
					$aIINList[273]=511212 ;- US Chase Manhattan Bank USA
					$aIINList[274]=511213 ;- US Chase Manhattan Bank USA
					$aIINList[275]=511214 ;- US Chase Manhattan Bank USA
					$aIINList[276]=511215 ;- US Chase Manhattan Bank USA
					$aIINList[277]=511216 ;- US Chase Manhattan Bank USA
					$aIINList[278]=511217 ;- US Chase Manhattan Bank USA
					$aIINList[279]=511218 ;- US Chase Manhattan Bank USA
					$aIINList[280]=511219 ;- US Chase Manhattan Bank USA
					$aIINList[281]=511220 ;- US Chase Manhattan Bank USA
					$aIINList[282]=511221 ;- US Chase Manhattan Bank USA
					$aIINList[283]=511222 ;- US Chase Manhattan Bank USA
					$aIINList[284]=511224 ;- US Chase Manhattan Bank USA
					$aIINList[285]=511227 ;- US Chase Manhattan Bank USA
					$aIINList[286]=511228 ;- US Chase Manhattan Bank USA
					$aIINList[287]=511230 ;- US Chase Manhattan Bank USA
					$aIINList[288]=511231 ;- US Chase Manhattan Bank USA
					$aIINList[289]=511232 ;- US Chase Manhattan Bank USA
					$aIINList[290]=511233 ;- US Chase Manhattan Bank USA
					$aIINList[291]=511234 ;- US Chase Manhattan Bank USA
					$aIINList[292]=511235 ;- US Chase Manhattan Bank USA
					$aIINList[293]=511239 ;- US Chase Manhattan Bank USA
					$aIINList[294]=511242 ;- US Chase Manhattan Bank USA
					$aIINList[295]=511243 ;- US Chase Manhattan Bank USA
					$aIINList[296]=511244 ;- US Chase Manhattan Bank USA
					$aIINList[297]=511261 ;- US Chase Manhattan Bank USA
					$aIINList[298]=511262 ;- US Chase Manhattan Bank USA
					$aIINList[299]=511263 ;- US Chase Manhattan Bank USA
					$aIINList[300]=511264 ;- US Chase Manhattan Bank USA
					$aIINList[301]=511265 ;- US Chase Manhattan Bank USA
					$aIINList[302]=511266 ;- US Chase Manhattan Bank USA
					$aIINList[303]=511267 ;- US Chase Manhattan Bank USA
					$aIINList[304]=511268 ;- US Chase Manhattan Bank USA
					$aIINList[305]=511273 ;- US Chase Manhattan Bank USA
					$aIINList[306]=511274 ;- US Chase Manhattan Bank USA
					$aIINList[307]=511275 ;- US Chase Manhattan Bank USA
					$aIINList[308]=511276 ;- US Chase Manhattan Bank USA
					$aIINList[309]=511277 ;- US Chase Manhattan Bank USA
					$aIINList[310]=511278 ;- US Chase Manhattan Bank USA
					$aIINList[311]=511279 ;- US Chase Manhattan Bank USA
					$aIINList[312]=511281 ;- US Chase Manhattan Bank USA
					$aIINList[313]=511282 ;- US Chase Manhattan Bank USA
					$aIINList[314]=511283 ;- US Chase Manhattan Bank USA
					$aIINList[315]=511284 ;- US Chase Manhattan Bank USA
					$aIINList[316]=511288 ;- US Chase Manhattan Bank USA
					$aIINList[317]=511293 ;- US Chase Manhattan Bank USA
					$aIINList[318]=511294 ;- US Chase Manhattan Bank USA
					$aIINList[319]=511296 ;- US Chase Manhattan Bank USA
					$aIINList[320]=511298 ;- US Chase Manhattan Bank USA
					$aIINList[321]=511300 ;- US Chase Manhattan Bank USA
					$aIINList[322]=511301 ;- US Chase Manhattan Bank USA
					$aIINList[323]=511302 ;- US Chase Manhattan Bank USA
					$aIINList[324]=511303 ;- US Chase Manhattan Bank USA
					$aIINList[325]=511304 ;- US Chase Manhattan Bank USA
					$aIINList[326]=511305 ;- US Chase Manhattan Bank USA
					$aIINList[327]=511306 ;- US Chase Manhattan Bank USA
					$aIINList[328]=511307 ;- US Chase Manhattan Bank USA
					$aIINList[329]=511308 ;- US Chase Manhattan Bank USA
					$aIINList[330]=511309 ;- US Chase Manhattan Bank USA
					$aIINList[331]=511310 ;- US Chase Manhattan Bank USA
					$aIINList[332]=511311 ;- US Chase Manhattan Bank USA
					$aIINList[333]=511312 ;- US Chase Manhattan Bank USA
					$aIINList[334]=511313 ;- US Chase Manhattan Bank USA
					$aIINList[335]=511314 ;- US Chase Manhattan Bank USA
					$aIINList[336]=511315 ;- US Chase Manhattan Bank USA
					$aIINList[337]=511316 ;- US Chase Manhattan Bank USA
					$aIINList[338]=511317 ;- US Chase Manhattan Bank USA
					$aIINList[339]=511318 ;- US Chase Manhattan Bank USA
					$aIINList[340]=511319 ;- US Chase Manhattan Bank USA
					$aIINList[341]=511320 ;- US Chase Manhattan Bank USA
					$aIINList[342]=511321 ;- US Chase Manhattan Bank USA
					$aIINList[343]=511322 ;- US Chase Manhattan Bank USA
					$aIINList[344]=511323 ;- US Chase Manhattan Bank USA
					$aIINList[345]=511324 ;- US Chase Manhattan Bank USA
					$aIINList[346]=511325 ;- US Chase Manhattan Bank USA
					$aIINList[347]=511326 ;- US Chase Manhattan Bank USA
					$aIINList[348]=511327 ;- US Chase Manhattan Bank USA
					$aIINList[349]=511328 ;- US Chase Manhattan Bank USA
					$aIINList[350]=511329 ;- US Chase Manhattan Bank USA
					$aIINList[351]=511330 ;- US Chase Manhattan Bank USA
					$aIINList[352]=511331 ;- US Chase Manhattan Bank USA
					$aIINList[353]=511332 ;- US Chase Manhattan Bank USA
					$aIINList[354]=511333 ;- US Chase Manhattan Bank USA
					$aIINList[355]=511334 ;- US Chase Manhattan Bank USA
					$aIINList[356]=511335 ;- US Chase Manhattan Bank USA
					$aIINList[357]=511336 ;- US Chase Manhattan Bank USA
					$aIINList[358]=511337 ;- US Chase Manhattan Bank USA
					$aIINList[359]=511338 ;- US Chase Manhattan Bank USA
					$aIINList[360]=511339 ;- US Chase Manhattan Bank USA
					$aIINList[361]=511340 ;- US Chase Manhattan Bank USA
					$aIINList[362]=511341 ;- US Chase Manhattan Bank USA
					$aIINList[363]=511342 ;- US Chase Manhattan Bank USA
					$aIINList[364]=511343 ;- US Chase Manhattan Bank USA
					$aIINList[365]=511344 ;- US Chase Manhattan Bank USA
					$aIINList[366]=511345 ;- US Chase Manhattan Bank USA
					$aIINList[367]=511346 ;- US Chase Manhattan Bank USA
					$aIINList[368]=511347 ;- US Chase Manhattan Bank USA
					$aIINList[369]=511348 ;- US Chase Manhattan Bank USA
					$aIINList[370]=511349 ;- US Chase Manhattan Bank USA
					$aIINList[371]=511350 ;- US Chase Manhattan Bank USA
					$aIINList[372]=511351 ;- US Chase Manhattan Bank USA
					$aIINList[373]=511352 ;- US Chase Manhattan Bank USA
					$aIINList[374]=511353 ;- US Chase Manhattan Bank USA
					$aIINList[375]=511354 ;- US Chase Manhattan Bank USA
					$aIINList[376]=511355 ;- US Chase Manhattan Bank USA
					$aIINList[377]=511356 ;- US Chase Manhattan Bank USA
					$aIINList[378]=511357 ;- US Chase Manhattan Bank USA
					$aIINList[379]=511358 ;- US Chase Manhattan Bank USA
					$aIINList[380]=511359 ;- US Chase Manhattan Bank USA
					$aIINList[381]=511360 ;- US Chase Manhattan Bank USA
					$aIINList[382]=511361 ;- US Chase Manhattan Bank USA
					$aIINList[383]=511362 ;- US Chase Manhattan Bank USA
					$aIINList[384]=511363 ;- US Chase Manhattan Bank USA
					$aIINList[385]=511364 ;- US Chase Manhattan Bank USA
					$aIINList[386]=511365 ;- US Chase Manhattan Bank USA
					$aIINList[387]=511366 ;- US Chase Manhattan Bank USA
					$aIINList[388]=511367 ;- US Chase Manhattan Bank USA
					$aIINList[389]=511368 ;- US Chase Manhattan Bank USA
					$aIINList[390]=511369 ;- US Chase Manhattan Bank USA
					$aIINList[391]=511370 ;- US Chase Manhattan Bank USA
					$aIINList[392]=511371 ;- US Chase Manhattan Bank USA
					$aIINList[393]=511372 ;- US Chase Manhattan Bank USA
					$aIINList[394]=511373 ;- US Chase Manhattan Bank USA
					$aIINList[395]=511374 ;- US Chase Manhattan Bank USA
					$aIINList[396]=511375 ;- US Chase Manhattan Bank USA
					$aIINList[397]=511376 ;- US Chase Manhattan Bank USA
					$aIINList[398]=511377 ;- US Chase Manhattan Bank USA
					$aIINList[399]=511378 ;- US Chase Manhattan Bank USA
					$aIINList[400]=511379 ;- US Chase Manhattan Bank USA
					$aIINList[401]=511380 ;- US Chase Manhattan Bank USA
					$aIINList[402]=511381 ;- US Chase Manhattan Bank USA
					$aIINList[403]=511382 ;- US Chase Manhattan Bank USA
					$aIINList[404]=511383 ;- US Chase Manhattan Bank USA
					$aIINList[405]=511384 ;- US Chase Manhattan Bank USA
					$aIINList[406]=511385 ;- US Chase Manhattan Bank USA
					$aIINList[407]=511386 ;- US Chase Manhattan Bank USA
					$aIINList[408]=511387 ;- US Chase Manhattan Bank USA
					$aIINList[409]=511388 ;- US Chase Manhattan Bank USA
					$aIINList[410]=511389 ;- US Chase Manhattan Bank USA
					$aIINList[411]=511390 ;- US Chase Manhattan Bank USA
					$aIINList[412]=511391 ;- US Chase Manhattan Bank USA
					$aIINList[413]=511392 ;- US Chase Manhattan Bank USA
					$aIINList[414]=511393 ;- US Chase Manhattan Bank USA
					$aIINList[415]=511394 ;- US Chase Manhattan Bank USA
					$aIINList[416]=511395 ;- US Chase Manhattan Bank USA
					$aIINList[417]=511396 ;- US Chase Manhattan Bank USA
					$aIINList[418]=511397 ;- US Chase Manhattan Bank USA
					$aIINList[419]=511398 ;- US Chase Manhattan Bank USA
					$aIINList[420]=511399 ;- US Chase Manhattan Bank USA
					$aIINList[421]=511400 ;- US Chase Manhattan Bank USA
					$aIINList[422]=511401 ;- US Chase Manhattan Bank USA
					$aIINList[423]=511402 ;- US Chase Manhattan Bank USA
					$aIINList[424]=511403 ;- US Chase Manhattan Bank USA
					$aIINList[425]=511404 ;- US Chase Manhattan Bank USA
					$aIINList[426]=511405 ;- US Chase Manhattan Bank USA
					$aIINList[427]=511406 ;- US Chase Manhattan Bank USA
					$aIINList[428]=511407 ;- US Chase Manhattan Bank USA
					$aIINList[429]=511408 ;- US Chase Manhattan Bank USA
					$aIINList[430]=511409 ;- US Chase Manhattan Bank USA
					$aIINList[431]=511410 ;- US Chase Manhattan Bank USA
					$aIINList[432]=511411 ;- US Chase Manhattan Bank USA
					$aIINList[433]=511412 ;- US Chase Manhattan Bank USA
					$aIINList[434]=511413 ;- US Chase Manhattan Bank USA
					$aIINList[435]=511414 ;- US Chase Manhattan Bank USA
					$aIINList[436]=511415 ;- US Chase Manhattan Bank USA
					$aIINList[437]=511416 ;- US Chase Manhattan Bank USA
					$aIINList[438]=511417 ;- US Chase Manhattan Bank USA
					$aIINList[439]=511418 ;- US Chase Manhattan Bank USA
					$aIINList[440]=511419 ;- US Chase Manhattan Bank USA
					$aIINList[441]=511420 ;- US Chase Manhattan Bank USA
					$aIINList[442]=511421 ;- US Chase Manhattan Bank USA
					$aIINList[443]=511422 ;- US Chase Manhattan Bank USA
					$aIINList[444]=511423 ;- US Chase Manhattan Bank USA
					$aIINList[445]=511424 ;- US Chase Manhattan Bank USA
					$aIINList[446]=511425 ;- US Chase Manhattan Bank USA
					$aIINList[447]=511426 ;- US Chase Manhattan Bank USA
					$aIINList[448]=511427 ;- US Chase Manhattan Bank USA
					$aIINList[449]=511428 ;- US Chase Manhattan Bank USA
					$aIINList[450]=511429 ;- US Chase Manhattan Bank USA
					$aIINList[451]=511430 ;- US Chase Manhattan Bank USA
					$aIINList[452]=511431 ;- US Chase Manhattan Bank USA
					$aIINList[453]=511432 ;- US Chase Manhattan Bank USA
					$aIINList[454]=511433 ;- US Chase Manhattan Bank USA
					$aIINList[455]=511434 ;- US Chase Manhattan Bank USA
					$aIINList[456]=511435 ;- US Chase Manhattan Bank USA
					$aIINList[457]=511436 ;- US Chase Manhattan Bank USA
					$aIINList[458]=511437 ;- US Chase Manhattan Bank USA
					$aIINList[459]=511438 ;- US Chase Manhattan Bank USA
					$aIINList[460]=511439 ;- US Chase Manhattan Bank USA
					$aIINList[461]=511440 ;- US Chase Manhattan Bank USA
					$aIINList[462]=511441 ;- US Chase Manhattan Bank USA
					$aIINList[463]=511442 ;- US Chase Manhattan Bank USA
					$aIINList[464]=511443 ;- US Chase Manhattan Bank USA
					$aIINList[465]=511444 ;- US Chase Manhattan Bank USA
					$aIINList[466]=511445 ;- US Chase Manhattan Bank USA
					$aIINList[467]=511446 ;- US Chase Manhattan Bank USA
					$aIINList[468]=511447 ;- US Chase Manhattan Bank USA
					$aIINList[469]=511448 ;- US Chase Manhattan Bank USA
					$aIINList[470]=511449 ;- US Chase Manhattan Bank USA
					$aIINList[471]=511450 ;- US Chase Manhattan Bank USA
					$aIINList[472]=511451 ;- US Chase Manhattan Bank USA
					$aIINList[473]=511452 ;- US Chase Manhattan Bank USA
					$aIINList[474]=511453 ;- US Chase Manhattan Bank USA
					$aIINList[475]=511454 ;- US Chase Manhattan Bank USA
					$aIINList[476]=511455 ;- US Chase Manhattan Bank USA
					$aIINList[477]=511456 ;- US Chase Manhattan Bank USA
					$aIINList[478]=511457 ;- US Chase Manhattan Bank USA
					$aIINList[479]=511458 ;- US Chase Manhattan Bank USA
					$aIINList[480]=511459 ;- US Chase Manhattan Bank USA
					$aIINList[481]=511460 ;- US Chase Manhattan Bank USA
					$aIINList[482]=511461 ;- US Chase Manhattan Bank USA
					$aIINList[483]=511462 ;- US Chase Manhattan Bank USA
					$aIINList[484]=511463 ;- US Chase Manhattan Bank USA
					$aIINList[485]=511464 ;- US Chase Manhattan Bank USA
					$aIINList[486]=511465 ;- US Chase Manhattan Bank USA
					$aIINList[487]=511466 ;- US Chase Manhattan Bank USA
					$aIINList[488]=511467 ;- US Chase Manhattan Bank USA
					$aIINList[489]=511468 ;- US Chase Manhattan Bank USA
					$aIINList[490]=511469 ;- US Chase Manhattan Bank USA
					$aIINList[491]=511470 ;- US Chase Manhattan Bank USA
					$aIINList[492]=511471 ;- US Chase Manhattan Bank USA
					$aIINList[493]=511472 ;- US Chase Manhattan Bank USA
					$aIINList[494]=511473 ;- US Chase Manhattan Bank USA
					$aIINList[495]=511474 ;- US Chase Manhattan Bank USA
					$aIINList[496]=511475 ;- US Chase Manhattan Bank USA
					$aIINList[497]=511476 ;- US Chase Manhattan Bank USA
					$aIINList[498]=511477 ;- US Chase Manhattan Bank USA
					$aIINList[499]=511478 ;- US Chase Manhattan Bank USA
					$aIINList[500]=511479 ;- US Chase Manhattan Bank USA
					$aIINList[501]=511480 ;- US Chase Manhattan Bank USA
					$aIINList[502]=511481 ;- US Chase Manhattan Bank USA
					$aIINList[503]=511482 ;- US Chase Manhattan Bank USA
					$aIINList[504]=511483 ;- US Chase Manhattan Bank USA
					$aIINList[505]=511484 ;- US Chase Manhattan Bank USA
					$aIINList[506]=511485 ;- US Chase Manhattan Bank USA
					$aIINList[507]=511486 ;- US Chase Manhattan Bank USA
					$aIINList[508]=511487 ;- US Chase Manhattan Bank USA
					$aIINList[509]=511488 ;- US Chase Manhattan Bank USA
					$aIINList[510]=511489 ;- US Chase Manhattan Bank USA
					$aIINList[511]=511490 ;- US Chase Manhattan Bank USA
					$aIINList[512]=511491 ;- US Chase Manhattan Bank USA
					$aIINList[513]=511492 ;- US Chase Manhattan Bank USA
					$aIINList[514]=511493 ;- US Chase Manhattan Bank USA
					$aIINList[515]=511494 ;- US Chase Manhattan Bank USA
					$aIINList[516]=511495 ;- US Chase Manhattan Bank USA
					$aIINList[517]=511496 ;- US Chase Manhattan Bank USA
					$aIINList[518]=511497 ;- US Chase Manhattan Bank USA
					$aIINList[519]=511498 ;- US Chase Manhattan Bank USA
					$aIINList[520]=511499 ;- US Chase Manhattan Bank USA
					$aIINList[521]=511500 ;- US Chase Manhattan Bank USA
					$aIINList[522]=511501 ;- US Chase Manhattan Bank USA
					$aIINList[523]=511502 ;- US Chase Manhattan Bank USA
					$aIINList[524]=511503 ;- US Chase Manhattan Bank USA
					$aIINList[525]=511504 ;- US Chase Manhattan Bank USA
					$aIINList[526]=511505 ;- US Chase Manhattan Bank USA
					$aIINList[527]=511506 ;- US Chase Manhattan Bank USA
					$aIINList[528]=511507 ;- US Chase Manhattan Bank USA
					$aIINList[529]=511508 ;- US Chase Manhattan Bank USA
					$aIINList[530]=511509 ;- US Chase Manhattan Bank USA
					$aIINList[531]=511510 ;- US Chase Manhattan Bank USA
					$aIINList[532]=511514 ;- US Chase Manhattan Bank USA
					$aIINList[533]=511519 ;- US Chase Manhattan Bank USA
					$aIINList[534]=511520 ;- US Chase Manhattan Bank USA
					$aIINList[535]=511521 ;- US Chase Manhattan Bank USA
					$aIINList[536]=511522 ;- US Chase Manhattan Bank USA
					$aIINList[537]=511523 ;- US Chase Manhattan Bank USA
					$aIINList[538]=511524 ;- US Chase Manhattan Bank USA
					$aIINList[539]=511528 ;- US Chase Manhattan Bank USA
					$aIINList[540]=511530 ;- US Chase Manhattan Bank USA
					$aIINList[541]=511532 ;- US Chase Manhattan Bank USA
					$aIINList[542]=511533 ;- US Chase Manhattan Bank USA
					$aIINList[543]=511534 ;- US Chase Manhattan Bank USA
					$aIINList[544]=511536 ;- US Chase Manhattan Bank USA
					$aIINList[545]=511538 ;- US Chase Manhattan Bank USA
					$aIINList[546]=511539 ;- US Chase Manhattan Bank USA
					$aIINList[547]=511540 ;- US Chase Manhattan Bank USA
					$aIINList[548]=511543 ;- US Chase Manhattan Bank USA
					$aIINList[549]=511544 ;- US Chase Manhattan Bank USA
					$aIINList[550]=511548 ;- US Chase Manhattan Bank USA
					$aIINList[551]=511553 ;- US Chase Manhattan Bank USA
					$aIINList[552]=511555 ;- US Chase Manhattan Bank USA
					$aIINList[553]=511559 ;- US Chase Manhattan Bank USA
					$aIINList[554]=511562 ;- US Chase Manhattan Bank USA
					$aIINList[555]=511563 ;- US Chase Manhattan Bank USA
					$aIINList[556]=511564 ;- US Chase Manhattan Bank USA
					$aIINList[557]=511566 ;- US Chase Manhattan Bank USA
					$aIINList[558]=511567 ;- US Chase Manhattan Bank USA
					$aIINList[559]=511568 ;- US Chase Manhattan Bank USA
					$aIINList[560]=511572 ;- US Chase Manhattan Bank USA
					$aIINList[561]=511573 ;- US Chase Manhattan Bank USA
					$aIINList[562]=511574 ;- US Chase Manhattan Bank USA
					$aIINList[563]=511578 ;- US Chase Manhattan Bank USA
					$aIINList[564]=511579 ;- US Chase Manhattan Bank USA
					$aIINList[565]=511585 ;- US Chase Manhattan Bank USA
					$aIINList[566]=511586 ;- US Chase Manhattan Bank USA
					$aIINList[567]=511590 ;- US Chase Manhattan Bank USA
					$aIINList[568]=511592 ;- US Chase Manhattan Bank USA
					$aIINList[569]=511593 ;- US Chase Manhattan Bank USA
					$aIINList[570]=511594 ;- US Chase Manhattan Bank USA
					$aIINList[571]=511595 ;- US Chase Manhattan Bank USA
					$aIINList[572]=511600 ;- US Chase Manhattan Bank USA
					$aIINList[573]=511601 ;- US Chase Manhattan Bank USA
					$aIINList[574]=511602 ;- US Chase Manhattan Bank USA
					$aIINList[575]=511603 ;- US Chase Manhattan Bank USA
					$aIINList[576]=511604 ;- US Chase Manhattan Bank USA
					$aIINList[577]=511605 ;- US Chase Manhattan Bank USA
					$aIINList[578]=511607 ;- US Chase Manhattan Bank USA
					$aIINList[579]=511608 ;- US Chase Manhattan Bank USA
					$aIINList[580]=511609 ;- US Chase Manhattan Bank USA
					$aIINList[581]=511610 ;- US Chase Manhattan Bank USA
					$aIINList[582]=511614 ;- US Chase Manhattan Bank USA
					$aIINList[583]=511620 ;- US Chase Manhattan Bank USA
					$aIINList[584]=511622 ;- US Chase Manhattan Bank USA
					$aIINList[585]=511642 ;- US Chase Manhattan Bank USA
					$aIINList[586]=511647 ;- US Chase Manhattan Bank USA
					$aIINList[587]=511650 ;- US Chase Manhattan Bank USA
					$aIINList[588]=511654 ;- US Chase Manhattan Bank USA
					$aIINList[589]=511656 ;- US Chase Manhattan Bank USA
					$aIINList[590]=511661 ;- US Chase Manhattan Bank USA
					$aIINList[591]=511664 ;- US Chase Manhattan Bank USA
					$aIINList[592]=511665 ;- US Chase Manhattan Bank USA
					$aIINList[593]=511667 ;- US Chase Manhattan Bank USA
					$aIINList[594]=511668 ;- US Chase Manhattan Bank USA
					$aIINList[595]=511669 ;- US Chase Manhattan Bank USA
					$aIINList[596]=511671 ;- US Chase Manhattan Bank USA
					$aIINList[597]=511673 ;- US Chase Manhattan Bank USA
					$aIINList[598]=511674 ;- US Chase Manhattan Bank USA
					$aIINList[599]=511676 ;- US Chase Manhattan Bank USA
					$aIINList[600]=511677 ;- US Chase Manhattan Bank USA
					$aIINList[601]=511678 ;- US Chase Manhattan Bank USA
					$aIINList[602]=511679 ;- US Chase Manhattan Bank USA
					$aIINList[603]=511680 ;- US Chase Manhattan Bank USA
					$aIINList[604]=511681 ;- US Chase Manhattan Bank USA
					$aIINList[605]=511682 ;- US Chase Manhattan Bank USA
					$aIINList[606]=511683 ;- US Chase Manhattan Bank USA
					$aIINList[607]=511684 ;- US Chase Manhattan Bank USA
					$aIINList[608]=511685 ;- US Chase Manhattan Bank USA
					$aIINList[609]=511686 ;- US Chase Manhattan Bank USA
					$aIINList[610]=511688 ;- US Chase Manhattan Bank USA
					$aIINList[611]=511689 ;- US Chase Manhattan Bank USA
					$aIINList[612]=511690 ;- US Chase Manhattan Bank USA
					$aIINList[613]=511691 ;- US Chase Manhattan Bank USA
					$aIINList[614]=511692 ;- US Chase Manhattan Bank USA
					$aIINList[615]=511693 ;- US Chase Manhattan Bank USA
					$aIINList[616]=511694 ;- US Chase Manhattan Bank USA
					$aIINList[617]=511695 ;- US Chase Manhattan Bank USA
					$aIINList[618]=511696 ;- US Chase Manhattan Bank USA
					$aIINList[619]=511698 ;- US Chase Manhattan Bank USA
					$aIINList[620]=511699 ;- US Chase Manhattan Bank USA
					$aIINList[621]=511712 ;- US Chase Manhattan Bank USA
					$aIINList[622]=511716 ;- US Chase Manhattan Bank USA
					$aIINList[623]=511721 ;- US Chase Manhattan Bank USA
					$aIINList[624]=511726 ;- US Chase Manhattan Bank USA
					$aIINList[625]=511730 ;- US Chase Manhattan Bank USA
					$aIINList[626]=511732 ;- US Chase Manhattan Bank USA
					$aIINList[627]=511733 ;- US Chase Manhattan Bank USA
					$aIINList[628]=511734 ;- US Chase Manhattan Bank USA
					$aIINList[629]=511740 ;- US Chase Manhattan Bank USA
					$aIINList[630]=511742 ;- US Chase Manhattan Bank USA
					$aIINList[631]=511743 ;- US Chase Manhattan Bank USA
					$aIINList[632]=511744 ;- US Chase Manhattan Bank USA
					$aIINList[633]=511746 ;- US Chase Manhattan Bank USA
					$aIINList[634]=511747 ;- US Chase Manhattan Bank USA
					$aIINList[635]=511748 ;- US Chase Manhattan Bank USA
					$aIINList[636]=511749 ;- US Chase Manhattan Bank USA
					$aIINList[637]=511756 ;- US Chase Manhattan Bank USA
					$aIINList[638]=511760 ;- US Chase Manhattan Bank USA
					$aIINList[639]=511762 ;- US Chase Manhattan Bank USA
					$aIINList[640]=511763 ;- US Chase Manhattan Bank USA
					$aIINList[641]=511765 ;- US Chase Manhattan Bank USA
					$aIINList[642]=511766 ;- US Chase Manhattan Bank USA
					$aIINList[643]=511767 ;- US Chase Manhattan Bank USA
					$aIINList[644]=511770 ;- US Chase Manhattan Bank USA
					$aIINList[645]=511771 ;- US Chase Manhattan Bank USA
					$aIINList[646]=511774 ;- US Chase Manhattan Bank USA
					$aIINList[647]=511775 ;- US Chase Manhattan Bank USA
					$aIINList[648]=511778 ;- US Chase Manhattan Bank USA
					$aIINList[649]=511779 ;- US Chase Manhattan Bank USA
					$aIINList[650]=511780 ;- US Chase Manhattan Bank USA
					$aIINList[651]=511781 ;- US Chase Manhattan Bank USA
					$aIINList[652]=511782 ;- US Chase Manhattan Bank USA
					$aIINList[653]=511783 ;- US Chase Manhattan Bank USA
					$aIINList[654]=511784 ;- US Chase Manhattan Bank USA
					$aIINList[655]=511785 ;- US Chase Manhattan Bank USA
					$aIINList[656]=511788 ;- US Chase Manhattan Bank USA
					$aIINList[657]=511790 ;- US Chase Manhattan Bank USA
					$aIINList[658]=511791 ;- US Chase Manhattan Bank USA
					$aIINList[659]=511793 ;- US Chase Manhattan Bank USA
					$aIINList[660]=511794 ;- US Chase Manhattan Bank USA
					$aIINList[661]=511796 ;- US Chase Manhattan Bank USA
					$aIINList[662]=511799 ;- US Chase Manhattan Bank USA
					$aIINList[663]=511800 ;- US Chase Manhattan Bank USA
					$aIINList[664]=511807 ;- US Chase Manhattan Bank USA
					$aIINList[665]=511808 ;- US Chase Manhattan Bank USA
					$aIINList[666]=511809 ;- US Chase Manhattan Bank USA
					$aIINList[667]=511810 ;- US PayPal PayPal Secure Credit Card
					$aIINList[668]=511812 ;- US Chase Manhattan Bank USA
					$aIINList[669]=511813 ;- US Chase Manhattan Bank USA
					$aIINList[670]=511814 ;- US Chase Manhattan Bank USA
					$aIINList[671]=511815 ;- US Chase Manhattan Bank USA
					$aIINList[672]=511816 ;- US Chase Manhattan Bank USA
					$aIINList[673]=511817 ;- US Chase Manhattan Bank USA
					$aIINList[674]=511818 ;- US Chase Manhattan Bank USA
					$aIINList[675]=511819 ;- US Chase Manhattan Bank USA
					$aIINList[676]=511820 ;- US Chase Manhattan Bank USA
					$aIINList[677]=511821 ;- US Chase Manhattan Bank USA
					$aIINList[678]=511822 ;- US Chase Manhattan Bank USA
					$aIINList[679]=511823 ;- US Chase Manhattan Bank USA
					$aIINList[680]=511824 ;- US Chase Manhattan Bank USA
					$aIINList[681]=511825 ;- US Chase Manhattan Bank USA
					$aIINList[682]=511826 ;- US Chase Manhattan Bank USA
					$aIINList[683]=511827 ;- US Chase Manhattan Bank USA
					$aIINList[684]=511828 ;- US Chase Manhattan Bank USA
					$aIINList[685]=511829 ;- US Chase Manhattan Bank USA
					$aIINList[686]=511830 ;- US Chase Manhattan Bank USA
					$aIINList[687]=511831 ;- US Chase Manhattan Bank USA
					$aIINList[688]=511832 ;- US Chase Manhattan Bank USA
					$aIINList[689]=511833 ;- US Chase Manhattan Bank USA
					$aIINList[690]=511834 ;- US Chase Manhattan Bank USA
					$aIINList[691]=511836 ;- US Chase Manhattan Bank USA
					$aIINList[692]=511837 ;- US Chase Manhattan Bank USA
					$aIINList[693]=511838 ;- US Chase Manhattan Bank USA
					$aIINList[694]=511839 ;- US Chase Manhattan Bank USA
					$aIINList[695]=511840 ;- US Chase Manhattan Bank USA
					$aIINList[696]=511841 ;- US Chase Manhattan Bank USA
					$aIINList[697]=511842 ;- US Chase Manhattan Bank USA
					$aIINList[698]=511843 ;- US Chase Manhattan Bank USA
					$aIINList[699]=511844 ;- US Chase Manhattan Bank USA
					$aIINList[700]=511847 ;- US Chase Manhattan Bank USA
					$aIINList[701]=511848 ;- US Chase Manhattan Bank USA
					$aIINList[702]=511849 ;- US Chase Manhattan Bank USA
					$aIINList[703]=511850 ;- US Chase Manhattan Bank USA
					$aIINList[704]=511851 ;- US Chase Manhattan Bank USA
					$aIINList[705]=511852 ;- US Chase Manhattan Bank USA
					$aIINList[706]=511853 ;- US Chase Manhattan Bank USA
					$aIINList[707]=511856 ;- US Chase Manhattan Bank USA
					$aIINList[708]=511857 ;- US Chase Manhattan Bank USA
					$aIINList[709]=511859 ;- US Chase Manhattan Bank USA
					$aIINList[710]=511860 ;- US Chase Manhattan Bank USA
					$aIINList[711]=511861 ;- US Chase Manhattan Bank USA
					$aIINList[712]=511864 ;- US Chase Manhattan Bank USA
					$aIINList[713]=511865 ;- US Chase Manhattan Bank USA
					$aIINList[714]=511866 ;- US Chase Manhattan Bank USA
					$aIINList[715]=511867 ;- US Chase Manhattan Bank USA
					$aIINList[716]=511869 ;- US Chase Manhattan Bank USA
					$aIINList[717]=511870 ;- US Chase Manhattan Bank USA
					$aIINList[718]=511871 ;- US Chase Manhattan Bank USA
					$aIINList[719]=511872 ;- US Chase Manhattan Bank USA
					$aIINList[720]=511874 ;- US Chase Manhattan Bank USA
					$aIINList[721]=511875 ;- US Chase Manhattan Bank USA
					$aIINList[722]=511876 ;- US Chase Manhattan Bank USA
					$aIINList[723]=511878 ;- US Chase Manhattan Bank USA
					$aIINList[724]=511879 ;- US Chase Manhattan Bank USA
					$aIINList[725]=511880 ;- US Chase Manhattan Bank USA
					$aIINList[726]=511881 ;- US Chase Manhattan Bank USA
					$aIINList[727]=511882 ;- US Chase Manhattan Bank USA
					$aIINList[728]=511885 ;- US Chase Manhattan Bank USA
					$aIINList[729]=511887 ;- US Chase Manhattan Bank USA
					$aIINList[730]=511888 ;- US Chase Manhattan Bank USA
					$aIINList[731]=511889 ;- US Chase Manhattan Bank USA
					$aIINList[732]=511890 ;- US Chase Manhattan Bank USA
					$aIINList[733]=511891 ;- US Chase Manhattan Bank USA
					$aIINList[734]=511892 ;- US Chase Manhattan Bank USA
					$aIINList[735]=511893 ;- US Chase Manhattan Bank USA
					$aIINList[736]=511894 ;- US Chase Manhattan Bank USA
					$aIINList[737]=511895 ;- US Chase Manhattan Bank USA
					$aIINList[738]=511896 ;- US Chase Manhattan Bank USA
					$aIINList[739]=511897 ;- US Chase Manhattan Bank USA
					$aIINList[740]=511898 ;- US Chase Manhattan Bank USA
					$aIINList[741]=511899 ;- US Chase Manhattan Bank USA
					$aIINList[742]=511900 ;- US Chase Manhattan Bank USA
					$aIINList[743]=511901 ;- US Chase Manhattan Bank USA
					$aIINList[744]=511902 ;- US Chase Manhattan Bank USA
					$aIINList[745]=511904 ;- US Chase Manhattan Bank USA
					$aIINList[746]=511910 ;- US Chase Manhattan Bank USA
					$aIINList[747]=511911 ;- US Chase Manhattan Bank USA
					$aIINList[748]=511913 ;- US Chase Manhattan Bank USA
					$aIINList[749]=511916 ;- US Chase Manhattan Bank USA
					$aIINList[750]=511917 ;- US Chase Manhattan Bank USA
					$aIINList[751]=511920 ;- US Chase Manhattan Bank USA
					$aIINList[752]=511921 ;- US Chase Manhattan Bank USA
					$aIINList[753]=511932 ;- US Chase Manhattan Bank USA
					$aIINList[754]=511934 ;- US Chase Manhattan Bank USA
					$aIINList[755]=511937 ;- US Chase Manhattan Bank USA
					$aIINList[756]=511938 ;- US Chase Manhattan Bank USA
					$aIINList[757]=511939 ;- US Chase Manhattan Bank USA
					$aIINList[758]=511942 ;- US Chase Manhattan Bank USA
					$aIINList[759]=511953 ;- US Chase Manhattan Bank USA
					$aIINList[760]=511958 ;- US Chase Manhattan Bank USA
					$aIINList[761]=511964 ;- US Chase Manhattan Bank USA
					$aIINList[762]=511967 ;- US Chase Manhattan Bank USA
					$aIINList[763]=511972 ;- US Chase Manhattan Bank USA
					$aIINList[764]=511974 ;- US Chase Manhattan Bank USA
					$aIINList[765]=511981 ;- US Chase Manhattan Bank USA
					$aIINList[766]=511987 ;- US Chase Manhattan Bank USA
					$aIINList[767]=511988 ;- US Chase Manhattan Bank USA
					$aIINList[768]=511995 ;- US Chase Manhattan Bank USA
					$aIINList[769]=511998 ;- US Chase Manhattan Bank USA
					$aIINList[770]=511999 ;- US Chase Manhattan Bank USA
					$aIINList[771]=512000 ;- US Western States BankCard Association
					$aIINList[772]=512005 ;- US Western States BankCard Association
					$aIINList[773]=512010 ;- US Western States BankCard Association
					$aIINList[774]=512012 ;- US Chase Manhattan Bank USA
					$aIINList[775]=512015 ;- US Western States BankCard Association
					$aIINList[776]=512022 ;- US Western States BankCard Association
					$aIINList[777]=512023 ;- JO International Card
					$aIINList[778]=512024 ;- US Western States BankCard Association
					$aIINList[779]=512105 ;- US Western States BankCard Association
					$aIINList[780]=512106 ;- US Sears National Bank Citi Sears MasterCard
					$aIINList[781]=512107 ;- US Sears National Bank Citi Sears MasterCard
					$aIINList[782]=512108 ;- US Sears National Bank Citi Sears MasterCard
					$aIINList[783]=512109 ;- CL Corp Banca
					$aIINList[784]=512110 ;- US Western States BankCard Association
					$aIINList[785]=512111 ;- US Western States BankCard Association
					$aIINList[786]=512127 ;- AU BankWest Business Debit MasterCard
					$aIINList[787]=512136 ;- US Western States BankCard Association
					$aIINList[788]=512207 ;- US Western States BankCard Association
					$aIINList[789]=512210 ;- US Western States BankCard Association
					$aIINList[790]=512211 ;- US Western States BankCard Association
					$aIINList[791]=512213 ;- US Western States BankCard Association
					$aIINList[792]=512221 ;- US Western States BankCard Association
					$aIINList[793]=512240 ;- US Western States BankCard Association
					$aIINList[794]=512244 ;- US Western States BankCard Association
					$aIINList[795]=512262 ;- US Western States BankCard Association
					$aIINList[796]=512265 ;- US Western States BankCard Association
					$aIINList[797]=512268 ;- US Western States BankCard Association
					$aIINList[798]=512277 ;- US Western States BankCard Association
					$aIINList[799]=512278 ;- US Western States BankCard Association
					$aIINList[800]=512281 ;- US Western States BankCard Association
					$aIINList[801]=512282 ;- US Western States BankCard Association
					$aIINList[802]=512283 ;- US Western States BankCard Association
					$aIINList[803]=512287 ;- US Western States BankCard Association
					$aIINList[804]=512288 ;- US Western States BankCard Association
					$aIINList[805]=512289 ;- US Western States BankCard Association
					$aIINList[806]=512290 ;- US Western States BankCard Association
					$aIINList[807]=512293 ;- US Western States BankCard Association
					$aIINList[808]=512295 ;- US Western States BankCard Association
					$aIINList[809]=512297 ;- US Western States BankCard Association
					$aIINList[810]=512344 ;- US Western States BankCard Association
					$aIINList[811]=512356 ;- US Western States BankCard Association
					$aIINList[812]=512369 ;- US Western States BankCard Association
					$aIINList[813]=512375 ;- US Western States BankCard Association
					$aIINList[814]=512387 ;- US Western States BankCard Association
					$aIINList[815]=512388 ;- US Western States BankCard Association
					$aIINList[816]=512390 ;- US Western States BankCard Association
					$aIINList[817]=512462 ;- Lotte Card MasterCard Gold Card
					$aIINList[818]=512500 ;- US Western States BankCard Association
					$aIINList[819]=512502 ;- US Western States BankCard Association
					$aIINList[820]=512503 ;- US Western States BankCard Association
					$aIINList[821]=512504 ;- US Western States BankCard Association
					$aIINList[822]=512505 ;- US Western States BankCard Association
					$aIINList[823]=512506 ;- US Western States BankCard Association
					$aIINList[824]=512507 ;- US Western States BankCard Association
					$aIINList[825]=512508 ;- US Western States BankCard Association
					$aIINList[826]=512509 ;- US Western States BankCard Association
					$aIINList[827]=512511 ;- US Western States BankCard Association
					$aIINList[828]=512512 ;- US Western States BankCard Association
					$aIINList[829]=512513 ;- US Western States BankCard Association
					$aIINList[830]=512514 ;- US Western States BankCard Association
					$aIINList[831]=512515 ;- US Western States BankCard Association
					$aIINList[832]=512516 ;- US Western States BankCard Association
					$aIINList[833]=512517 ;- US Western States BankCard Association
					$aIINList[834]=512518 ;- US Western States BankCard Association
					$aIINList[835]=512519 ;- US Western States BankCard Association
					$aIINList[836]=512520 ;- US Western States BankCard Association
					$aIINList[837]=512521 ;- US Western States BankCard Association
					$aIINList[838]=512522 ;- US Western States BankCard Association
					$aIINList[839]=512523 ;- US Western States BankCard Association
					$aIINList[840]=512524 ;- US Western States BankCard Association
					$aIINList[841]=512525 ;- US Western States BankCard Association
					$aIINList[842]=512526 ;- US Western States BankCard Association
					$aIINList[843]=512527 ;- US Western States BankCard Association
					$aIINList[844]=512528 ;- US Western States BankCard Association
					$aIINList[845]=512529 ;- US Western States BankCard Association
					$aIINList[846]=512530 ;- US Western States BankCard Association
					$aIINList[847]=512531 ;- US Western States BankCard Association
					$aIINList[848]=512532 ;- US Western States BankCard Association
					$aIINList[849]=512533 ;- US Western States BankCard Association
					$aIINList[850]=512534 ;- US Western States BankCard Association
					$aIINList[851]=512535 ;- US Western States BankCard Association
					$aIINList[852]=512536 ;- US Western States BankCard Association
					$aIINList[853]=512537 ;- US Western States BankCard Association
					$aIINList[854]=512538 ;- US Western States BankCard Association
					$aIINList[855]=512539 ;- US Western States BankCard Association
					$aIINList[856]=512540 ;- US Western States BankCard Association
					$aIINList[857]=512541 ;- US Western States BankCard Association
					$aIINList[858]=512542 ;- US Western States BankCard Association
					$aIINList[859]=512543 ;- US Western States BankCard Association
					$aIINList[860]=512544 ;- US Western States BankCard Association
					$aIINList[861]=512545 ;- US Western States BankCard Association
					$aIINList[862]=512546 ;- US Western States BankCard Association
					$aIINList[863]=512547 ;- US Western States BankCard Association
					$aIINList[864]=512548 ;- US Western States BankCard Association
					$aIINList[865]=512549 ;- US Western States BankCard Association
					$aIINList[866]=512550 ;- US Western States BankCard Association
					$aIINList[867]=512551 ;- ES Europay 6000
					$aIINList[868]=512552 ;- ES Europay 6000
					$aIINList[869]=512553 ;- ES Europay 6000
					$aIINList[870]=512554 ;- ES Europay 6000
					$aIINList[871]=512555 ;- ES Europay 6000
					$aIINList[872]=512568 ;- PL Citi Gold MasterCard Citi Poland
					$aIINList[873]=512569 ;- UK Lloyds TSB
					$aIINList[874]=512607 ;- Continental Finance MasterCard
					$aIINList[875]=512622 ;- IN SBI Tata Card Mastercard Credit Card
					$aIINList[876]=512687 ;- UK Sainsbury Sainsbury Credit Card
					$aIINList[877]=513011 ;- FR Europay France
					$aIINList[878]=513015 ;- FR Europay France
					$aIINList[879]=513016 ;- FR Europay France
					$aIINList[880]=513017 ;- FR Europay France
					$aIINList[881]=513018 ;- FR Europay France
					$aIINList[882]=513020 ;- FR Europay France
					$aIINList[883]=513021 ;- FR Europay France
					$aIINList[884]=513022 ;- FR Europay France
					$aIINList[885]=513023 ;- FR Europay France
					$aIINList[886]=513024 ;- FR Europay France
					$aIINList[887]=513025 ;- FR Europay France
					$aIINList[888]=513026 ;- FR Europay France
					$aIINList[889]=513027 ;- FR Europay France
					$aIINList[890]=513028 ;- FR Europay France
					$aIINList[891]=513029 ;- FR Europay France
					$aIINList[892]=513030 ;- FR Europay France
					$aIINList[893]=513031 ;- FR Europay France
					$aIINList[894]=513032 ;- FR Europay France
					$aIINList[895]=513033 ;- FR Europay France
					$aIINList[896]=513034 ;- FR Europay France
					$aIINList[897]=513035 ;- FR Europay France
					$aIINList[898]=513036 ;- FR Europay France
					$aIINList[899]=513037 ;- FR Europay France
					$aIINList[900]=513038 ;- FR Europay France
					$aIINList[901]=513100 ;- FR Europay France
					$aIINList[902]=513101 ;- FR Europay France Crédit Agricole Gold MasterCard Credit Card
					$aIINList[903]=513102 ;- FR Europay France
					$aIINList[904]=513103 ;- FR Europay France
					$aIINList[905]=513104 ;- FR Europay France
					$aIINList[906]=513105 ;- FR Europay France
					$aIINList[907]=513106 ;- FR Europay France
					$aIINList[908]=513107 ;- FR Europay France
					$aIINList[909]=513108 ;- FR Europay France
					$aIINList[910]=513109 ;- FR Europay France
					$aIINList[911]=513110 ;- FR Europay France
					$aIINList[912]=513111 ;- FR Europay France
					$aIINList[913]=513112 ;- FR Europay France
					$aIINList[914]=513113 ;- FR Europay France
					$aIINList[915]=513114 ;- FR Europay France
					$aIINList[916]=513115 ;- FR Europay France
					$aIINList[917]=513116 ;- FR Europay France
					$aIINList[918]=513117 ;- FR Europay France
					$aIINList[919]=513118 ;- FR Europay France
					$aIINList[920]=513119 ;- FR Europay France
					$aIINList[921]=513120 ;- FR Europay France
					$aIINList[922]=513121 ;- FR Europay France
					$aIINList[923]=513122 ;- FR Europay France
					$aIINList[924]=513123 ;- FR Europay France
					$aIINList[925]=513124 ;- FR Europay France
					$aIINList[926]=513125 ;- FR Europay France
					$aIINList[927]=513126 ;- FR Europay France
					$aIINList[928]=513127 ;- FR Europay France
					$aIINList[929]=513128 ;- FR Europay France
					$aIINList[930]=513129 ;- FR Europay France
					$aIINList[931]=513130 ;- FR Europay France
					$aIINList[932]=513131 ;- FR Europay France
					$aIINList[933]=513132 ;- FR Europay France
					$aIINList[934]=513133 ;- FR Europay France
					$aIINList[935]=513134 ;- FR Europay France
					$aIINList[936]=513135 ;- FR Europay France
					$aIINList[937]=513136 ;- FR Europay France
					$aIINList[938]=513137 ;- FR Europay France
					$aIINList[939]=513138 ;- FR Europay France
					$aIINList[940]=513139 ;- FR Europay France
					$aIINList[941]=513140 ;- FR Europay France
					$aIINList[942]=513141 ;- FR Europay France Crédit Agricole MasterCard Credit Card
					$aIINList[943]=513142 ;- FR Europay France
					$aIINList[944]=513143 ;- FR Europay France Advanzia Bank MasterCard Credit Card
					$aIINList[945]=513144 ;- FR Europay France Advanzia Bank
					$aIINList[946]=513145 ;- FR Europay France Advanzia Bank
					$aIINList[947]=513146 ;- FR Europay France Advanzia Bank
					$aIINList[948]=513147 ;- FR Europay France Advanzia Bank
					$aIINList[949]=513148 ;- FR Europay France Advanzia Bank
					$aIINList[950]=513149 ;- FR Europay France Advanzia Bank
					$aIINList[951]=513150 ;- FR Europay France Advanzia Bank
					$aIINList[952]=513151 ;- FR Europay France Advanzia Bank
					$aIINList[953]=513152 ;- FR Europay France Advanzia Bank
					$aIINList[954]=513153 ;- FR Europay France Advanzia Bank
					$aIINList[955]=513154 ;- FR Europay France Advanzia Bank
					$aIINList[956]=513155 ;- FR Europay France Advanzia Bank
					$aIINList[957]=513156 ;- FR Europay France Advanzia Bank
					$aIINList[958]=513157 ;- FR Europay France Advanzia Bank
					$aIINList[959]=513158 ;- FR Europay France Advanzia Bank
					$aIINList[960]=513159 ;- FR Europay France Advanzia Bank
					$aIINList[961]=513160 ;- FR Europay France Advanzia Bank
					$aIINList[962]=513161 ;- FR Europay France Advanzia Bank
					$aIINList[963]=513162 ;- FR Europay France Advanzia Bank
					$aIINList[964]=513163 ;- FR Europay France Advanzia Bank
					$aIINList[965]=513164 ;- FR Europay France Advanzia Bank
					$aIINList[966]=513165 ;- FR Europay France Advanzia Bank
					$aIINList[967]=513166 ;- FR Europay France Advanzia Bank
					$aIINList[968]=513167 ;- FR Europay France Advanzia Bank
					$aIINList[969]=513168 ;- FR Europay France Advanzia Bank
					$aIINList[970]=513169 ;- FR Europay France Advanzia Bank
					$aIINList[971]=513170 ;- FR Europay France Advanzia Bank
					$aIINList[972]=513171 ;- FR Europay France Advanzia Bank
					$aIINList[973]=513172 ;- FR Europay France Advanzia Bank
					$aIINList[974]=513173 ;- FR Europay France Advanzia Bank
					$aIINList[975]=513174 ;- FR Europay France Advanzia Bank
					$aIINList[976]=513175 ;- FR Europay France Advanzia Bank
					$aIINList[977]=513176 ;- FR Europay France Advanzia Bank
					$aIINList[978]=513177 ;- FR Europay France Advanzia Bank
					$aIINList[979]=513178 ;- FR Europay France Advanzia Bank
					$aIINList[980]=513179 ;- FR Europay France Advanzia Bank
					$aIINList[981]=513180 ;- FR Europay France Advanzia Bank
					$aIINList[982]=513181 ;- FR Europay France Advanzia Bank
					$aIINList[983]=513182 ;- FR Europay France Advanzia Bank
					$aIINList[984]=513183 ;- FR Europay France Advanzia Bank
					$aIINList[985]=513184 ;- FR Europay France Advanzia Bank
					$aIINList[986]=513185 ;- FR Europay France Advanzia Bank
					$aIINList[987]=513186 ;- FR Europay France Advanzia Bank
					$aIINList[988]=513187 ;- FR Europay France Advanzia Bank
					$aIINList[989]=513188 ;- FR Europay France Advanzia Bank
					$aIINList[990]=513189 ;- FR Europay France Advanzia Bank
					$aIINList[991]=513190 ;- FR Europay France Advanzia Bank
					$aIINList[992]=513191 ;- FR Europay France Advanzia Bank
					$aIINList[993]=513192 ;- FR Europay France Advanzia Bank
					$aIINList[994]=513193 ;- FR Europay France Advanzia Bank
					$aIINList[995]=513194 ;- FR Europay France Advanzia Bank
					$aIINList[996]=513195 ;- FR Europay France Advanzia Bank
					$aIINList[997]=513196 ;- FR Europay France Advanzia Bank
					$aIINList[998]=513197 ;- FR Europay France Advanzia Bank
					$aIINList[999]=513198 ;- FR Europay France Advanzia Bank
					$aIINList[1000]=513199 ;- FR Europay France Advanzia Bank
					$aIINList[1001]=513200 ;- FR Europay France
					$aIINList[1002]=513201 ;- FR Europay France
					$aIINList[1003]=513202 ;- FR Europay France
					$aIINList[1004]=513203 ;- FR Europay France
					$aIINList[1005]=513207 ;- FR Europay France
					$aIINList[1006]=513208 ;- FR Europay France
					$aIINList[1007]=513209 ;- FR Europay France
					$aIINList[1008]=513210 ;- FR Europay France
					$aIINList[1009]=513211 ;- FR Europay France
					$aIINList[1010]=513212 ;- FR Europay France
					$aIINList[1011]=513213 ;- FR Europay France
					$aIINList[1012]=513214 ;- FR Europay France
					$aIINList[1013]=513215 ;- FR Europay France
					$aIINList[1014]=513216 ;- FR Europay France
					$aIINList[1015]=513217 ;- FR Europay France
					$aIINList[1016]=513218 ;- FR Europay France
					$aIINList[1017]=513219 ;- FR Europay France
					$aIINList[1018]=513220 ;- FR Europay France
					$aIINList[1019]=513221 ;- FR Europay France
					$aIINList[1020]=513224 ;- FR Europay France
					$aIINList[1021]=513225 ;- FR Europay France
					$aIINList[1022]=513230 ;- FR Europay France
					$aIINList[1023]=513231 ;- FR Europay France
					$aIINList[1024]=513232 ;- FR Europay France
					$aIINList[1025]=513233 ;- FR Europay France
					$aIINList[1026]=513234 ;- FR Europay France
					$aIINList[1027]=513235 ;- FR Europay France
					$aIINList[1028]=513236 ;- FR Europay France
					$aIINList[1029]=513237 ;- FR Europay France
					$aIINList[1030]=513238 ;- FR Europay France
					$aIINList[1031]=513239 ;- FR Europay France
					$aIINList[1032]=513240 ;- FR Europay France
					$aIINList[1033]=513241 ;- FR Europay France
					$aIINList[1034]=513242 ;- FR Europay France
					$aIINList[1035]=513243 ;- FR Europay France
					$aIINList[1036]=513244 ;- FR Europay France
					$aIINList[1037]=513245 ;- FR Europay France
					$aIINList[1038]=513246 ;- FR Europay France
					$aIINList[1039]=513247 ;- FR Europay France
					$aIINList[1040]=513248 ;- FR Europay France
					$aIINList[1041]=513249 ;- FR Europay France
					$aIINList[1042]=513250 ;- FR Europay France
					$aIINList[1043]=513251 ;- FR Europay France
					$aIINList[1044]=513252 ;- FR Europay France
					$aIINList[1045]=513253 ;- FR Europay France
					$aIINList[1046]=513254 ;- FR Europay France
					$aIINList[1047]=513255 ;- FR Europay France
					$aIINList[1048]=513256 ;- FR Europay France
					$aIINList[1049]=513257 ;- FR Europay France
					$aIINList[1050]=513258 ;- FR Europay France
					$aIINList[1051]=513261 ;- FR Europay France
					$aIINList[1052]=513262 ;- FR Europay France
					$aIINList[1053]=513263 ;- FR Europay France
					$aIINList[1054]=513264 ;- FR Europay France
					$aIINList[1055]=513265 ;- FR Europay France
					$aIINList[1056]=513266 ;- FR Europay France
					$aIINList[1057]=513267 ;- FR Europay France
					$aIINList[1058]=513268 ;- FR Europay France
					$aIINList[1059]=513269 ;- FR Europay France
					$aIINList[1060]=513270 ;- FR Europay France
					$aIINList[1061]=513271 ;- FR Europay France
					$aIINList[1062]=513272 ;- FR Europay France
					$aIINList[1063]=513273 ;- FR Europay France
					$aIINList[1064]=513274 ;- FR Europay France
					$aIINList[1065]=513275 ;- FR Europay France
					$aIINList[1066]=513276 ;- FR Europay France
					$aIINList[1067]=513277 ;- FR Europay France
					$aIINList[1068]=513278 ;- FR Europay France
					$aIINList[1069]=513279 ;- FR Europay France
					$aIINList[1070]=513283 ;- FR Europay France
					$aIINList[1071]=513284 ;- FR Europay France
					$aIINList[1072]=513285 ;- FR Europay France
					$aIINList[1073]=513286 ;- FR Europay France
					$aIINList[1074]=513287 ;- FR Europay France
					$aIINList[1075]=513288 ;- FR Europay France
					$aIINList[1076]=513290 ;- FR Europay France
					$aIINList[1077]=513291 ;- FR Europay France
					$aIINList[1078]=513292 ;- FR Europay France
					$aIINList[1079]=513293 ;- FR Europay France
					$aIINList[1080]=513294 ;- FR Europay France
					$aIINList[1081]=513296 ;- FR Europay France
					$aIINList[1082]=513297 ;- FR Europay France
					$aIINList[1083]=513299 ;- FR Europay France
					$aIINList[1084]=513300 ;- FR Europay France
					$aIINList[1085]=513310 ;- FR Europay France
					$aIINList[1086]=513320 ;- FR Europay France
					$aIINList[1087]=513350 ;- FR Europay France
					$aIINList[1088]=513400 ;- FR Europay France
					$aIINList[1089]=513411 ;- FR Europay France
					$aIINList[1090]=513412 ;- FR Europay France
					$aIINList[1091]=513413 ;- FR Europay France
					$aIINList[1092]=513453 ;- FR BNP Paribas MasterCard Credit Card
					$aIINList[1093]=513500 ;- FR Europay France
					$aIINList[1094]=513501 ;- FR Europay France
					$aIINList[1095]=513502 ;- FR Europay France
					$aIINList[1096]=513503 ;- FR Europay France
					$aIINList[1097]=513504 ;- FR Europay France
					$aIINList[1098]=513505 ;- FR Europay France
					$aIINList[1099]=513506 ;- FR Europay France
					$aIINList[1100]=513507 ;- FR Europay France
					$aIINList[1101]=513508 ;- FR Europay France
					$aIINList[1102]=513509 ;- FR Europay France
					$aIINList[1103]=513510 ;- FR Europay France
					$aIINList[1104]=513511 ;- FR Europay France
					$aIINList[1105]=513512 ;- FR Europay France
					$aIINList[1106]=513513 ;- FR Europay France
					$aIINList[1107]=513514 ;- FR Europay France
					$aIINList[1108]=513515 ;- FR Europay France
					$aIINList[1109]=513516 ;- FR Europay France
					$aIINList[1110]=513517 ;- FR Europay France
					$aIINList[1111]=513518 ;- FR Europay France
					$aIINList[1112]=513519 ;- FR Europay France
					$aIINList[1113]=513520 ;- FR Europay France
					$aIINList[1114]=513521 ;- FR Europay France
					$aIINList[1115]=513522 ;- FR Europay France
					$aIINList[1116]=513523 ;- FR Europay France
					$aIINList[1117]=513524 ;- FR Europay France
					$aIINList[1118]=513525 ;- FR Europay France
					$aIINList[1119]=513526 ;- FR Europay France
					$aIINList[1120]=513527 ;- FR Europay France
					$aIINList[1121]=513528 ;- FR Europay France
					$aIINList[1122]=513529 ;- FR Europay France
					$aIINList[1123]=513530 ;- FR Europay France
					$aIINList[1124]=513531 ;- FR Europay France
					$aIINList[1125]=513532 ;- FR Europay France
					$aIINList[1126]=513533 ;- FR Europay France
					$aIINList[1127]=513534 ;- FR Europay France
					$aIINList[1128]=513536 ;- FR Europay France BRED Banque Populaire Affinity MasterCard Credit Card
					$aIINList[1129]=513537 ;- FR Europay France
					$aIINList[1130]=513538 ;- FR Europay France
					$aIINList[1131]=513539 ;- FR Europay France
					$aIINList[1132]=513540 ;- FR Europay France
					$aIINList[1133]=513541 ;- FR Europay France
					$aIINList[1134]=513542 ;- FR Europay France
					$aIINList[1135]=513543 ;- FR Europay France
					$aIINList[1136]=513544 ;- FR Europay France
					$aIINList[1137]=513545 ;- FR Europay France
					$aIINList[1138]=513546 ;- FR Europay France
					$aIINList[1139]=513547 ;- FR Europay France
					$aIINList[1140]=513548 ;- FR Europay France
					$aIINList[1141]=513549 ;- FR Europay France
					$aIINList[1142]=513550 ;- FR Europay France
					$aIINList[1143]=513551 ;- FR Europay France
					$aIINList[1144]=513552 ;- FR Europay France
					$aIINList[1145]=513553 ;- FR Europay France
					$aIINList[1146]=513554 ;- FR Europay France
					$aIINList[1147]=513555 ;- FR Europay France
					$aIINList[1148]=513556 ;- FR Europay France
					$aIINList[1149]=513557 ;- FR Europay France
					$aIINList[1150]=513558 ;- FR Europay France
					$aIINList[1151]=513559 ;- FR Europay France
					$aIINList[1152]=513560 ;- FR Europay France
					$aIINList[1153]=513561 ;- FR Europay France
					$aIINList[1154]=513562 ;- FR Europay France
					$aIINList[1155]=513563 ;- FR Europay France
					$aIINList[1156]=513564 ;- FR Europay France
					$aIINList[1157]=513565 ;- FR Europay France
					$aIINList[1158]=513566 ;- FR Europay France
					$aIINList[1159]=513567 ;- FR Europay France
					$aIINList[1160]=513568 ;- FR Europay France
					$aIINList[1161]=513569 ;- FR Europay France
					$aIINList[1162]=513570 ;- FR Europay France
					$aIINList[1163]=513600 ;- FR Europay France
					$aIINList[1164]=513601 ;- FR Europay France
					$aIINList[1165]=513602 ;- FR Europay France
					$aIINList[1166]=513603 ;- FR Europay France
					$aIINList[1167]=513604 ;- FR Europay France
					$aIINList[1168]=513605 ;- FR Europay France
					$aIINList[1169]=513606 ;- FR Europay France
					$aIINList[1170]=513607 ;- FR Europay France
					$aIINList[1171]=513608 ;- FR Europay France
					$aIINList[1172]=513609 ;- FR Europay France
					$aIINList[1173]=513610 ;- FR Europay France
					$aIINList[1174]=513611 ;- FR Europay France
					$aIINList[1175]=513612 ;- FR Europay France
					$aIINList[1176]=513613 ;- FR Europay France
					$aIINList[1177]=513614 ;- FR Europay France
					$aIINList[1178]=513615 ;- FR Europay France
					$aIINList[1179]=513616 ;- FR Europay France
					$aIINList[1180]=513617 ;- FR Europay France
					$aIINList[1181]=513618 ;- FR Europay France
					$aIINList[1182]=513619 ;- FR Europay France
					$aIINList[1183]=513620 ;- FR Europay France
					$aIINList[1184]=513621 ;- FR Europay France
					$aIINList[1185]=513622 ;- FR Europay France
					$aIINList[1186]=513623 ;- FR Europay France
					$aIINList[1187]=513624 ;- FR Europay France ;- Barclays Bank PLC MasterCard Platinum
					$aIINList[1188]=513624 ;- FR Europay France
					$aIINList[1189]=513625 ;- FR Europay France
					$aIINList[1190]=513626 ;- FR Europay France
					$aIINList[1191]=513627 ;- FR Europay France
					$aIINList[1192]=513628 ;- FR Europay France
					$aIINList[1193]=513629 ;- FR Europay France
					$aIINList[1194]=513630 ;- FR Europay France
					$aIINList[1195]=513631 ;- FR Europay France
					$aIINList[1196]=513632 ;- FR Europay France
					$aIINList[1197]=513633 ;- FR Europay France
					$aIINList[1198]=513634 ;- FR Europay France
					$aIINList[1199]=513635 ;- FR Europay France
					$aIINList[1200]=513636 ;- FR Europay France
					$aIINList[1201]=513637 ;- FR Europay France
					$aIINList[1202]=513638 ;- FR Europay France
					$aIINList[1203]=513639 ;- FR Europay France
					$aIINList[1204]=513640 ;- FR Europay France
					$aIINList[1205]=513641 ;- FR Europay France
					$aIINList[1206]=513642 ;- FR Europay France
					$aIINList[1207]=513643 ;- FR Europay France
					$aIINList[1208]=513644 ;- FR Europay France
					$aIINList[1209]=513645 ;- FR Europay France
					$aIINList[1210]=513646 ;- FR Europay France
					$aIINList[1211]=513647 ;- FR Europay France
					$aIINList[1212]=513648 ;- FR Europay France
					$aIINList[1213]=513649 ;- FR Europay France
					$aIINList[1214]=513650 ;- FR Europay France
					$aIINList[1215]=513651 ;- FR Europay France
					$aIINList[1216]=513652 ;- FR Europay France
					$aIINList[1217]=513653 ;- FR Europay France
					$aIINList[1218]=513655 ;- FR Europay France
					$aIINList[1219]=513662 ;- FR Europay France
					$aIINList[1220]=513663 ;- FR Europay France
					$aIINList[1221]=513664 ;- FR Europay France
					$aIINList[1222]=513665 ;- FR Europay France
					$aIINList[1223]=513666 ;- FR Europay France
					$aIINList[1224]=513667 ;- FR Europay France
					$aIINList[1225]=513668 ;- FR Europay France
					$aIINList[1226]=513669 ;- FR Europay France
					$aIINList[1227]=513670 ;- FR Europay France
					$aIINList[1228]=513698 ;- FR Europay France
					$aIINList[1229]=513699 ;- FR Europay France
					$aIINList[1230]=513691 ;- RU Russian Standard Bank, Russia MasterCard Unembossed (Instant Issue)
					$aIINList[1231]=513700 ;- FR Europay France
					$aIINList[1232]=513704 ;- FR Europay France
					$aIINList[1233]=513707 ;- FR Europay France
					$aIINList[1234]=513708 ;- FR Europay France
					$aIINList[1235]=513710 ;- FR Europay France
					$aIINList[1236]=513711 ;- FR Europay France
					$aIINList[1237]=513712 ;- FR Europay France
					$aIINList[1238]=513713 ;- FR Europay France
					$aIINList[1239]=513714 ;- FR Europay France
					$aIINList[1240]=513800 ;- FR Europay France
					$aIINList[1241]=513801 ;- FR Europay France
					$aIINList[1242]=513802 ;- FR Europay France
					$aIINList[1243]=513803 ;- FR Europay France
					$aIINList[1244]=513804 ;- FR Europay France
					$aIINList[1245]=513805 ;- FR Europay France
					$aIINList[1246]=513806 ;- FR Europay France
					$aIINList[1247]=513807 ;- FR Europay France
					$aIINList[1248]=513808 ;- FR Europay France
					$aIINList[1249]=513809 ;- FR Europay France
					$aIINList[1250]=513810 ;- FR Europay France
					$aIINList[1251]=513811 ;- FR Europay France
					$aIINList[1252]=513812 ;- FR Europay France
					$aIINList[1253]=513813 ;- FR Europay France
					$aIINList[1254]=513814 ;- FR Europay France
					$aIINList[1255]=513815 ;- FR Europay France
					$aIINList[1256]=513816 ;- FR Europay France
					$aIINList[1257]=513817 ;- FR Europay France
					$aIINList[1258]=513818 ;- FR Europay France
					$aIINList[1259]=513819 ;- FR Europay France
					$aIINList[1260]=513820 ;- FR Europay France
					$aIINList[1261]=513821 ;- FR Europay France
					$aIINList[1262]=513822 ;- FR Europay France
					$aIINList[1263]=513823 ;- FR Europay France
					$aIINList[1264]=513824 ;- FR Europay France
					$aIINList[1265]=513825 ;- FR Europay France
					$aIINList[1266]=513826 ;- FR Europay France
					$aIINList[1267]=513827 ;- FR Europay France
					$aIINList[1268]=513828 ;- FR Europay France
					$aIINList[1269]=513829 ;- FR Europay France
					$aIINList[1270]=513830 ;- FR Europay France
					$aIINList[1271]=513831 ;- FR Europay France
					$aIINList[1272]=513832 ;- FR Europay France
					$aIINList[1273]=513833 ;- FR Europay France
					$aIINList[1274]=513834 ;- FR Europay France
					$aIINList[1275]=513835 ;- FR Europay France
					$aIINList[1276]=513900 ;- FR Europay France
					$aIINList[1277]=514011 ;- US Integra Bank
					$aIINList[1278]=514012 ;- US CitiBank South Dakota
					$aIINList[1279]=514013 ;- US Elgin First Credit Union
					$aIINList[1280]=514015 ;- US Infibank
					$aIINList[1281]=514016 ;- US Miramar First Credit Union
					$aIINList[1282]=514017 ;- US Franklin Templeton Bank and Trust
					$aIINList[1283]=514019 ;- US Wells Fargo
					$aIINList[1284]=514020 ;- US Wells Fargo
					$aIINList[1285]=514021 ;- US Juniper Bank Now known as Barclays Bank PLC
					$aIINList[1286]=514022 ;- US Navy Federal Credit Union
					$aIINList[1287]=514045 ;- AU Aussie Mastercard Credit Card
					$aIINList[1288]=514102 ;- US Park National Bank
					$aIINList[1289]=514108 ;- US Paradigm Bank Texas
					$aIINList[1290]=514250 ;- AU Commonwealth Securities Debit Mastercard
					$aIINList[1291]=514253 ;- US EDS Employees First Credit Union
					$aIINList[1292]=514700 ;- Mascoma Savings Bank Business Mastercard Debit Card
					$aIINList[1293]=514876 ;- KR CitiBank Platinum MasterCard
					$aIINList[1294]=514889 ;- US Juniper Bank Now known as Barclays Bank PLC
					$aIINList[1295]=514923 ;- US Chase Manhattan Bank USA
					$aIINList[1296]=515462 ;- US Bankcorp Bank "Vanilla" Sams Club Gift PrePaid
					$aIINList[1297]=515854 ;- RU Citibank Citigold Debit Card
					$aIINList[1298]=517644 ;- US Miramar First Credit Union
					$aIINList[1299]=516010 ;- PL Polbank EFG MasterCard Credit Card
					$aIINList[1300]=516029 ;- CitiFinancial Shell/CitiFinancial Europe MasterCard
					$aIINList[1301]=516300 ;- AU Westpac Banking Corporation
					$aIINList[1302]=516310 ;- AU Westpac Banking Corporation
					$aIINList[1303]=516315 ;- AU Westpac Banking Corporation
					$aIINList[1304]=516331 ;- RU Svyaznoy Bank
					$aIINList[1305]=516335 ;- AU Westpac Banking Corporation
					$aIINList[1306]=516321 ;- AU Westpac Banking Corporation Australia Mastercard Credit Card
					$aIINList[1307]=516337 ;- AU Westpac Banking Corporation Australia Platinum MasterCard
					$aIINList[1308]=516361 ;- AU Westpac Banking Corporation Debit MasterCard
					$aIINList[1309]=516366 ;- AU Westpac Banking Corporation Debit MasterCard
					$aIINList[1310]=516693 ;- USA FISERV SOLUTIONS CREDIT Mastercard
					$aIINList[1311]=517651 ;- US 5-Star Bank
					$aIINList[1312]=517652 ;- HDFC Bank MasterCard Gold Credit Card
					$aIINList[1313]=517669 ;- UK HSBC (formerly Household) MasterCard Credit Card
					$aIINList[1314]=517805 ;- US Jpmorgan Chase Bank MasterCard Credit Card
					$aIINList[1315]=517869 ;- US Union Bank[disambiguation needed] MasterCard Debit Card
					$aIINList[1316]=518126 ;- Utility Warehouse MasterCard PrePaid Card
					$aIINList[1317]=518127 ;- CA President's Choice Financial MasterCard Credit Card
					$aIINList[1318]=518142 ;- UK MBNA MasterCard[citation needed]
					$aIINList[1319]=518145 ;- UK Royal Bank of Scotland Tesco Bank Classic MasterCard Credit Card
					$aIINList[1320]=518152 ;- UK  Tesco Bank ClubCard MasterCard Credit Card
					$aIINList[1321]=518175 ;- UK MBNA British Midland Airways MasterCard
					$aIINList[1322]=518346 ;- DE Unicredit Bank AG Unicredit Bank AG Mastercard
					$aIINList[1323]=518390 ;- US Citibank Sunoco or Conoco Mastercard
					$aIINList[1324]=518542 ;- HK HSBC Premier Banking World Mastercard
					$aIINList[1325]=518676 ;- IE AvantCard AvantCard (formerly MBNA Ireland) Platinum MasterCard
					$aIINList[1326]=518652 ;- EUR GBR EDINBURGH ROYAL BANK OF SCOTLAND PLC.
					$aIINList[1327]=518791 ;- Lloyds TSB MasterCard CreditCard
					$aIINList[1328]=518868 ;- AU Bendigo Bank bendigoblue MasterCard Debit
					$aIINList[1329]=518996 ;- Russia UniCredit Bank,
					$aIINList[1330]=519000 ;- CA Bank of Montreal
					$aIINList[1331]=519113 ;- CA Bank of Montreal
					$aIINList[1332]=519120 ;- CA Bank of Montreal
					$aIINList[1333]=519121 ;- CA Bank of Montreal
					$aIINList[1334]=519122 ;- CA Bank of Montreal
					$aIINList[1335]=519123 ;- CA Bank of Montreal
					$aIINList[1336]=519129 ;- CA Bank of Montreal
					$aIINList[1337]=519133 ;- CA Bank of Montreal
					$aIINList[1338]=519140 ;- CA Bank of Montreal
					$aIINList[1339]=519141 ;- CA Bank of Montreal
					$aIINList[1340]=519142 ;- CA Bank of Montreal
					$aIINList[1341]=519143 ;- CA Bank of Montreal
					$aIINList[1342]=519154 ;- CA Bank of Montreal
					$aIINList[1343]=519161 ;- CA Bank of Montreal
					$aIINList[1344]=519162 ;- CA Bank of Montreal
					$aIINList[1345]=519163 ;- NZ Kiwibank
					$aIINList[1346]=519173 ;- CA Bank of Montreal
					$aIINList[1347]=519180 ;- CA Bank of Montreal
					$aIINList[1348]=519181 ;- CA Bank of Montreal
					$aIINList[1349]=519182 ;- CA Bank of Montreal
					$aIINList[1350]=519183 ;- CA Bank of Montreal
					$aIINList[1351]=519200 ;- CA Bank of Montreal
					$aIINList[1352]=519201 ;- CA Bank of Montreal
					$aIINList[1353]=519202 ;- CA Bank of Montreal
					$aIINList[1354]=519220 ;- CA Bank of Montreal
					$aIINList[1355]=519221 ;- CA Bank of Montreal
					$aIINList[1356]=519222 ;- CA Bank of Montreal
					$aIINList[1357]=519223 ;- CA Bank of Montreal
					$aIINList[1358]=519240 ;- CA Bank of Montreal
					$aIINList[1359]=519241 ;- CA Bank of Montreal
					$aIINList[1360]=519242 ;- CA Bank of Montreal
					$aIINList[1361]=519244 ;- AU Bendigo Bank Business Blue Debit Mastercard
					$aIINList[1362]=519259 ;- CA Bank of Montreal
					$aIINList[1363]=519269 ;- CA Bank of Montreal USD Mastercard
					$aIINList[1364]=519281 ;- CA Bank of Montreal
					$aIINList[1365]=519283 ;- CA Bank of Montreal
					$aIINList[1366]=519290 ;- CA Bank of Montreal
					$aIINList[1367]=519293 ;- CA Bank of Montreal
					$aIINList[1368]=519294 ;- CA Bank of Montreal
					$aIINList[1369]=519322 ;- CA Bank of Montreal
					$aIINList[1370]=519323 ;- CA Bank of Montreal
					$aIINList[1371]=519332 ;- CA Bank of Montreal
					$aIINList[1372]=519342 ;- CA Bank of Montreal
					$aIINList[1373]=519371 ;- CA Bank of Montreal
					$aIINList[1374]=519373 ;- CA Bank of Montreal
					$aIINList[1375]=519381 ;- CA Bank of Montreal
					$aIINList[1376]=519383 ;- CA Bank of Montreal
					$aIINList[1377]=519390 ;- CA Bank of Montreal
					$aIINList[1378]=519391 ;- CA Bank of Montreal
					$aIINList[1379]=519393 ;- CA Bank of Montreal
					$aIINList[1380]=519394 ;- CA Bank of Montreal
					$aIINList[1381]=519395 ;- CA Bank of Montreal
					$aIINList[1382]=519398 ;- CA HSBC Canada
					$aIINList[1383]=519400 ;- CA Bank of Montreal
					$aIINList[1384]=519403 ;- CA Bank of Montreal
					$aIINList[1385]=519409 ;- CA Bank of Montreal
					$aIINList[1386]=519430 ;- CA Bank of Montreal
					$aIINList[1387]=519431 ;- CA Bank of Montreal
					$aIINList[1388]=519433 ;- CA Bank of Montreal
					$aIINList[1389]=519434 ;- CA Bank of Montreal
					$aIINList[1390]=519443 ;- CA Bank of Montreal
					$aIINList[1391]=519463 ;- PH Banco De Oro MasterCard Debit Card
					$aIINList[1392]=519490 ;- CA Bank of Montreal
					$aIINList[1393]=519491 ;- CA Bank of Montreal
					$aIINList[1394]=519493 ;- CA Bank of Montreal
					$aIINList[1395]=519494 ;- CA Bank of Montreal
					$aIINList[1396]=519520 ;- Altair Prepaid Cards
					$aIINList[1397]=519525 ;- Contis Group & EZPay Prepaid Cards
					$aIINList[1398]=519540 ;- CA Bank of Montreal
					$aIINList[1399]=519541 ;- CA Bank of Montreal
					$aIINList[1400]=519542 ;- CA Bank of Montreal
					$aIINList[1401]=519543 ;- CA Bank of Montreal
					$aIINList[1402]=519544 ;- CA Bank of Montreal
					$aIINList[1403]=513264 ;- Crédit Mutuel MasterCard Credit Card (France)
					$aIINList[1404]=520108 ;- China CITIC Bank Master Card (China)
					$aIINList[1405]=520169 ;- BestBuy MasterCard by Bank of Communications/HSBC (China)
					$aIINList[1406]=520301 ;- credit/debit cards issued by Valovis Commercial Bank under various brands (Germany)
					$aIINList[1407]=520306 ;- Citibank/Lufthansa Miles & More MasterCard Credit Card (Russia)
					$aIINList[1408]=520641 ;- Tesco Bank Bonus Mastercard(UK)
					$aIINList[1409]=520988 ;- Garanti Bank Shop&Miles MasterCard Credit Card
					$aIINList[1410]=520991 ;- Nordea Gold (Sweden)
					$aIINList[1411]=521324 ;- Tinkoff Credit Systems (Russia), MasterCard Platinum Credit Card
					$aIINList[1412]=521326 ;- SMP Bank (Russia), MasterCard Platinum Transaero Card
					$aIINList[1413]=521402 ;- Mastercard
					$aIINList[1414]=521679 ;- US Bank National Association, Giftcard
					$aIINList[1415]=521584 ;- Finansbank Prepaid Card
					$aIINList[1416]=521804 ;- Tesco Bank Business Mastercard (UK)
					$aIINList[1417]=521853 ;- PayPal MasterCard
					$aIINList[1418]=521893 ;- Go Mastercard, GE Capital Finance T/A GE Money (AUS)
					$aIINList[1419]=521899 ;- Bank of Communications, HSBC Co-Branded Credit Card (China)
					$aIINList[1420]=522182 ;- People's Trust (US)
					$aIINList[1421]=522222 ;- United Overseas Bank MasterCard Platinum Malaysia
					$aIINList[1422]=522223 ;- Avangard Bank, Russia
					$aIINList[1423]=522276 ;- Chase Manhattan Bank MasterCard Credit Card
					$aIINList[1424]=523748 ;- Commonwealth Bank of Australia Prepaid Travel Money Mastercard
					$aIINList[1425]=523911 ;- Affinity Bank
					$aIINList[1426]=523912 ;- Affinity Bank
					$aIINList[1427]=523916 ;- Citibank Platinum Credit Card (Argentina)
					$aIINList[1428]=523935 ;- Citibank (Malaysia)
					$aIINList[1429]=523951 ;- ICICI Bank MasterCard Credit Card (India)
					$aIINList[1430]=524040 ;- OCBC Bank BEST-OCBC MasterCard Credit Card (Singapore)
					$aIINList[1431]=524100 ;- Citibank Korea
					$aIINList[1432]=524805 ;- Orico MasterCard Credit Card (Japan)
					$aIINList[1433]=525241 ;- Saison Card International, Japan ;- United Airlines MileagePlus
					$aIINList[1434]=525303 ;- Halifax/Bank of Scotland (UK)
					$aIINList[1435]=525405 ;- VÚB Banka (Banca Intesa group) MasterCard original+ Credit card (Slovakia)
					$aIINList[1436]=525678 ;- Banamex Debit card
					$aIINList[1437]=525896 ;- Mastercard Husky (Canada) [Husky/Mohawk MasterCard]
					$aIINList[1438]=525995 ;- Canadian Tire Bank Gas Advantage MasterCard
					$aIINList[1439]=526219 ;- Citibank MasterCard American Airlines AAdvantage Debit Card
					$aIINList[1440]=526224 ;- Citibank MasterCard Debit Card
					$aIINList[1441]=526226 ;- Citibank MasterCard Card
					$aIINList[1442]=526418 ;- Vietcombank ;- Vietnam ;- MasterCard Debit Card
					$aIINList[1443]=526468 ;- SBI Cards credit card (India)
					$aIINList[1444]=526471 ;- POSBank MasterCard Debit/ATM Card (Singapore)
					$aIINList[1445]=526495 ;- Bank of India MasterCard Debit/ATM Card
					$aIINList[1446]=526702 ;- Yes Bank Mastercard Silver Debit Card (India)
					$aIINList[1447]=526722 ;- Standard Bank South Africa MasterCard Credit Card (Gift Card)
					$aIINList[1448]=526737 ;- Security Bank Cash Card (Philippines)
					$aIINList[1449]=526781 ;- VÚB Banka (Banca Intesa group) ;- MasterCard unembossed Credit card (Slovakia)
					$aIINList[1450]=526790 ;- Asia Commercial Bank Vietnam ;- MasterCard Debit Card
					$aIINList[1451]=527434 ;- Caixanova NovaXove / EVO Banco (Spain) Mastecard Debit Card
					$aIINList[1452]=527455 ;- Rubycard Pre-Paid Mastercard (Ireland) issued by Newcastle Building Society
					$aIINList[1453]=527456 ;- WireCard Bank (Germany)
					$aIINList[1454]=527890 ;- Go National (National Bank of Greece)
					$aIINList[1455]=528013 ;- Bankwest Australia MasterCard Debit Card
					$aIINList[1456]=528038 ;- ING Bank N.V. Amsterdam
					$aIINList[1457]=528061 ;- BMO Bank of Montreal MasterCard Prepaid Travel
					$aIINList[1458]=528093 ;- Banesto (Spain) Mastercard Prepaid Sevilla Futbol Club
					$aIINList[1459]=528229 ;- Nexpay prepaid card
					$aIINList[1460]=528683 ;- The Governor And Company Of The Bank Of Scotland EUR GBR DUNFERMLINE
					$aIINList[1461]=528689 ;- Santander UK Zero MasterCard Credit Card UK
					$aIINList[1462]=528919 ;- CIMB Niaga Platinum MasterCard Credit Card (Indonesia)
					$aIINList[1463]=528945 ;- HDFC Bank MasterCard credit card (India)
					$aIINList[1464]=529020 ;- Woolworths Everyday Money MasterCard credit card
					$aIINList[1465]=529480 ;- Santander [CONTIGO] Credit Card (Spain)
					$aIINList[1466]=529512 ;- Prepaid Debit MasterCard issued by Australia and New Zealand Banking Group
					$aIINList[1467]=529523 ;- Woolworths Everyday Money Prepaid MasterCard (issued by ANZ Banking Group)
					$aIINList[1468]=529565 ;- Spark Prepaid MasterCard issued by Prepaid Financial Services Limited (UK)
					$aIINList[1469]=529580 ;- (Italy) Kalixa Prepaid MasterCard (Vincento Payment Solutions)
					$aIINList[1470]=529930 ;- Marks & Spencer Money MasterCard Credit Card
					$aIINList[1471]=529932 ;- Asda branded MasterCard Credit Card (UK)
					$aIINList[1472]=529962 ;- Prepaid MasterCards issued by DCBANK. (MuchMusic)
					$aIINList[1473]=529964 ;- CardOneBanking Mastercard Debit
					$aIINList[1474]=529965 ;- pre paid debit cards
					$aIINList[1475]=529966 ;- pre paid debit cards
					$aIINList[1476]=530111 ;- Citibank
					$aIINList[1477]=530127 ;- BARCLAYS BANK PLC. EUR GBR NORTHAMPTON
					$aIINList[1478]=530343 ;- Net1 Virtual Card Prepaid
					$aIINList[1479]=530442 ;- Choice Bank Limited (Payoneer)
					$aIINList[1480]=530695 ;- Bancolombia Prepaid MasterCard Credit Card (E-prepago)
					$aIINList[1481]=530785 ;- Sears MasterCard ;- Chase Card Service Canada
					$aIINList[1482]=530786 ;- Sears Voyage MasterCard ;- Chase Card Services Canada
					$aIINList[1483]=530831 ;- Orange Cash Prepaid MasterCard, issued by Orange and Barclays with PayPass
					$aIINList[1484]=531045 ;- MBNA Virgin Money
					$aIINList[1485]=531106 ;- PayPal (USA) Prepaid MasterCard ;- NetSpend / The Bancorp Bank
					$aIINList[1486]=531108 ;- MetaBank (USA) Prepaid Debit Mastercard
					$aIINList[1487]=531207 ;- Uralsib Bank (Russia), MasterCard World ;- Aeroflot bonus
					$aIINList[1488]=531289 ;- AEON View Suica MasterCard Credit Card (Japan)
					$aIINList[1489]=531306 ;- Newcastle Building SocietyPrepaid Mastercard. Various trade names e.g. Moneybookers.com, Monarch Airlines
					$aIINList[1490]=531307 ;- Newcastle Building Society Prepaid Mastercard. Various trade names e.g. FairFX
					$aIINList[1491]=531355 ;- National Bank MasterCard Credit Card
					$aIINList[1492]=531445 ;- Payoneer MasterCard Debit Card
					$aIINList[1493]=531496 ;- Air New Zealand OneSmart Prepaid Debit Card (issued by the Bank of New Zealand
					$aIINList[1494]=532450 ;- China Construction Bank Credit Card
					$aIINList[1495]=532561 ;- HSBC Bank USA Premier Debit Mastercard with PayPass
					$aIINList[1496]=532700 ;- RBS Premium MasterCard Debit Card
					$aIINList[1497]=532737 ;- BankWest Platinum Debit MasterCard
					$aIINList[1498]=532902 ;- Wachovia Bank MasterCard Credit Card
					$aIINList[1499]=533157 ;- RNKO, Euroset Kukuruza Bonus (Russia) Mastercard Unembossed, Instant Issue
					$aIINList[1500]=533200 ;- Metro Bank PLC UK retail Mastercard credit card
					$aIINList[1501]=533206 ;- Avangard Bank MasterCard Credit Card
					$aIINList[1502]=533248 ;- Comerica Bank Mastercard prepaid
					$aIINList[1503]=533389 ;- New Zealand Credit Unions Debit Card
					$aIINList[1504]=533505 ;- Citibank Japan (Titanium) credit card
					$aIINList[1505]=533506 ;- Citibank Japan (World) credit card
					$aIINList[1506]=533619 ;- CIMB Niaga Syariah Gold MasterCard Credit Card
					$aIINList[1507]=533838 ;- [CBA] Prepaid Gift card as MasterCard
					$aIINList[1508]=533846 ;- Kalixa Prepaid Mastercard UK Kalixa Prepaid MasterCard (Vincento Payment Solutions)
					$aIINList[1509]=533875 ;- Paypal Italy MasterCard Prepaid
					$aIINList[1510]=533896 ;- Paypal Access Card (UK)
					$aIINList[1511]=533908 ;- Bank Zachodni WBK Mastercard Premium Prepaid PayPass (Electronic) (Poland)
					$aIINList[1512]=533936 ;- Kalixa Prepaid Mastercard DE Kalixa Prepaid MasterCard (Vincento Payment Solutions)
					$aIINList[1513]=534248 ;- Best Buy
					$aIINList[1514]=535316 ;- Commonwealth Bank Standard MasterCard Credit Card
					$aIINList[1515]=535317 ;- Commonwealth Bank Credit Card
					$aIINList[1516]=535318 ;- Commonwealth Bank Gold MasterCard Credit Card
					$aIINList[1517]=536386 ;- Barclaycard World Mastercard (UK)
					$aIINList[1518]=536409 ;- Russian Agricultural Bank (Rosselhozbank) MasterCard Country Debit Card
					$aIINList[1519]=537004 ;- RNKO, Russia, Svyaznoy MasterCard Unembossed Card Instant Issue
					$aIINList[1520]=537196 ;- Commonwealth Bank Debit Card
					$aIINList[1521]=537881 ;- CUETS Financial
					$aIINList[1522]=538720 ;- BC Mastercard issued by Woori Bank
					$aIINList[1523]=538803 ;- BC Mastercard issued by Industrial Bank of Korea
					$aIINList[1524]=538806 ;- BC Mastercard issued by Kookmin Bank
					$aIINList[1525]=538811 ;- BC Mastercard issued by Nonghyup Central Bank
					$aIINList[1526]=538812 ;- BC Mastercard issued by Nonghyup Local Banks
					$aIINList[1527]=538820 ;- BC Mastercard
					$aIINList[1528]=538823 ;- BC Mastercard issued by SC First Bank
					$aIINList[1529]=538825 ;- BC Mastercard issued by Hana Bank
					$aIINList[1530]=538827 ;- BC Mastercard issued by Citibank in Korea
					$aIINList[1531]=538878 ;- BC Mastercard issued by Shinhan Bank
					$aIINList[1532]=539028 ;- Citibank Mastercard (Brazil)
					$aIINList[1533]=539655 ;- AT&T Universal MasterCard Credit Card, now part of Citibank
					$aIINList[1534]=539673 ;- Avangard Bank, MasterCard World Signia Card
					$aIINList[1535]=539738 ;- FNB Bank, MasterCard Debit Prepaid (USA)
					$aIINList[1536]=539941 ;- Zenith Bank (Nigeria) MasterCard Debit Card
					$aIINList[1537]=539923 ;- First Bank of Nigeria MasterCard Debit Card
					$aIINList[1538]=540002 ;- DBS (Esso co-branded) Singapore
					$aIINList[1539]=540012 ;- OCBC Singapore Titanium
					$aIINList[1540]=540034 ;- Standard Chartered Bank Titanium Credit Card (HK)
					$aIINList[1541]=540041 ;- HSBC Bank Gold Malaysia
					$aIINList[1542]=540141 ;- BANESCO Classic Mastercard card (Venezuela).
					$aIINList[1543]=540168 ;- Chase MasterCard Credit Card
					$aIINList[1544]=540187 ;- Advanzia Bank (LU)
					$aIINList[1545]=540204 ;- Citibank Hong Kong MasterCard Credit Card
					$aIINList[1546]=540205 ;- Citibank Taiwan MasterCard Credit Card
					$aIINList[1547]=540207 ;- BNZ (Bank of New Zealand) Global Plus MasterCard Credit Card
					$aIINList[1548]=540221 ;- ANZ Bank New Zealand ANZ MasterCard Credit Card
					$aIINList[1549]=540223 ;- Westpac New Zealand MasterCard Credit Card
					$aIINList[1550]=540256 ;- Citibank Malaysia MasterCard Credit Card
					$aIINList[1551]=540410 ;- Brown Thomas MasterCard (Issued by AIB)
					$aIINList[1552]=540450 ;- Advanced Payment Solutions (APS)
					$aIINList[1553]=540451 ;- Advanced Payment Solutions (APS)
					$aIINList[1554]=540482 ;- Bankwest Zero Gold Mastercard Credit Card (AU)
					$aIINList[1555]=540758 ;- MBNA Bank UK bmi Blue Mastercard
					$aIINList[1556]=540801 ;- Household Bank USA MasterCard Credit Card
					$aIINList[1557]=540805 ;- Citibank Taiwan
					$aIINList[1558]=540806 ;- Hang Seng Bank Credit Card
					$aIINList[1559]=540838 ;- BOC Great Wall Credit Card (CN)
					$aIINList[1560]=540877 ;- Bank of China Platinum MasterCard Credit Card (SG)
					$aIINList[1561]=541010 ;- Raiffeisen Zentralbank
					$aIINList[1562]=541065 ;- Citibank MC
					$aIINList[1563]=541142 ;- CIBC MasterCard (Canadian Imperial Bank of Commerce) formerly Citi MasterCard Canada
					$aIINList[1564]=541206 ;- USAA
					$aIINList[1565]=541256 ;- SEB Kort AB, Choice Club credit card (SE)
					$aIINList[1566]=541256 ;- SEB Kort AB, SJ Prio credit card (SE)
					$aIINList[1567]=541277 ;- Nordea Finance/Valutakortet Valuta MasterCard credit card (SE)
					$aIINList[1568]=541330 ;- Mastercard test BIN for NIV, TIP certifiction (not production cards)
					$aIINList[1569]=541383 ;- OCBC Singapore Worldcard
					$aIINList[1570]=541590 ;- Royal Bank Mastercard
					$aIINList[1571]=541592 ;- Neteller (UK) Mastercard debit card
					$aIINList[1572]=541597 ;- Slovenská sporiteľna Mastercard debit card
					$aIINList[1573]=541606 ;- WestJet/RBC Royal Bank of Canada MasterCard (CA)
					$aIINList[1574]=541647 ;- Asda branded MasterCard Credit Card (UK), discontinued 2012
					$aIINList[1575]=541657 ;- (eBay MasterCard) via Providian
					$aIINList[1576]=538670 ;- R. RAPHAEL & SONS PLC | DEBIT | Prepaid | Italy
					$aIINList[1577]=542418 ;- Citibank Platinum Select
					$aIINList[1578]=542432 ;- Fifth Third Bank MasterCard Debit Card
					$aIINList[1579]=542505 ;- RBS Gold Mastercard Credit Card (formerly ABN Amro Bank) (IN)
					$aIINList[1580]=542523 ;- Allied Irish Banks MasterCard Credit Card (IE)
					$aIINList[1581]=542542 ;- GE Money Bank Mastercard debit card (SE)
					$aIINList[1582]=542542 ;- GE Money Bank Mastercard credit card (SE)
					$aIINList[1583]=542598 ;- Bank of Ireland Post Office Platinum Card (UK)
					$aIINList[1584]=543034 ;- Stockmann Department Store Exclusive Mastercard, issued by Nordea (FI)
					$aIINList[1585]=543077 ;- Handelsbanken Business Mastercard (SE)
					$aIINList[1586]=543122 ;- HSBC issued Mastercard (HK)
					$aIINList[1587]=543250 ;- Bank of New Zealand MasterCard Credit Card
					$aIINList[1588]=543256 ;- National Bank of Bahrain, Mastercard Giftcard
					$aIINList[1589]=543267 ;- Bank of Ireland MasterCard Credit Card
					$aIINList[1590]=543328 ;- HSBC Credit USA
					$aIINList[1591]=543429 ;- Halifax 'One' Mastercard
					$aIINList[1592]=543458 ;- HSBC UK Premier Credit Card
					$aIINList[1593]=543460 ;- HSBC Mastercard Credit Card (UK)
					$aIINList[1594]=543478 ;- National Irish Bank Mastercard
					$aIINList[1595]=543479 ;- National Irish Bank Gold Mastercard
					$aIINList[1596]=543482 ;- RBS Mastercard Credit Card
					$aIINList[1597]=543556 ;- NatWest Mastercard Charge Card
					$aIINList[1598]=543568 ;- Bankwest Lite Mastercard Credit Card
					$aIINList[1599]=543678 ;- Westpac New Zealand Mastercard Gold Credit Card
					$aIINList[1600]=543696 ;- Itau Mastercard Credit Card
					$aIINList[1601]=543699 ;- NatWest MasterCard Gold Credit Card
					$aIINList[1602]=543778 ;- MasterCard Credit Card ;- issued by Zagrebačka banka, Croatia (UniCredit Group)
					$aIINList[1603]=543793 ;- St George Bank Credit Card (AU)
					$aIINList[1604]=533997 ;- ATB Financial
					$aIINList[1605]=544014 ;- Citibank Gold Credit Card (Argentina)
					$aIINList[1606]=544047 ;- Shazam (USA)
					$aIINList[1607]=544156 ;- Allied Irish Banks Gold MasterCard Credit Card
					$aIINList[1608]=544258 ;- BRE Bank (MultiBank) Mastercard Aquarius PayPass Credit Card (Black) (PL)
					$aIINList[1609]=544291 ;- Kiwibank Go Fly MasterCard Standard (NZ)
					$aIINList[1610]=544434 ;- Wizard Clear Advantage MasterCard (AU)
					$aIINList[1611]=544440 ;- Valovis Bank, Prepaid MasterCard Debit(DE)
					$aIINList[1612]=544448 ;- Boeing Employee Credit Union Debit
					$aIINList[1613]=544602 ;- People's United Bank MasterMoney Debit Card
					$aIINList[1614]=544637 ;- Coles Myer Mastercard Credit Card (AU)
					$aIINList[1615]=544748 ;- Chase SLATE MasterCard Credit Card
					$aIINList[1616]=544758 ;- HSBC Philippines Mastercard Credit Card (PH)
					$aIINList[1617]=544842 ;- MasterCard, USA
					$aIINList[1618]=544856 ;- GE Retail Bank Prepaid (USA)
					$aIINList[1619]=544917 ;- Citizens Bank (Personal Checking) Debit
					$aIINList[1620]=544927 ;- Keybank, Electron Mastercard Debit
					$aIINList[1621]=545045 ;- Danske Bank Intercard MasterCard debit card (SE)
					$aIINList[1622]=545114 ;- SEB KORT Danmark Credit Card
					$aIINList[1623]=545139 ;- Nordea Bank Danmark Credit Card
					$aIINList[1624]=545157 ;- Masterbank (Russia), MasterCard World Signia
					$aIINList[1625]=545229 ;- Bank of East Asia Hong Kong
					$aIINList[1626]=545250 ;- Maestro (debit card) BZWBK Poland
					$aIINList[1627]=545460 ;- Natwest Student Mastercard (UK)
					$aIINList[1628]=545511 ;- Masterbank (Russia) MasterCard Gold Debit Card
					$aIINList[1629]=545578 ;- Halifax MasterCard (UK)
					$aIINList[1630]=545709 ;- Commercial bank Privatbank
					$aIINList[1631]=545955 ;- Mascoma Savings Bank Mastercard Consumer Debit Card
					$aIINList[1632]=546097 ;- Luma MasterCard Credit Card by Capital One (UK)
					$aIINList[1633]=546259 ;- The Governor And Company Of The Bank Of Ireland EUR IRL DUBLIN 2
					$aIINList[1634]=546286 ;- Dexia banka Slovensko,a.s.; MasterCard Red with PayPass technology
					$aIINList[1635]=546405 ;- MidCountry Bank Debit Card (US)
					$aIINList[1636]=546540 ;- Suntrust Bank Mastercard Credit/Debit
					$aIINList[1637]=546528 ;- USAA Federal Savings Bank Master Card Credit/Debit Card
					$aIINList[1638]=546638 ;- Barclaycard US Airways Premier Word Credit Card
					$aIINList[1639]=546604 ;- First USA Banke, N.A. Master Card
					$aIINList[1640]=546616 ;- Wells Fargo Bank
					$aIINList[1641]=546632 ;- Fidelity 529 College Rewards (FIA Card Services)
					$aIINList[1642]=546641 ;- HSBC GM MasterCard Credit Card
					$aIINList[1643]=546680 ;- HSBC GM MasterCard Credit Card
					$aIINList[1644]=546827 ;- ANZ Mastercard
					$aIINList[1645]=547046 ;- Santander Uni-k Credit Card (MX)
					$aIINList[1646]=547343 ;- ANZ Business MasterCard (NZ)
					$aIINList[1647]=547347 ;- HSBC Commercial Card (UK in £)
					$aIINList[1648]=547356 ;- RBS Royal Bank of Scotland
					$aIINList[1649]=547367 ;- NatWest (RBS)
					$aIINList[1650]=547372 ;- Swedbank, Estonia, MasterCard Business Card
					$aIINList[1651]=548009 ;- Fifth Third Bank
					$aIINList[1652]=548045 ;- BANCO BRADESCO S.A. (BR)
					$aIINList[1653]=548280 ;- Prepaid Card(card level), Master card(card brand), Debit(card type), peoples trust company (CA)
					$aIINList[1654]=548616 ;- DZ Bank / BBBank (DE)
					$aIINList[1655]=548652 ;- Banco de Chile Master Card Credit Card
					$aIINList[1656]=548653 ;- Banco de Chile Master Card Credit Card RUA
					$aIINList[1657]=548673 ;- Alfa-Bank/Aeroflot-bonus, M-Video bonus debit Card (RU)
					$aIINList[1658]=548674 ;- Alfa-Bank Credit Card (RU)
					$aIINList[1659]=548696 ;- DZ-Bank / Volksbank and Raiffeisenbank (DE)
					$aIINList[1660]=548805 ;- Hatton National Bank, Sri Lanka RUA
					$aIINList[1661]=548901 ;- Banco Santander MasterCard debit card (ES)
					$aIINList[1662]=548912 ;- Banco Santander MasterCard debit card (ES)
					$aIINList[1663]=548913 ;- Open Bank S.A.(Santander Group) MasterCard debit (ES)
					$aIINList[1664]=548955 ;- HOUSEHOLD BANK (NEVADA), N.A, (Orchard Bank M/C, HSBC Card Services) RUA
					$aIINList[1665]=548960 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1666]=548961 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1667]=548962 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1668]=548963 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1669]=548964 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1670]=548965 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1671]=548966 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1672]=548967 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1673]=548968 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1674]=548969 ;- Industrial and Commercial Bank of China (ICBC) Peony American Express Gold Card China
					$aIINList[1675]=549035 ;- MBNA American Bank [Now part of Bank of America]
					$aIINList[1676]=549099 ;- MBNA American Bank [Now part of Bank of America]
					$aIINList[1677]=549104 ;- Chase Manhattan Bank USA, N.A.
					$aIINList[1678]=549110 ;- HSBC Bank Nevada, N.A. issued Household Bank Platinum Mastercard
					$aIINList[1679]=549113 ;- Citibank MC
					$aIINList[1680]=549123 ;- USAA Federal Savings Bank Platinum
					$aIINList[1681]=549191 ;- MBNA Canada Mastercard
					$aIINList[1682]=549198 ;- MBNA Canada Mastercard (CA)
					$aIINList[1683]=549409 ;- HSBC Bank Nevada, NA Premier World Mastercard (credit card)
					$aIINList[1684]=549471 ;- Qantas Woolworths Everyday Mastercard (issued by HSBC)
					$aIINList[1685]=549945 ;- Union Plus serviced by Capital One ;- formerly HSBC
					$aIINList[1686]=550018 ;- MasterCard Credit Card issued in Switzerland by Viseca Card Service SA
					$aIINList[1687]=550619 ;- "Skycard" MasterCard Credit Card issued in UK in association with Barclaycard
					$aIINList[1688]=550800 ;- Finserv
					$aIINList[1689]=550988 ;- County National Bank Debit Card issued in South Central Michigan, USA
					$aIINList[1690]=551128 ;- ITS Bank/SHAZAM (Interbank Network) Mastercard USA unclear if Debit or Credit
					$aIINList[1691]=551167 ;- ITS Bank/SHAZAM (Interbank Network) Mastercard USA unclear if Debit or Credit
					$aIINList[1692]=551445 ;- Cambridge Trust Company in Massachusetts, USA
					$aIINList[1693]=551915 ;- Orange County's Credit Union Debit Master Card
					$aIINList[1694]=552004 ;- Citibank (HK)
					$aIINList[1695]=552016 ;- Bank of China International MasterCard Platinum (HK)
					$aIINList[1696]=552033 ;- Commonwealth Bank Platinum Awards MasterCard Credit Card
					$aIINList[1697]=552038 ;- POSB (DBS Bank) everyday Platinum MasterCard Credit Card
					$aIINList[1698]=552060 ;- Citibank Mastercard Credit Card (AU)
					$aIINList[1699]=552068 ;- Royal Bank of Scotland | RBS
					$aIINList[1700]=552083 ;- Standard Chartered (HK)
					$aIINList[1701]=552093 ;- Citibank Mastercard Platinum Credit Card (IN)
					$aIINList[1702]=552157 ;- Lloyds TSB Platinum Mastercard
					$aIINList[1703]=552188 ;- Tesco Bank Finest Platinum Mastercard (UK)
					$aIINList[1704]=552213 ;- NatWest Platinum Mastercard
					$aIINList[1705]=552396 ;- MBNA Smart Cash World MasterCard (CA)(MBNA is a division of The Toronto-Dominion Bank)
					$aIINList[1706]=552313 ;- USAA World Mastercard
					$aIINList[1707]=552350 ;- Commonwealth Bank Diamond Awards MasterCard Credit Card
					$aIINList[1708]=552415 ;- Citibank (HK)
					$aIINList[1709]=552724 ;- Danske Bank MasterCard Direkt debit card (SE)
					$aIINList[1710]=553412 ;- Hooroo Pty Ltd/GE Capital Virtual Credit Card
					$aIINList[1711]=553421 ;- Bank of Scotland Mastercard
					$aIINList[1712]=553823 ;- MIT Federal Credit Union Debit Mastercard
					$aIINList[1713]=553877 ;- Star Processing PrePaid Mastercard
					$aIINList[1714]=553985 ;- First National Bank in Edinburg (US)
					$aIINList[1715]=554219 ;- CitiBank China Rewards (US Dollars Card)
					$aIINList[1716]=554346 ;- Kookmin Bank Mastercard "Free Pass" Debit Card
					$aIINList[1717]=554386 ;- VTB24 Mastercard Credit Card (RU)
					$aIINList[1718]=554390 ;- Banco Santanader MasterCard Credit Card
					$aIINList[1719]=554393 ;- VTB24 Mastercard Credit Card (RU)
					$aIINList[1720]=554544 ;- Bank of Ireland (IE)
					$aIINList[1721]=554564 ;- Onyxcard39
					$aIINList[1722]=554567 ;- BC Card
					$aIINList[1723]=554619 ;- Citibank Mastercard Silver Credit Card (IN)
					$aIINList[1724]=554641 ;- Euro Kartensysteme Eurocard und Eurocheque gmbh
					$aIINList[1725]=554704 ;- Maybank Singapore Worldcard
					$aIINList[1726]=554827 ;- POSBank MasterCard Debit Card (SG)
					$aIINList[1727]=555003 ;- Westpac Banking Corporation Mastercard (AU)
					$aIINList[1728]=555005 ;- Commonwealth Bank of Australia Corporate Mastercard (AU)
					$aIINList[1729]=555045 ;- Citibank International Plc, Mastercard (UK)
					$aIINList[1730]=556951 ;- NatWest Bank Mastercard (UK)
					$aIINList[1731]=557071 ;- MinBank MasterCard Debit Card (RU)
					$aIINList[1732]=557098 ;- Aqua Card Mastercard (UK)
					$aIINList[1733]=557100 ;- UkrSibBank (UA) Part of BNP Paribas Group
					$aIINList[1734]=557101 ;- UkrSibBank (UA) Part of BNP Paribas Group
					$aIINList[1735]=557199 ;- MB Financial Bank (US)
					$aIINList[1736]=557300 ;- Metro Bank (UK) MasterCard Debit Card
					$aIINList[1737]=557360 ;- Metro Bank Mastercard
					$aIINList[1738]=557370 ;- CUSO Ireland Mastercard ;- Credit Union Card
					$aIINList[1739]=557505 ;- Bank Handlowy Mastercard Electronic Pay Pass (Karta Miejska) Debit Card (PL)
					$aIINList[1740]=557510 ;- BRE Bank (MultiBank) Mastercard Aquarius PayPass Debit Card (PL)
					$aIINList[1741]=557513 ;- BRE Bank (MultiBank) Mastercard PayPass Debit Card (PL)
					$aIINList[1742]=557552 ;- Ally Bank Platinum Debit Card
					$aIINList[1743]=557615 ;- Bremer Bank Debit Card
					$aIINList[1744]=557753 ;- Bank of the Philippine Islands Express Cash Mastercard Electronic Card (Philippines)
					$aIINList[1745]=557890 ;- Česká spořitelna, a.s. (CZ)
					$aIINList[1746]=557843 ;- "Goldfish" MasterCard Credit Card issued in UK by Morgan Stanley
					$aIINList[1747]=557892 ;- MasterCard Credit Card issued in Nordea Denmark
					$aIINList[1748]=557905 ;- Santander Mexico Debit Card
					$aIINList[1749]=557907 ;- Santander Mexico Debit Card
					$aIINList[1750]=557975 ;- payzone worldwide money Pre-paid Mastercard (UK/IE) (issued by Banque Invik SA, Luxembourg)
					$aIINList[1751]=558108 ;- Citizens Bank (Business Checking) Debit
					$aIINList[1752]=558158 ;- PayPal (USA) Debit MasterCard BusinessCard, The Bancorp Bank
					$aIINList[1753]=558250 ;- Chase Business ink MasterCard
					$aIINList[1754]=558346 ;- Bank of Montreal Mastercard
					$aIINList[1755]=558424 ;- PrivatBank MasterCard "Corporate" (UA)
					$aIINList[1756]=558818 ;- HDFC Bank MasterCard Credit Card "Business Platinum" India
					$aIINList[1757]=558846 ;- FIA
					$aIINList[1758]=559139 ;- Citibank China Premiermiles (US Dollars Card)
					$aIINList[1759]=559318 ;- Aeon Hong Kong Ferrari World Master Card
					$aIINList[1760]=516390 ;- Westpac Australia Classic MasterCard
					$aIINList[1761]=516391 ;- Westpac Australia Classic MasterCard
					$aIINList[1762]=516392 ;- Westpac Australia Classic MasterCard
					$aIINList[1763]=516393 ;- Westpac Australia Classic MasterCard
					$aIINList[1764]=516394 ;- Westpac Australia Classic MasterCard
					$aIINList[1765]=516395 ;- Westpac Australia Classic MasterCard
					$aIINList[1766]=516396 ;- Westpac Australia Classic MasterCard
					$aIINList[1767]=516397 ;- Westpac Australia Classic MasterCard
					$aIINList[1768]=516398 ;- Westpac Australia Classic MasterCard
					$aIINList[1769]=516399 ;- Westpac Australia Classic MasterCard
					$aIINList[1770]=545461 ;- Natwest Student Mastercard (UK)
					$aIINList[1771]=545462 ;- Natwest Student Mastercard (UK)
					$aIINList[1772]=545463 ;- Natwest Student Mastercard (UK)
					$aIINList[1773]=545464 ;- Natwest Student Mastercard (UK)
					$aIINList[1774]=545465 ;- Natwest Student Mastercard (UK)
					$aIINList[1775]=545466 ;- Natwest Student Mastercard (UK)
					$aIINList[1776]=545467 ;- Natwest Student Mastercard (UK)
					$aIINList[1777]=545468 ;- Natwest Student Mastercard (UK)
					$aIINList[1778]=545469 ;- Natwest Student Mastercard (UK)
				Case 4
					Local $aIINList[101]
					$aIINList[0]=5108 ;- INGDirect	Electric Orange Debit Card
					$aIINList[1]=5122 ;- First Gulf Bank
					$aIINList[2]=5130 ;- Banque Postale (France)
					$aIINList[3]=5131 ;- Crédit Agricole
					$aIINList[4]=5134 ;- HSBC -Credit Card
					$aIINList[5]=5135 ;- BRED Banque Populaire MasterCard Credit Card
					$aIINList[6]=5141 ;- Banco Popular North America Mastercard Debit Card
					$aIINList[7]=5148 ;- US Airways Dividend Miles Platinum MasterCard
					$aIINList[8]=5149 ;- MetaBank MasterCard FSA debit card (issued on behalf of third-party administrators)
					$aIINList[9]=5151 ;- OboPay Prepaid Debit Card Issued By First Premier
					$aIINList[10]=5155 ;- Orchard Bank issued by HSBC
					$aIINList[11]=5156 ;- BestBuy MasterCard issued by HSBC
					$aIINList[12]=5176 ;- China Minsheng Bank MasterCard Credit Card
					$aIINList[13]=5177 ;- BANAMEX Debit Card
					$aIINList[14]=5179 ;- Bank Atlantic Mastercard Debit Card
					$aIINList[15]=5182 ;- Banco Nacional de Costa Rica Servibanca Debit Card
					$aIINList[16]=5185 ;- HONGKONG AND SHANGHAI BANKING CORPORATION, LTD., THE MasterCard (HK)
					$aIINList[17]=5187 ;- China Merchants Bank MasterCard Credit Card
					$aIINList[18]=5200 ;- MBNA Quantum MasterCard Credit Card
					$aIINList[19]=5206 ;- Caixa Geral de Depotios (CGD) (Portugal) (Caixa Pro Master Card)
					$aIINList[20]=5217 ;- Commonwealth Bank of Australia Debit MasterCard
					$aIINList[21]=5211 ;- Privatbank (UA)
					$aIINList[22]=5221 ;- MasterCard Credit Cards in South Africa
					$aIINList[23]=5228 ;- Presidents Choice MasterCard Credit Card
					$aIINList[24]=5232 ;- Sparkasse Germany MasterCard Credit Card
					$aIINList[25]=5234 ;- Lufthansa Miles & More MasterCard Credit Card
					$aIINList[26]=5236 ;- AirBank MasterCard Debit Card
					$aIINList[27]=5243 ;- Hudson's Bay Company MasterCard Credit Card (Canada)
					$aIINList[28]=5255 ;- Mastercard CartaSi (Italy)
					$aIINList[29]=5256 ;- Sparda-Bank MasterCard Charge Card (Germany)
					$aIINList[30]=5258 ;- Mastercard National Bank of Canada (Canada)
					$aIINList[31]=5259 ;- Canadian Tire Bank Cash Advantage Platinum MasterCard
					$aIINList[32]=5262 ;- Citibank MasterCard Debit Card
					$aIINList[33]=5264 ;- Bank Negara Indonesia MasterCard Debit Card
					$aIINList[34]=5268 ;- Landesbank Berlin (Germany) MasterCard Credit Card
					$aIINList[35]=5268 ;- CitiBank Platinum Enrich (Canada) MasterCard Credit Card
					$aIINList[36]=5275 ;- Danske Bank (Finland) MasterCard Debit Card
					$aIINList[37]=5286 ;- Santander Cards
					$aIINList[38]=5286 ;- ABSA (Amalgamated Banks of South Africa) MasterCard Credit Card
					$aIINList[39]=5286 ;- Virgin Money South Africa (Virtual Bank; Operates partially on ABSA's system)
					$aIINList[40]=5287 ;- Washington Mutual Bank Debit card
					$aIINList[41]=5289 ;- ANZ (Previously RBS and ABN AMRO) Switch Platinum MasterCard Credit Card (Singapore)
					$aIINList[42]=5300 ;- Bay Bank.
					$aIINList[43]=5301 ;- BarclayCard Mastercards.
					$aIINList[44]=5303 ;- BAC San José (Costa Rica) Debit card
					$aIINList[45]=5310 ;- Lufthansa Miles & More MasterCard Credit Card Frequent Traveler
					$aIINList[46]=5316 ;- CUETS Financial Canada MasterCard Credit Card
					$aIINList[47]=5317 ;- CUETS Financial Canada Global Payment MasterCard
					$aIINList[48]=5322 ;- Washington Mutual Business Debit card
					$aIINList[49]=5326 ;- Isracard MasterCard Credit Card (IL)
					$aIINList[50]=5327 ;- Dexia banka Slovensko, a.s.; MasterCard credit PayPass
					$aIINList[51]=5329 ;- MBNA Preferred MasterCard Credit Card
					$aIINList[52]=5396 ;- Saks Fifth Avenue World Elite MasterCard issued by HSBC
					$aIINList[53]=5399 ;- ICICI Bank MasterCard debit Card
					$aIINList[54]=5401 ;- Bank of America (formerly MBNA) MasterCard Gold Credit Card
					$aIINList[55]=5403 ;- Citibank MasterCard Credit Card ("Virtual Card" number)
					$aIINList[56]=5404 ;- Lloyds TSB Bank MasterCard Credit Card
					$aIINList[57]=5406 ;- Bancolombia MasterCard Credit Card (CO)
					$aIINList[58]=5407 ;- HSBC Bank GM Card
					$aIINList[59]=5409 ;- HSBC Bank, Union Bank of California Pay Pass debit card
					$aIINList[60]=5412 ;- HSBC Malaysia issued Mastercard
					$aIINList[61]=5416 ;- Washington Mutual (formerly Providian) Platinum MasterCard Credit Card
					$aIINList[62]=5417 ;- Chase Bank
					$aIINList[63]=5420 ;- MasterCard issued by USAA, Mastercard issued by John Lewis (Partnership Card)
					$aIINList[64]=5424 ;- Citibank MasterCard Credit Card (Dividend, Diamond and others)
					$aIINList[65]=5425 ;- Barclaycard MasterCard Credit Card (DE)
					$aIINList[66]=5426 ;- Alberta Treasury Branch
					$aIINList[67]=5430 ;- ANZ Bank MasterCard
					$aIINList[68]=5430 ;- Stockmann Department Store Mastercard, issued by Nordea (FI)
					$aIINList[69]=5434 ;- MasterCard credit cards from UK and Irish banks
					$aIINList[70]=5438 ;- USAA Federal Savings Bank
					$aIINList[71]=5440 ;- Mastercard from MBF Malaysia
					$aIINList[72]=5442 ;- HSBC Mastercard Credit Card (SG)
					$aIINList[73]=5443 ;- HSBC MasterCard Debit Card with PayPass (US)
					$aIINList[74]=5444 ;- Bangkok Bank (TH)
					$aIINList[75]=5444 ;- BHW MasterCard Charge Card (DE)
					$aIINList[76]=5446 ;- Canadian Tire MasterCard Credit Card
					$aIINList[77]=5451 ;- NatWest Mastercard Credit Card
					$aIINList[78]=5452 ;- MBNA Canada Mastercard
					$aIINList[79]=5455 ;- BancorpSouth Mastercard MasterMoney Debit Card
					$aIINList[80]=5457 ;- Capital One Canada Branch
					$aIINList[81]=5457 ;- Dexia banka Slovensko, a.s.; Mastercard Gold with PayPass technology
					$aIINList[82]=5458 ;- USAA Credit Card
					$aIINList[83]=5459 ;- Harris Bank Debit Card
					$aIINList[84]=5460 ;- Berliner Bank (Germany),Mint MasterCard Credit Card and Capital One UK
					$aIINList[85]=5466 ;- Citibank, MBNA & Chase World MasterCard Credit Cards,
					$aIINList[86]=5469 ;- Sberbank of Russia
					$aIINList[87]=5471 ;- Davivienda MasterCard Credit Card (CO)
					$aIINList[88]=5474 ;- Wells Fargo Bank BusinessLine credit card (US)
					$aIINList[89]=5483 ;- HypoVereinsbank (DE)
					$aIINList[90]=5490 ;- MBNA & Chase Platinum MasterCard Credit Cards
					$aIINList[91]=5491 ;- AT&T Universal MasterCard Credit Card, now part of Citibank, also MBNA MasterCard Credit Cards
					$aIINList[92]=5520 ;- DBS POSB Everyday Platinum Mastercard (Singapore) / Bank of Scotland Private Banking Platinum MasterCard / RBS World Mastercard
					$aIINList[93]=5521 ;- BC Platinum Mastercard
					$aIINList[94]=5522 ;- NatWest Platinum Mastercard
					$aIINList[95]=5524 ;- BMO Bank Of Montreal World Elite MasterCard (CA)
					$aIINList[96]=5528 ;- Diner's Club
					$aIINList[97]=5533 ;- Standard Chartered (HK)
					$aIINList[98]=5588 ;- Citibank MasterCard Credit Card "Business"
					$aIINList[99]=5049	;- US	CitiBank	Sears Card
					$aIINList[100]=5077	;- US		Maestro EBT Card
			EndSwitch
		Case 6 ;Discover
			Switch $Length
				Case 6
					Local $aIINList[4]
					$aIINList[0]=601131 ;- Walmart Discover Card Credit Card
					$aIINList[1]=601136 ;- Sam's Discover Card Credit Card
					$aIINList[2]=601137 ;- Sam's Business Discover Card Credit Card
					$aIINList[3]=601138 ;- HSBC - Direct Rewards Credit Card
				Case 4
					Local $aIINList[3]
					$aIINList[0]=6011 ;- Discover Card Credit Card
					$aIINList[1]=6541 ;- KR	BC Card	BC Global[1]
					$aIINList[2]=6556 ;- KR	BC Card	BC Global[1]
			EndSwitch
	EndSwitch

	Return $aIINList
EndFunc

;#######################################################################
;		MSSQLPreMatch - $aColumn  Name|Type|Length
;-----------------------------------------------------------------------
Func MSSQLPreMatch($DataBase,$Table,$aColumn,$oADODB=-1)
	Local $sQuery
	$SQLErr=""
	If $oADODB=-1 Then $oADODB=$SQL_LastConnection
	If Not IsObj($oADODB) Then
		$SQLErr="Invalid ADODB.Connection object"
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	_SQL_Execute($oADODB,'USE '&$DataBase&';'&"SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;")
	_SQL_Execute($oADODB,"IF (EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME "& _
						"LIKE '#dataloc%')) BEGIN DROP TABLE #dataloc END;")

	If $aColumn[2]="-1" Then $aColumn[2]="MAX"
	Switch StringLower($aColumn[1])
		Case "text"
			$aColumn[2]="MAX"
			$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" VARCHAR('&$aColumn[2]&'));'
		Case "ntext"
			$aColumn[2]="MAX"
			$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" NVARCHAR('&$aColumn[2]&'));'
		Case "numeric","decimal","dec"
			$aColumn[2]="38"
			$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&'('&$aColumn[2]&'));'
		Case Else
			$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&'('&$aColumn[2]&'));'
	EndSwitch

	_SQL_Execute($oADODB,$sQuery) ;Create temp table

	Local $sSelectColumn
	Switch StringLower($aColumn[1])
		Case "text"
			$sSelectColumn='LEFT(CAST("'&$aColumn[0]&'" as VARCHAR(MAX)), 20000)'
		Case "ntext"
			$sSelectColumn='LEFT(CAST("'&$aColumn[0]&'" as NVARCHAR(MAX)), 20000)'
		Case Else
			If $aColumn[2]="MAX" Or $aColumn[2] > 20000 Then
				$sSelectColumn='LEFT("'&$aColumn[0]&'", 20000)'
			Else
				$sSelectColumn='"'&$aColumn[0]&'"'
			EndIf
	EndSwitch
	$sQuery='INSERT INTO #dataloc '& _
	'Select '&$sSelectColumn&' FROM '&$Table&' WHERE "'&$aColumn[0]&'" LIKE '& _ ;VISA starts with 4 Len=16
	"('%4%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%') "& _
	'UNION Select '&$sSelectColumn&' FROM '&$Table&' WHERE "'&$aColumn[0]&'" LIKE '& _ ;MasterCard (51-55) Len=16
	"('%5%[1-5]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%') "& _
	'UNION Select '&$sSelectColumn&' FROM '&$Table&' WHERE "'&$aColumn[0]&'" LIKE '& _ ;Amex Starts with 34 OR 37 Len=15
	"('%3%[47]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%') "& _
	'UNION Select '&$sSelectColumn&' FROM '&$Table&' WHERE "'&$aColumn[0]&'" LIKE '& _ ;Discover 6011 OR 65 Len=16
	"('%6%[05]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%[0-9]%')"
	_SQL_Execute($oADODB,$sQuery) ;Populate temp table
EndFunc

;#######################################################################
;		GetExcludes - returns an array of items for exclusion.  Array[0]=row count
;-----------------------------------------------------------------------
Func GetExcludes($Type) ;Alphabetical order for binary search
	Switch $Type
		Case "Databases"
			Local $ExcludeList[10]
			$ExcludeList[0]=9
			$ExcludeList[1]="distribution"
			$ExcludeList[2]="master"
			$ExcludeList[3]="model"
			$ExcludeList[4]="msdb"
			$ExcludeList[5]="publication"
			$ExcludeList[6]="reportserver"
			$ExcludeList[7]="reportservertempdb"
			$ExcludeList[8]="resource"
			$ExcludeList[9]="tempdb"
		Case "Tables"
			Local $ExcludeList[18]
			$ExcludeList[0]= 17
			$ExcludeList[1]="syscolumns"
			$ExcludeList[2]="syscomments"
			$ExcludeList[3]="sysconstraints"
			$ExcludeList[4]="sysdepends"
			$ExcludeList[5]="sysfilegroups"
			$ExcludeList[6]="sysfiles"
			$ExcludeList[7]="sysforeignkeys"
			$ExcludeList[8]="sysfulltextcatalogs"
			$ExcludeList[9]="sysindexes"
			$ExcludeList[10]="sysindexkeys"
			$ExcludeList[11]="sysmembers"
			$ExcludeList[12]="sysobjects"
			$ExcludeList[13]="syspermissions"
			$ExcludeList[14]="sysprotects"
			$ExcludeList[15]="sysreferences"
			$ExcludeList[16]="systypes"
			$ExcludeList[17]="sysusers"
		Case "DataTypes"
			Local $ExcludeList[27]
			$ExcludeList[0] = 26
			$ExcludeList[1] = "bigint"
			$ExcludeList[2] = "binary"
			$ExcludeList[3] = "bit"
			$ExcludeList[4] = "cursor"
			$ExcludeList[5] = "date"
			$ExcludeList[6] = "datetime"
			$ExcludeList[7] = "datetime2"
			$ExcludeList[8] = "datetimeoffset"
			$ExcludeList[9] = "float"
			$ExcludeList[10] = "geography"
			$ExcludeList[11] = "hierarchyid"
			$ExcludeList[12] = "image"
			$ExcludeList[13] = "int"
			$ExcludeList[14] = "money"
			$ExcludeList[15] = "real"
			$ExcludeList[16] = "smalldatetime"
			$ExcludeList[17] = "smallint"
			$ExcludeList[18] = "smallmoney"
			$ExcludeList[19] = "sql_variant"
			$ExcludeList[20] = "table"
			$ExcludeList[21] = "time"
			$ExcludeList[22] = "timestamp"
			$ExcludeList[23] = "tinyint"
			$ExcludeList[24] = "uniqueidentifier"
			$ExcludeList[25] = "varbinary"
			$ExcludeList[26] = "xml"
	EndSwitch
	Return $ExcludeList
EndFunc

;#######################################################################
;		_SQL_ConnectionTimeout -
;-----------------------------------------------------------------------
Func _SQL_ConnectionTimeout($ADODBHandle=-1,$iTimeOut=0)
    $SQLErr=""
     If $ADODBHandle=-1 Then $ADODBHandle=$SQL_LastConnection
    If Not IsObj($ADODBHandle) Then
        $SQLErr="Invalid ADODB.Connection object"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	If $iTimeOut="" then Return SetError($SQL_OK,0,$ADODBHandle.ConnectionTimeout)
	If NOT isInt($iTimeOut) then
		$SQLErr="ConnectionTimeOut value must be an integer"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	$ADODBHandle.ConnectionTimeout=$iTimeOut
	Return SetError($SQL_OK,0,$ADODBHandle.ConnectionTimeout)
EndFunc

;#######################################################################
;		_SQL_CommandTimeout -
;-----------------------------------------------------------------------
Func _SQL_CommandTimeout($ADODBHandle=-1,$iTimeOut=0)
    $SQLErr=""
     If $ADODBHandle=-1 Then $ADODBHandle=$SQL_LastConnection
    If Not IsObj($ADODBHandle) Then
        $SQLErr="Invalid ADODB.Connection object"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	If $iTimeOut="" then Return SetError($SQL_OK,0,$ADODBHandle.CommandTimeout)
	If NOT isInt($iTimeOut) then
		$SQLErr="CommandTimeOut value must be an integer"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
	$ADODBHandle.CommandTimeout=$iTimeOut
	Return SetError($SQL_OK,0,$ADODBHandle.CommandTimeout)
EndFunc

;#######################################################################
;		_SQL_Execute -
;-----------------------------------------------------------------------
Func _SQL_Execute($oADODB=-1,$vQuery="")
	FileWriteLine("sql.log",$vQuery)
    $SQLErr=""
    If $oADODB=-1 Then $oADODB=$SQL_LastConnection
    Local $hQuery=$oADODB.Execute($vQuery)
    If @error Then
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
    Else
        Return SetError($SQL_OK,0,$hQuery)
    EndIf
EndFunc

;#######################################################################
;		_SQL_GetData2D - returns 2D array containing query results
;-----------------------------------------------------------------------
Func _SQL_GetData2D($oADODB, $vQuery, ByRef $aResult, ByRef $iRows, ByRef $iColumns)
    $SQLErr=""
    Local $i,$x,$y,$objquery
    $iRows=0
    $iColumns=0
    $objquery=_SQL_Execute($oADODB,$vQuery)
    If @error Then
        $SQLErr="Query Error"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
    EndIf
    If $objquery.eof Then
        $SQLErr="Query has no data"
        $objquery=0
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
    EndIf
    With $objquery
        $aResult=.GetRows()
        If IsArray($aResult) Then
            $iColumns=UBound($aResult,2)
            $iRows=UBound($aResult)
            ReDim $aResult[$iRows+1][$iColumns]

            For $x=$iRows To 1 Step -1
                For $y=0 To $iColumns-1
                    $aResult[$x][$y]=$aResult[$x-1][$y]
                Next
            Next
            ;Add the coloumn names
            For $i = 0 To $iColumns-1
                $aResult[0][$i]=.Fields($i).Name
            Next
        Else
            $SQLErr="Unable to retreive data"
            $objquery=0
            Return SetError($SQL_ERROR,0,$SQL_ERROR)
        EndIf
    EndWith
    $objquery=0
    Return SetError($SQL_OK,0,$SQL_OK)
EndFunc

;#######################################################################
;		_SQL_Startup - opens an ADODB.Connection
;-----------------------------------------------------------------------
Func _SQL_Startup()
	$SQLErr=""
	Local $adCN=ObjCreate("ADODB.Connection")
	If IsObj($adCN)=1 Then
		$SQL_LastConnection=$adCN
		Return SetError($SQL_OK,0,$adCN)
	Else
		$SQLErr="Failed to Create ADODB.Connection object"
		Return SetError($SQL_ERROR,0,$SQL_ERROR)
	EndIf
EndFunc

;#######################################################################
;		_SQL_Close - Closes an open ADODB.Connection
;-----------------------------------------------------------------------
Func _SQL_Close($ADODBHandle=-1)
	$SQLErr=""
	If $ADODBHandle=-1 Then $ADODBHandle=$SQL_LastConnection
	;Validate DB object exists
    If IsObj($ADODBHandle)=0 Or $ADODBHandle=-1 Then ;invalid object
        $SQLErr="Invalid ADODB.Connection object, use _SQL_Startup()"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
	Else ;valid object
		$ADODBHandle.Close
		$SQL_LastConnection=-1
		Return SetError($SQL_OK,0,$SQL_OK)
    EndIf
EndFunc

;#######################################################################
;		_SQL_ErrFunc -
;-----------------------------------------------------------------------
Func SQL_ErrFunc()
	Select
		;Server does not exist or access denied
		Case StringInStr($SQLObjErr.description,"Server does not exist or access denied")
			cout("Server does not exist or access denied")
			MsgBox(0,"SQL Error","Server does not exist or access denied.",30)
		Case StringInStr($SQLObjErr.description,"Login failed for user")
			cout("Login failed for specified user.")
			MsgBox(0,"SQL Error","Login failed for specified user.",30)
		Case Else
			;Gather error details
			$SQLErr="------------------------------------"&@CRLF & _
					"err.description: "&@TAB&$SQLObjErr.description&@CRLF & _
					"err.windescription:"&@TAB&$SQLObjErr.windescription&@CRLF & _
					"err.number: "&@TAB&Hex($SQLObjErr.number,8)&@CRLF & _
					"err.lastdllerror: "&@TAB&$SQLObjErr.lastdllerror&@CRLF & _
					"err.scriptline: "&@TAB&$SQLObjErr.scriptline&@CRLF & _
					"err.source: "&@TAB&$SQLObjErr.source&@CRLF & _
					"err.helpfile: "&@TAB&$SQLObjErr.helpfile&@CRLF & _
					"err.helpcontext: "&@TAB&$SQLObjErr.helpcontext&@CRLF & _
					"------------------------------------"&@CRLF

;~ 			FileWriteLine("sql.log","SQL Error: "&$SQLErr)
			cout("SQL Error: "&$SQLErr)
			MsgBox(0,"SQL Error","SQL Error: "&$SQLErr,30)
	EndSelect
	;Reset error state
    SetError($SQL_ERROR,0,$SQLErr)
EndFunc

;#######################################################################
;		RegisterErrorHandler -
;-----------------------------------------------------------------------
Func RegisterErrorHandler($Func="SQL_ErrFunc")
    $SQLErr=""
    If ObjEvent("AutoIt.Error")="" Then
        $SQLObjErr=ObjEvent("AutoIt.Error",$Func)
        Return SetError($SQL_OK,0,$SQL_OK)
    Else
        $SQLErr="An Error Handler is already registered"
        Return SetError($SQL_ERROR,0,$SQL_ERROR)
    EndIf
EndFunc

;#######################################################################
;		Cout -
;-----------------------------------------------------------------------
Func Cout($sMSG)
	GUICtrlSetData($Input4,$sMSG)
	$sMSG_Time=_NowCalc()
EndFunc

;#######################################################################
;		_LuhnCheck - Check to see if number is Luhn valid. Must use string ""
;-----------------------------------------------------------------------
;Returns True/False
Func _LuhnCheck($s_Num)
	If IsString($s_Num) And StringIsDigit($s_Num) Then
		Local $a_Digit=StringSplit($s_Num,'')
		Local $i_Count,$i_State=0,$i_Temp,$i_CheckSum,$RetVal
		For $i_Count=$a_Digit[0] To 1 Step -1
			If $i_State Then
				$i_Temp=$a_Digit[$i_Count]*2
				If $i_Temp>9 Then
					$i_Temp=Int($i_temp/10)+mod($i_Temp,10)
				EndIf
			Else
				$i_Temp=$a_Digit[$i_Count]
			EndIf
			$i_CheckSum+=$i_Temp
			$i_State=Not $i_State
		Next
		$RetVal=Mod($i_Checksum,10)=0
		SetExtended($i_CheckSum)
		Return $RetVal
	Else
		SetError(1)
		Return 'Input "'&$s_Num&'" is not a valid numeric string'
	EndIf
EndFunc

;#######################################################################
;		GetDelimiterTypeCount - identify the number of unique delimiters
;-----------------------------------------------------------------------
Func GetDelimiterTypeCount($Delimiters)
	If StringLen($Delimiters) >= 0 Then
		Local $aDelimiters[StringLen($Delimiters)]
		For $a=0 To StringLen($Delimiters)-1
			$aDelimiters[$a]=StringMid($Delimiters,$a,1)
		Next
		$aUniqueDelimiters=_ArrayUnique(StringLower($aDelimiters))
		If Not @error Then
			Return $aUniqueDelimiters[0]
		EndIf
	EndIf
	Return 0
EndFunc