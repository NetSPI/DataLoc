#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Etc\Cake.ico
#AutoIt3Wrapper_Outfile=DataLoc_x86.exe
#AutoIt3Wrapper_Outfile_x64=DataLoc_x64.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Description=DB Data locator
#AutoIt3Wrapper_Res_Fileversion=0.1.0.54
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
Local $aOPTIONS[12],$oADODB=-1,$aListView1Items[2],$aListView2Items[2],$ListView1Last="",$ListView2Last=""
	$aOPTIONS[1]=GUICtrlRead($Input1) ;RHOST
	$aOPTIONS[4]="false"     ;WINAUTH
	$aOPTIONS[5]=GUICtrlRead($Input2) ;DBUSER
	$aOPTIONS[6]=GUICtrlRead($Input3) ;DBPASS
	$aOPTIONS[7]="*"         ;DB
	$aOPTIONS[8]="*"         ;TABLE
	$aOPTIONS[9]="*"         ;COLUMN
	$aOPTIONS[10]="cc"       ;DATATYPE
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
			$SQL_Query = 'USE '&$aOPTIONS[7]&';SELECT * FROM INFORMATION_SCHEMA.COLUMNS where '
			If $aExcludes[0]>0 Then
				$SQL_Query=$SQL_Query&"DATA_TYPE NOT IN ("
				For $a=1 To $aExcludes[0]
					$SQL_Query=$SQL_Query&"'"&$aExcludes[$a]&"',"
				Next
				$SQL_Query=StringTrimRight($SQL_Query,1)
				$SQL_Query=$SQL_Query&") AND "
			EndIf
			$SQL_Query=$SQL_Query&"TABLE_NAME='"&$aOPTIONS[8]&"' ORDER BY COLUMN_NAME;"
	EndSwitch

	;Query Database
	_SQL_GetData2D($oADODB,$SQL_Query,$aResults,$iRows,$iColumns)

	;Remove invalid items
	If $iRows>0 Then
		_ArraySort($aResults,0,1)

		;Check for min length
		If $Target="columns" Then
			Local $MinLength=15
			For $a=UBound($aResults)-1 To 1 Step -1
				If $aResults[$a][8]="" Then $aResults[$a][8]=-1
				If $aResults[$a][8]<$MinLength And $aResults[$a][8]<>-1 Then
					_ArrayDelete($aResults,$a)
				EndIf
			Next
		EndIf
	EndIf

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
								$PullCount=3000
							Case 21 To 50
								$PullCount=2000
							Case 51 To 100
								$PullCount=1500
							Case 101 To 500
								$PullCount=500
							Case 501 To 1000
								$PullCount=250
							Case Else
								$PullCount=100
						EndSwitch

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
	$aRegexPattern[1]="(?<![0-9])3\D{0,4}(4|7)(\D{0,4}\d){13}(?![0-9])"
	;Discover begin with 6011 or 65. All have 16 digits.
	$aRegexPattern[2]="(?<![0-9])6\D{0,4}(5(\D{0,4}\d){14}(\D?|$)|0\D{0,4}1\D{0,4}1(\D{0,4}\d){12}(?![0-9]))"
	;MasterCard  start with 50 through 55. 16 digits
	$aRegexPattern[3]="(?<![0-9])5\D{0,4}(0-5)(\D{0,4}\d){14}(?![0-9])"
	;Visa All cards start with 4 length is *NOT* 13-16 digits. 16 only.
	$aRegexPattern[4]="(?<![0-9])4(\D{0,4}\d){15}(?![0-9])"

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
;~ 						$aTargetData[1][3] ;Match|Confidence|OriginalCellData
						$aTargetData[0][0]+=1
						_ArrayAdd($aTargetData,$NumericMatch&"|50|"&$aPreProc[$a][1])

						;Remove extra characters resulting from not prepended or followed by a number check
						If StringIsInt(StringRight($aMatch[0],1))=0 Then StringTrimRight($aMatch[0],1)
						If StringIsInt(StringLeft($aMatch[0],1))=0 Then StringTrimLeft($aMatch[0],1)

						;Score Finding
						;Delimiters
						$aTargetData[UBound($aTargetData)-1][1]=ConfidenceDelimiters($aTargetData[UBound($aTargetData)-1][1],$aMatch[0])
						;KeyWords - Cell data and column / table names
						$aTargetData[UBound($aTargetData)-1][1]=ConfidenceKeyWords($aTargetData[UBound($aTargetData)-1][1])
						;IIN - Issuer identification number check
						$aTargetData[UBound($aTargetData)-1][1]=ConfidenceIINCheck($aTargetData[UBound($aTargetData)-1][0],$aTargetData[UBound($aTargetData)-1][1])
					EndIf
				Next
			EndIf
		Next
	Next
	Return $aTargetData
EndFunc

;#######################################################################
;		ConfidenceBINCheck - Adjust score based known issuer ID in card number
;-----------------------------------------------------------------------
;The first 6 digits of a credit card number are known as the Issuer Identification Number (IIN)
Func ConfidenceIINCheck($ExactMatch,$Score)
	Local $MatchIIN, $bMF=0, $aIINList[1]

	;6 digit checks
	$aIINList=IINGetList(StringLeft($ExactMatch,1),6)
	$MatchIIN=StringLeft($ExactMatch,6)
	For $a=0 To UBound($aIINList)-1
		If $MatchIIN=$aIINList[$a] Then
			$Score+=15
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
				$Score+=10
				$bMF=1
				ExitLoop
			EndIf
		Next
	EndIf

	;No match
	If $bMF=0 Then $Score-=10
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
			Switch $Length
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
	EndSwitch

	Return $aIINList
EndFunc


;#######################################################################
;		ConfidenceMiscTests - Adjust score based on additional patterns
;-----------------------------------------------------------------------
Func ConfidenceMiscTests($Score)
	;Cell Data
	;#.match = reduce score
	;match.### increase score
	;match.(#|##).(#|##) increase
	Return $Score
EndFunc

;#######################################################################
;		ConfidenceKeyWords - Adjust score based on Cell data and column / table names
;-----------------------------------------------------------------------
Func ConfidenceKeyWords($Score)
	;Cell Data
	;+ CVV VISA AMEX
	;- AAA
	;Table names
	;
	;Column Names
	;phone = reduce score
	;aaa = reduce score
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
				$Score+=40
			Case 1
				$Score+=35
			Case 2
				$Score+=20
			Case 3
				$Score+=10
			Case Else
				$Score+=-10
		EndSwitch
	Else
		Switch $DelimTypeCount
			Case 1
				$Score+=25
			Case 2
				$Score+=15
			Case 3
				$Score+=-10
			Case Else
				$Score+=-20
		EndSwitch
	EndIf

	Return $Score
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
	_SQL_Execute($oADODB,'USE '&$DataBase&';')
	_SQL_Execute($oADODB,"SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;")
	_SQL_Execute($oADODB,"IF (EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME "& _
						"LIKE '#dataloc%')) BEGIN DROP TABLE #dataloc END;")
	If $aColumn[2]="" Then
		$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&');'
	Else
		Switch StringLower($aColumn[1])
			Case "text"
				$aColumn[1]="VARCHAR"
				$aColumn[2]="MAX"
			Case "ntext"
				$aColumn[1]="NVARCHAR"
				$aColumn[2]="MAX"
			Case "numeric","decimal","dec"
				$aColumn[2]="38"
		EndSwitch
		If $aColumn[2]="-1" Then $aColumn[2]="MAX"
		$sQuery='CREATE TABLE #dataloc (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&'('&$aColumn[2]&'));'
	EndIf
	_SQL_Execute($oADODB,$sQuery) ;Create temp table
	Local $sSelectColumn
	Switch StringLower($aColumn[1])
		Case "text"
			$sSelectColumn='LEFT(CAST("'&$aColumn[0]&'" as VARCHAR(MAX)), 30000)'
		Case "ntext"
			$sSelectColumn='LEFT(CAST("'&$aColumn[0]&'" as NVARCHAR(MAX)), 30000)'
		Case Else
			$sSelectColumn='LEFT("'&$aColumn[0]&'", 30000)'
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