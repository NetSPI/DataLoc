#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Etc\Cake.ico
#AutoIt3Wrapper_Outfile=DataLoc_x86.exe
#AutoIt3Wrapper_Outfile_x64=DataLoc_x64.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Description=DB Data locator
#AutoIt3Wrapper_Res_Fileversion=0.1.0.51
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

						;Pre-process scan target data
						Cout("Pre-Processing: "&$aDataBases[$a]&"|"&$aTables[$b][0]&"|"&$aColumns[$c][0]&"|"&@CRLF)
						MSSQLPreMatch($aDataBases[$a],$aTables[$b][2],$aColumn)
						If StringInStr($SQLErr,"80030009") Then
							Cout("Unable to create temp table"&@CRLF)
							MsgBox(0,"SQL Error","Unable to create temp table",120)
							return ;this could use a slower method of data collection instead of just quiting
						EndIf

						;Pull remaining data over the wire for post-processing
						For $e=1 To $aTables[$b][1] Step 500 ;Loop through all records in #TempCC
							Local $sQuery="SELECT * FROM #TempCC WHERE (RowNumber >="&$e&" AND RowNumber <="&$e+499&") ORDER BY RowNumber;"
							Local $aPreProc[1][1],$iRows=0,$iColumns=0
							_SQL_GetData2D($oADODB,$sQuery,$aPreProc,$iRows,$iColumns)
							If $iRows>1 And $iColumns>1 Then
								Cout("Post-Processing: "&$aDataBases[$a]&"|"&$aTables[$b][0]&"|"&$aColumns[$c][0]&"| rows "&$e&"-"&$e+499&@CRLF)
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
						"LIKE '#TempCC%')) BEGIN DROP TABLE #TempCC END;")
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

	Local $aRegexPattern[21]
	;Autoit's Regex has it's limits
	;American Express start with 34 or 37 and have 15 digits
	$aRegexPattern[1]="[^0-9]3[^0-9a-zA-Z]{0,1}[47][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[2]="[^0-9]3[^0-9a-zA-Z]{0,1}[47][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	$aRegexPattern[3]="\A3[^0-9a-zA-Z]{0,1}[47][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[4]="\A3[^0-9a-zA-Z]{0,1}[47][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	;Visa All cards start with 4 length is *NOT* 13-16 digits. 16 only.
	$aRegexPattern[5]="[^0-9]4[^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[6]="[^0-9]4[^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	$aRegexPattern[7]="\A4[^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[8]="\A4[^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	;Discover begin with 6011 or 65. All have 16 digits.
	$aRegexPattern[9]="[^0-9]6[^0-9a-zA-Z]{0,1}0[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[10]="[^0-9]6[^0-9a-zA-Z]{0,1}0[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	$aRegexPattern[11]="\A6[^0-9a-zA-Z]{0,1}0[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[12]="\A6[^0-9a-zA-Z]{0,1}0[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}1[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	$aRegexPattern[13]="[^0-9]6[^0-9a-zA-Z]{0,1}5[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9]\Z"
	$aRegexPattern[14]="[^0-9]6[^0-9a-zA-Z]{0,1}5[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9]"
	$aRegexPattern[15]="\A6[^0-9a-zA-Z]{0,1}5[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[16]="\A6[^0-9a-zA-Z]{0,1}5[^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	;MasterCard  start with 50 through 55. 16 digits
	$aRegexPattern[17]="[^0-9]5[^0-9a-zA-Z]{0,1}[0-5][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[18]="[^0-9]5[^0-9a-zA-Z]{0,1}[0-5][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"
	$aRegexPattern[19]="\A5[^0-9a-zA-Z]{0,1}[0-5][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9]\Z"
	$aRegexPattern[20]="\A5[^0-9a-zA-Z]{0,1}[0-5][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,2}[0-9][^0-9a-zA-Z]{0,1}[0-9][^0-9]"

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
			Local $aRegexResults=StringRegExp($aPreProc[$a][1],$aRegexPattern[$b],1)
			If Not @error Then
				;Cycle through all maches from the specific cell
				For $c=0 To UBound($aRegExResults)-1
					Local $NumericMatch=StringRegExpReplace($aRegExResults[$c],"\D","")
					If _LuhnCheck($NumericMatch)="True" Then
;~ 						$aTargetData[1][3] ;Match|Confidence|OriginalCellData
						$aTargetData[0][0]+=1
						_ArrayAdd($aTargetData,$NumericMatch&"|50|"&$aPreProc[$a][1])
						;Check for the total number of delimiters
						If StringIsInt(StringRight($aRegExResults[$c],1))=0 Then StringTrimRight($aRegExResults[$c],1)
						If StringIsInt(StringLeft($aRegExResults[$c],1))=0 Then StringTrimLeft($aRegExResults[$c],1)

						;Find the total number of spaces used by delimiters
						Local $Delimiters=StringRegExpReplace($aRegExResults[$c],"\d","")
						$Delimiters=StringStripWS($Delimiters,8)

						;Find the number of unique delimiter types "-/+" = 3 for example
						Local $DelimTypeCount=GetDelimiterTypeCount($Delimiters)

						Switch StringLen($Delimiters)
							Case 0
								$aTargetData[UBound($aTargetData)-1][1]+=40
							Case 1
								$aTargetData[UBound($aTargetData)-1][1]+=40
							Case 2
								$aTargetData[UBound($aTargetData)-1][1]+=30
							Case 3
								Switch $DelimTypeCount
									Case 1
										$aTargetData[UBound($aTargetData)-1][1]+=25
									Case 2
										$aTargetData[UBound($aTargetData)-1][1]+=20
									Case 3
										$aTargetData[UBound($aTargetData)-1][1]+=15
								EndSwitch
							Case 4
								Switch $DelimTypeCount
									Case 1
										$aTargetData[UBound($aTargetData)-1][1]+=40
									Case 2
										$aTargetData[UBound($aTargetData)-1][1]+=20
									Case 3
										$aTargetData[UBound($aTargetData)-1][1]+=15
									Case 4
										$aTargetData[UBound($aTargetData)-1][1]-=10
								EndSwitch
							Case 5
								Switch $DelimTypeCount
									Case 1
										$aTargetData[UBound($aTargetData)-1][1]+=40
									Case 2
										$aTargetData[UBound($aTargetData)-1][1]+=20
									Case 3
										$aTargetData[UBound($aTargetData)-1][1]+=15
									Case 4
										$aTargetData[UBound($aTargetData)-1][1]-=10
									Case 5
										$aTargetData[UBound($aTargetData)-1][1]-=30
								EndSwitch
							Case Else
								Switch $DelimTypeCount
									Case 1
										$aTargetData[UBound($aTargetData)-1][1]+=15
									Case 2
										$aTargetData[UBound($aTargetData)-1][1]+=10
									Case 3
										$aTargetData[UBound($aTargetData)-1][1]-=30
									Case 4
										$aTargetData[UBound($aTargetData)-1][1]-=35
									Case 5
										$aTargetData[UBound($aTargetData)-1][1]-=40
									Case Else
										$aTargetData[UBound($aTargetData)-1][1]-=50
								EndSwitch
						EndSwitch
					EndIf
				Next
			EndIf
		Next
	Next
	Return $aTargetData
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
						"LIKE '#TempCC%')) BEGIN DROP TABLE #TempCC END;")
	If $aColumn[2]="" Then
		$sQuery='CREATE TABLE #TempCC (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&');'
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
		$sQuery='CREATE TABLE #TempCC (RowNumber INT IDENTITY(1,1), "'&$aColumn[0]&'" '&$aColumn[1]&'('&$aColumn[2]&'));'
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
	$sQuery='INSERT INTO #TempCC '& _
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
			$ExcludeList[0] = 9
			$ExcludeList[1] = "distribution"
			$ExcludeList[2] = "master"
			$ExcludeList[3] = "model"
			$ExcludeList[4] = "msdb"
			$ExcludeList[5] = "publication"
			$ExcludeList[6] = "resource"
			$ExcludeList[7] = "reportserver"
			$ExcludeList[8] = "reportservertempdb"
			$ExcludeList[9] = "tempdb"
		Case "Tables"
			Local $ExcludeList[18]
			$ExcludeList[0] = 17
			$ExcludeList[1] = "syscolumns"
			$ExcludeList[2] = "syscomments"
			$ExcludeList[3] = "sysconstraints"
			$ExcludeList[4] = "sysdepends"
			$ExcludeList[5] = "sysfilegroups"
			$ExcludeList[6] = "sysfiles"
			$ExcludeList[7] = "sysforeignkeys"
			$ExcludeList[8] = "sysfulltextcatalogs"
			$ExcludeList[9] = "sysindexes"
			$ExcludeList[10] = "sysindexkeys"
			$ExcludeList[11] = "sysmembers"
			$ExcludeList[12] = "sysobjects"
			$ExcludeList[13] = "syspermissions"
			$ExcludeList[14] = "sysprotects"
			$ExcludeList[15] = "sysreferences"
			$ExcludeList[16] = "systypes"
			$ExcludeList[17] = "sysusers"
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
;~ 	FileWriteLine("sql.log",$vQuery)
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
	Local $aDelimiters[StringLen($Delimiters)]
	For $a=0 To StringLen($Delimiters)-1
		$aDelimiters[$a]=StringMid($Delimiters,$a,1)
	Next
	$aUniqueDelimiters=_ArrayUnique(StringLower($aDelimiters))
	If Not @error Then
		Return $aUniqueDelimiters[0]
	EndIf
	Return 0
EndFunc