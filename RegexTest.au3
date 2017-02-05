;~ 	Local $aRegexPattern[5]
;~ 	;Autoit's Regex has it's limits
;~ 	;American Express starts with 34 or 37 and has 15 digits
;~ 	$aRegexPattern[1]="(\D?|^)3\D{0,4}(4|7)(\D{0,4}\d){13}(\D?|$)"
;~ 	;Visa All cards start with 4 length is *NOT* 13-16 digits. 16 only.
;~ 	$aRegexPattern[2]="(\D?|^)4(\D{0,4}\d){15}(\D?|$)"
;~ 	;Discover begin with 6011 or 65. All have 16 digits.
;~ 	$aRegexPattern[3]="(\D?|^)6\D{0,4}(5(\D{0,4}\d){14}(\D?|$)|0\D{0,4}1\D{0,4}1(\D{0,4}\d){12}(\D?|$))"
;~ 	;MasterCard  start with 50 through 55. 16 digits
;~ 	$aRegexPattern[4]="(\D?|^)5\D{0,4}(0-5)(\D{0,4}\d){14}(\D?|$)"
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

Local $String="141a11111111111111 4111111b1111111119+411111111c1111111,41111d11111111111-411111e1111111111"
;~ _ArrayDisplay(StringRegExp($String,"(\D|^)4(\D{0,4}\d){15}(\D|$)",0))
;~ _ArrayDisplay(StringRegExp($String,"(?<![0-9])4(\D{0,4}\d){15}(?![0-9])",1))
;~ _ArrayDisplay(StringRegExp($String,"(?<![0-9])4(\D{0,4}\d){15}(?![0-9])",2))
;~ _ArrayDisplay(StringRegExp($String,"(?<![0-9])4(\D{0,4}\d){15}(?![0-9])",3))
Local $ArrayofArrays=StringRegExp($String,"(?<![0-9])4(\D{0,4}\d){15}(?![0-9])",4)
_ArrayDisplay($ArrayofArrays)
For $a=0 To UBound($ArrayofArrays)-1
	_ArrayDisplay($ArrayofArrays[$a])
Next