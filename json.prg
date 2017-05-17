*
* vfpjson
*
* ----------------------------------
* Ignacio Gutiérrez Torrero
* SAIT Software Administrativo
* www.sait.com.mx
* +52(653)534-8800
* Monterrey México
* -----------------------------------
* Mejorado por 
* Ing. Guillermo C. Torres Díaz
* Arequipa - Perú
* 2015/03/16
* y con snippets de Victor Espina

* JSON Library in VFP
* Libreria para el manejo de JSON en VFP
*
* http://code.google.com/p/dart/source/browse/trunk/dart/lib/json/json.dart
* Thanks Google for the code in Json Dart
* Gracias a Google por el codigo de Json de Dart
*
* json_encode(xExpr)
* returns a string, that is the json of any expression passed
*
* json_decode(cJson)
* returns an object, from the string passed
*
* json_getErrorMsg()
* returns empty if no error found in last decode.
*
* this class consider the JSONFROMURL method to capture properly the JSON ANSWER FROM A WEBSERVICE
*
*!*	Examples

*!*	set procedure vfpjson additive
*!*	oPerson = json_decode(' { "name":"Ignacio" , "lastname":"Gutierrez", "age":33 } ')
*!*	If Not Empty(json_getErrorMsg())
*!*		? 'Error in decode:'+json_getErrorMsg())
*!*		Return
*!*	Endif
*!*	? oPerson.Get('name') , oPerson.Get('lastname')


*!*	oCustomer = json_decode( ' { "name":"Ignacio" , "lastname":"Gutierrez", "age":33 } ')
*!*	? _Json.encode(oCustomer)
*!*	? oCustomer.Get('name')
*!*	? oCustomer.Get('lastname')
*!*	? oCustomer._age
*!*	? oCustomer  &&"(Object)"


*!*	cstring = _Json.JsonfromUrl("http://api.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de&username=demo")
*!*	obj= _json.json2object(cstring)
*!*	?obj._geonames.array[1]._name
*!*	?obj._geonames.array[2]._name
*!*	?obj._geonames.array[3]._name

lRunTest = .T.
If lRunTest
	testJsonClass()
Endif
Return


Function start_json
	* implement a singleton for the functions to run
	If Vartype(_json)<>'O' Or Isnull(_json)
		Public _json
		_json = Newobject('json')
	Endif
Endfunc


Function json_encode(xExpr)
	start_json()
	Return _json.Express2Json(@xExpr)
Endfunc

Function json_decode(cJson)
	Local retval
	start_json()
	retval = _json.Decode(cJson)
	If Not Empty(_json.cError)
		Return Null
	Endif
	Return retval
Endfunc



Function json_getErrorMsg()
	Return _json.cError
Endfunc


*
* recordToJson()
*
* Returns the json representation for current record
* Try it:
* 		use c:\mydir\mytable
*		cInfo = recordToJson()
*		? cInfo
*
Function recordToJson
	Local calias, cRetVal
	calias = Alias()
	If Empty(calias)
		Return  ""
	Endif
	cthestring = _json.Record2Json(calias)
	If Not Empty(json_getErrorMsg())
		cRetVal = 'ERROR:'+json_getErrorMsg()
	Endif
	Return cRetVal
Endfunc





* tableToJson()
*
* Returns the json representation for current table
* Warning need to be changed for large table, because use dimension aInfo[reccount()]
* For large table should change to create the string record by record.
*
* THIS NEW ALGORITHM WAS PROVE against a mora than 50000 records and everyrecord with 36 fields
* hope you like  :)
* Try it:
* 		use c:\mydir\mytable
*		cInfo = tableToJson()
*		? cInfo
*		_cliptext = strtran(cInfo, ',{"', ','+chr(13)+'{"')
*		Go to Any Editor and Paste the information
*
Function tableToJson
	Local calias, cRetVal
	calias = Alias()
	If Empty(calias)
		Return  ""
	Endif
	cthestring = _json.Table2Json(calias)
	If Not Empty(json_getErrorMsg())
		cRetVal = 'ERROR:'+json_getErrorMsg()
	Endif
	Return cRetVal
Endfunc



* json class
*
*
Define Class json As Custom

	nPos = 0
	nLen = 0
	cJson = ''
	cError = ''
	lshowerrormsg = .F.
	stringDelimitator = ["]

	Function Encode(puValue)
		Return This.Express2Json(@puValue)
	Endfun


	* Genera el codigo cJson para parametro que se manda
	* Returns a string, that is the json of any expression passed.

	* Returns a string, that is the json of any expression passed; just a more clear name for "ENCODE"
	Function Express2Json(puValue)
		Local lIsArray, cType, cJSONValue
		lIsArray = (Type("ALEN(puValue)") = "N")
		cType = Vartype(puValue)
		cJSONValue = "null"
		This.cError= ""
		Do Case
			Case lIsArray        && Array value
				cJSONValue = "["
				Local i,nSize
				If Pcount() = 2
					nSize = pnArraySize
				Else
					nSize = Alen(puValue,1)
				Endif
				For i = 1 To nSize
					cJSONValue = cJSONValue + Iif(i>1,",","") + This.Express2Json(puValue[i])
				Endfor
				cJSONValue = cJSONValue + "]"

			Case cType $ "CM"    && string/char value
				cJSONValue = This.stringDelimitator + puValue + This.stringDelimitator

			Case cType $ "NIYF"   && Numeric value
				If puValue = Int(puValue)
					cJSONValue = Alltrim(Str(puValue))
				Else
					cJSONValue = Chrtran(This.RTRIMX(This.RTRIMX(Transform(puValue), "0"), Set("POINT")),Set("POINT"), ".")  && JuanPa / Rafel Cano, Abril 13 2012
				Endif

			Case cType = "L"     && boolean value
				cJSONValue = Iif(puValue,"true","false")

			Case cType = "D"     && Date value (foxpro only)
				cJSONValue = [@] + Dtos(puValue)

			Case cType = "T"     && Datetime value (foxpro only)
				cJSONValue = [@] + Ttoc(puValue,1)

			Case cType = "O"     && Object value
				If	Pemstatus(puValue,"ToJSON",5)
					cJSONValue = puValue.ToJSON()
				Else
					Local cProp, cJSONValue, cRetVal, aProp[1]
					=Amembers(aProp,puValue)
					cRetVal = ''
					For Each cProp In aProp
						Do Case
							Case Type('puValue.'+cProp)=='U' Or cProp=='CLASS'
								* algunas propiedades pueden no estar definidas, por eso omite lo de este tipo
								* como: activecontrol, parent, etc
								Loop
							Case Type('puValue.'+cProp) = "O"

								* como es un objeto dentro de otro objeto, no hago más llamadas recursivas
								If Isnull('puValue.'+cProp)=.T.
									cJSONValue = [{"Content":null}]
								Else
									cJSONValue = [{"Content":"Object"}]
								Endif
							Case Type( 'ALen(puValue.'+cProp+')' ) == 'N'
								*es un arreglo, recorrerlo usando los [ ] y macro
								Local i,nTotElem
								cJSONValue = ''
								nTotElem = Eval('ALen(puValue.'+cProp+')')
								For i=1 To nTotElem
									cmd = 'cJsonValue=cJsonValue+","+ this.express2json( puValue.'+cProp+'[i])'
									&cmd.
								Next
								cJSONValue = '[' + Substr(cJSONValue,2) + ']'
							Otherwise
								* es otro tipo de dato normal C, N, L
								*
								cJSONValue = This.Express2Json( Evaluate( 'puValue.'+cProp ) )
						Endcase

						cRetVal = cRetVal + ',' + '"' + Lower(cProp) + '":' + cJSONValue
					Endfor
					cJSONValue = '{' + Substr(cRetVal,2) + '}'
				Endif

			Otherwise  && unknown type. Handle it as a string value
				cJSONValue = Transform(puValue,"")
		Endcase
		Return cJSONValue
	Endfunc




	* regresa un elemento representado por la cadena json que se manda
	* Returns an object, from the JSON  string passed.
	Function Decode(cJson)
		This.cError= ""
		Local retValue
		cJson = Strtran(cJson,Chr(9),'')
		cJson = Strtran(cJson,Chr(10),'')
		cJson = Strtran(cJson,Chr(13),'')
		cJson = This.Unicode2Ansi(cJson)  &&de unicode -> ansi
		This.nPos  = 1
		This.cJson = cJson
		This.nLen  = Len(cJson)
		This.cError = ''
		retValue = This.parsevalue()
		If Not Empty(This.cError)
			Return Null
		Endif
		If This.getToken()<>Null
			This.setError('Junk at the end of JSON input')
			Return Null
		Endif
		Return retValue
	Endfunc


	* Returns a string, that is the json of any expression passed; just a more clear name for "DECODE"
	Function Json2Object
		Lparameters cJSONString
		Return This.Decode(cJSONString)
	Endfunc


	* Returns a json string from a URL, distinguishing the errors a server could answer
	* Appropiate for Web Services
	* 	IT AWAITS A JSON- FORMATED STRING
	Function JsonfromUrl(cUrl)
		This.cError= ""
		Local cJSONString, ncodeobtained, lsuccess
		If Empty(cUrl) Or Vartype(cUrl)<>"C"
			This.setError("invalid parameters(s) in calling jsonfromUrl")
			Return Null
		Endif

		Wait Window "connecting url..." Nowait
		lsuccess = This.ReadJsonStringfromUrl(cUrl,@cJSONString,@ncodeobtained)

		If Not lsuccess Or ncodeobtained>= 400
			cJSONString = ""
			This.setError("Error found in connecting with or the answer the server gave")
			Wait Window "error in process url" Nowait
		Else
			Wait Window "response proccesed" Nowait
		Endif

		Return cJSONString
	Endfunc


	Function Table2Json
		Lparameters calias, ndatasessionID, lIgnoreStrangeType
		* you always have to indicate the alias to process
		* lIgnoreStrangeType=.t., to indicate the class must to ignore field types wich can not be json-converted

		Local nolddatasession
		nolddatasession = Set("Datasession")
		This.cError= ""

		If Not This.SelectAlias(calias, ndatasessionID)
			Return ""
		Endif

		Local i,oObj
		Local totalrecs, nTotalflds
		Local cJsonString_, aTableStruct, cFieldType_, lFirstToken_
		Dimension aTableStruct[1]
		nTotalflds = Afields(aTableStruct)
		cJsonString_= "["
		lFirstToken_ = .T. &&es para evitar la primera coma, ya que una vez creado el string, sólo puede crecer

		Do Case
			Case Reccount()=0
				Wait Window "no records to process" Timeout 3
			Case Reccount()=>1000
				* se advierte al usuario que la tabla es muy grande
				If Messagebox("Table got more than 1000 recs."+Chr(13)+"Do you want to proceed?",4+32+256)=7 &&no
					Return ""
				Endif
		Endcase

		Go Top
		Scan
			Wait Window "working on record:"+Alltrim(Str(Recno())) Nowait
			oObj = Newobject('myObj')
			For i=1 To nTotalflds
				cFieldType_ = aTableStruct(i,2)

				If cFieldType_$"MGWQV" &&"M": Memo, "G": general, "W": blob, "Q": varbinary,	"V": Varchar and Varchar (binary)
					* since not always we can encode everytype of content, we always skip this fields
					* but we can include his names in the resulting string
					If Empty(lIgnoreStrangeType)
						oObj.Set(Field(i),cFieldType_+"FieldTyp")
					Endif
				Else
					oObj.Set(Field(i),Eval(Field(i)))
				Endif

			Endfor
			cJsonString_= cJsonString_+Iif(lFirstToken_,"",",")+This.Express2Json(oObj)
			lFirstToken_ = .F.
			oObj = Null
		Endscan
		cJsonString_= cJsonString_+"]"
		Wait Window "process complete" Nowait

		Set DataSession To (nolddatasession) &&restaura la sesion de datos
		Return cJsonString_

	Endfunc




	Function Record2Json
		Lparameters calias, ndatasessionID, lIgnoreStrangeType
		* you always have to indicate the alias to process
		* lIgnoreStrangeType=.t., to indicate the class must to ignore field types wich can not be json-converted

		Local nolddatasession
		nolddatasession = Set("Datasession")
		This.cError= ""
		If Not This.SelectAlias(calias, ndatasessionID)
			Return ""
		Endif
		If Eof(calias)
			This.cError = "no record to process: end of the table"
			Return ""
		Endif

		Local i,oObj
		Local nTotalflds, aTableStruct
		Local cJsonString_, cFieldType_
		Dimension aTableStruct[1]
		totalflds = Afields(aTableStruct)
		cJsonString_= "["

		oObj = Newobject('myObj')
		For i=1 To nTotalflds
			cFieldType_ = aTableStruct(i,2)

			If cFieldType_$"MGWQV" &&"M": Memo, "G": general, "W": blob, "Q": varbinary,	"V": Varchar and Varchar (binary)
				* since not always we can encode everytype of content, we always skip this fields
				* but we can include his names in the resulting string
				If Empty(lIgnoreStrangeType)
					oObj.Set(Field(i),cFieldType_+"FieldTyp")
				Endif
			Else
				oObj.Set(Field(i),Eval(Field(i)))
			Endif

		Endfor
		cJsonString_= cJsonString_+ This.Express2Json(oObj)+"]"
		oObj = Null

		Set DataSession To (nolddatasession) &&restaura la sesion de datos
		Return cJsonString_

	Endfunc



	Protected Function parsevalue()
		Local token
		token = This.getToken()
		If token==Null
			This.setError('Nothing to parse')
			Return Null
		Endif
		Do Case
			Case token$['"]
				Return This.parseString()
			Case Isdigit(token) Or token=='-'
				Return This.parseNumber()
			Case token=='n'
				Return This.expectedKeyword('null',Null)
			Case token=='f'
				Return This.expectedKeyword('false',.F.)
			Case token=='t'
				Return This.expectedKeyword('true',.T.)
			Case token=='{'
				Return This.parseObject()
			Case token=='['
				Return This.parseArray()
			Case token=='@'	 &&fecha o fechayhora
				Return This.parseDateTime()
			Otherwise
				This.setError('Unexpected token')
		Endcase
		Return
	Endfunc



	Protected Function expectedKeyword(cWord,eValue)
		For i=1 To Len(cWord)
			cChar = This.getChar()
			If cChar <> Substr(cWord,i,1)
				This.setError("Expected keyword '" + cWord + "'")
				Return ''
			Endif
			This.nPos = This.nPos + 1
		Next
		Return eValue
	Endfunc


	Protected Function parseObject()
		Local retval, cPropName, xValue
		retval = Createobject('myObj')
		This.nPos = This.nPos + 1 && Eat {
		If This.getToken()<>'}'
			Do While .T.
				cPropName = This.parseString()
				If Not Empty(This.cError)
					Return Null
				Endif
				If This.getToken()<>':'
					This.setError("Expected ':' when parsing object")
					Return Null
				Endif
				This.nPos = This.nPos + 1
				xValue = This.parsevalue()
				If Not Empty(This.cError)
					Return Null
				Endif
				retval.Set(cPropName, xValue)
				If This.getToken()<>','
					Exit
				Endif
				This.nPos = This.nPos + 1
			Enddo
		Endif
		If This.getToken()<>'}'
			This.setError("Expected '}' at the end of object")
			Return Null
		Endif
		This.nPos = This.nPos + 1
		Return retval
	Endfunc



	Protected Function parseArray()
		Local retval, xValue
		retval = Createobject('MyArray')
		This.nPos = This.nPos + 1	&& Eat [
		If This.getToken() <> ']'
			Do While .T.
				xValue = This.parsevalue()
				If Not Empty(This.cError)
					Return Null
				Endif
				retval.Add( xValue )
				If This.getToken()<>','
					Exit
				Endif
				This.nPos = This.nPos + 1
			Enddo
			If This.getToken() <> ']'
				This.setError('Expected ] at the end of array')
				Return Null
			Endif
		Endif
		This.nPos = This.nPos + 1
		Return retval
	Endfunc


	Protected Function parseString()
		Local cRetVal, cstringmark, nposicion_,char1_,char2_
		cstringmark  = This.getToken()
		If Not(cstringmark $["'])
			This.setError('string Expected ')
			Return ''
		Endif

		nposicion_ = This.nPos +1
		Do While nposicion_ <= This.nLen -1
			char1_ = Substr(This.cJson, nposicion_, 1)
			char2_ = Substr(This.cJson, nposicion_+1, 1)

			If char1_="\" And char2_$[btnfr'"\/] &&se trata de una secuencia de escape, ignora el delimitador
				nposicion_ = nposicion_+2
				Loop
			Endif

			If char1_=cstringmark
				Exit
			Endif
			nposicion_ = nposicion_+1

			If nposicion_>This.nLen
				This.setError('string not properly delimited')
				This.nPos = nposicion_+1
				Return ''
			Endif

		Enddo

		cRetVal = Substr(This.cJson, This.nPos+1,nposicion_-This.nPos-1 )
		This.nPos = nposicion_+1
		Return cRetVal

	Endfunc



	Protected Function parseDateTime()
		Local nposicion_, char1_, secuencia_, cRetVal
		nposicion_ = This.nPos +1

		Do While nposicion_ <= This.nLen
			char1_ = Substr(This.cJson, nposicion_, 1)
			If Not Isdigit(char1_) &&fin de cadena para la fecha, TODOS deben ser numeros
				Exit
			Else
				nposicion_ = nposicion_ + 1
			Endif
		Enddo
		*esta dato es una cadena de 8 digitos (si es fecha) o de 14 (si es fecha+ hora)
		secuencia_ = Substr(This.cJson, This.nPos+1,nposicion_-This.nPos-1 )
		If Not Inlist(Len(secuencia_),8,14) &&si no es ni 8 ni 14
			This.setError('expected datetime data')
			This.nPos = nposicion_
			Return {//}
		Endif

		If Len(secuencia_)=8 &&fecha
			cRetVal = Date(Val(Substr(secuencia_,1,4)),Val(Substr(secuencia_,5,2)),Val(Substr(secuencia_,7,2)))
		Else
			cRetVal = Datetime(Val(Substr(secuencia_,1,4)),Val(Substr(secuencia_,5,2)),Val(Substr(secuencia_,7,2)),;
				VAL(Substr(secuencia_,9,2)),Val(Substr(secuencia_,11,2)),Val(Substr(secuencia_,13,2)))
		Endif
		This.nPos = nposicion_
		Return cRetVal

	Endfunc



	**** Pendiente numeros con E
	Protected Function parseNumber()
		Local nStartPos,c, isInt, cNumero
		If Not ( Isdigit(This.getToken()) Or This.getToken()=='-')
			This.setError('Expected number literal')
			Return 0
		Endif
		nStartPos = This.nPos
		c = This.getChar()
		If c == '-'
			c = This.nextChar()
		Endif
		If c == '0'
			c = This.nextChar()
		Else
			If Isdigit(c)
				c = This.nextChar()
				Do While Isdigit(c)
					c = This.nextChar()
				Enddo
			Else
				This.setError('Expected digit when parsing number')
				Return 0
			Endif
		Endif

		isInt = .T.
		If c=='.'
			c = This.nextChar()
			If Isdigit(c)
				c = This.nextChar()
				isInt = .F.
				Do While Isdigit(c)
					c = This.nextChar()
				Enddo
			Else
				This.setError('Expected digit following dot comma')
				Return 0
			Endif
		Endif

		cNumero = Substr(This.cJson, nStartPos, This.nPos - nStartPos)
		Return Val(cNumero)
	Endfunc



	Hidden Function getToken()
		Local char1
		Do While .T.
			If This.nPos > This.nLen
				Return ""
			Endif
			char1 = Substr(This.cJson, This.nPos, 1)
			If char1==' '
				This.nPos = This.nPos + 1
				Loop
			Endif
			Return char1
		Enddo
		Return
	Endfunc


	Hidden Function getChar()
		If This.nPos > This.nLen
			This.setError('Unexpected end of JSON stream')
			Return ''
		Endif
		Return Substr(This.cJson, This.nPos, 1)
	Endfunc

	Hidden Function nextChar()
		This.nPos = This.nPos + 1
		If This.nPos > This.nLen
			Return ''
		Endif
		Return Substr(This.cJson, This.nPos, 1)
	Endfunc


	Hidden Function RTRIMX(pcString, pcCharToTrim)
		Local i
		i = Len(pcString)
		Do While Subs(pcString, i, 1) = pcCharToTrim
			i = i - 1
			pcString = Left(pcString, i)
		Enddo
		Return pcString
	Endfunc


	Protected Function setError(cMsg, lnoshowposition)
		* lnoshowposition, es para manejar el resto de errores además de los del parsing
		* lnoshowposition, is to handle any other errors in addition to the parsing

		This.cError= Iif(Empty(lnoshowposition),'ERROR parsing JSON at Position:'+Allt(Str(This.nPos,6,0))+' '+cMsg, cMsg)
		If This.lshowerrormsg
			Wait Window (This.cError) Timeout 2
		Endif

		Return
	Endfunc

	Function getError()
		Return This.cError
	Endfunc


	Function Unicode2Ansi(cStr)
		cStr = Strtran(cStr,'\u00e1','á')
		cStr = Strtran(cStr,'\u00e9','é')
		cStr = Strtran(cStr,'\u00ed','í')
		cStr = Strtran(cStr,'\u00f3','ó')
		cStr = Strtran(cStr,'\u00fa','ú')
		cStr = Strtran(cStr,'\u00fc','ü')
		cStr = Strtran(cStr,'\u00c1','Á')
		cStr = Strtran(cStr,'\u00c9','É')
		cStr = Strtran(cStr,'\u00cd','Í')
		cStr = Strtran(cStr,'\u00d3','Ó')
		cStr = Strtran(cStr,'\u00da','Ú')
		cStr = Strtran(cStr,'\u00dc','Ü')
		cStr = Strtran(cStr,'\u00f1','ñ')
		cStr = Strtran(cStr,'\u00d1','Ñ')
		cStr = Strtran(cStr,'\u0040','@')
		cStr = Strtran(cStr,'\u002a','*')
		cStr = Strtran(cStr,'\u0028','(')
		cStr = Strtran(cStr,'\u0029',')')
		cStr = Strtran(cStr,'\u0026','&')
		cStr = Strtran(cStr,'\u002f','/')
		cStr = Strtran(cStr,'\u003b',';')
		cStr = Strtran(cStr,'\u003f','?')
		cStr = Strtran(cStr,'\u005c','\')
		cStr = Strtran(cStr,'\u005f','_')
		cStr = Strtran(cStr,'\u00b4',"'")
		cStr = Strtran(cStr,'\u00a1','¡')
		cStr = Strtran(cStr,'\u0021','!')
		cStr = Strtran(cStr,'\u00bf','¿')
		Return cStr
	Endfun


	Function Ansi2Unicode(cStr)
		cStr = Strtran(cStr,'á','\u00e1')
		cStr = Strtran(cStr,'é','\u00e9')
		cStr = Strtran(cStr,'í','\u00ed')
		cStr = Strtran(cStr,'ó','\u00f3')
		cStr = Strtran(cStr,'ú','\u00fa')
		cStr = Strtran(cStr,'ü','\u00fc')
		cStr = Strtran(cStr,'Á','\u00c1')
		cStr = Strtran(cStr,'É','\u00c9')
		cStr = Strtran(cStr,'Í','\u00cd')
		cStr = Strtran(cStr,'Ó','\u00d3')
		cStr = Strtran(cStr,'Ú','\u00da')
		cStr = Strtran(cStr,'Ü','\u00dc')
		cStr = Strtran(cStr,'ñ','\u00f1')
		cStr = Strtran(cStr,'Ñ','\u00d1')
		cStr = Strtran(cStr,'@','\u0040')
		cStr = Strtran(cStr,'*','\u002a')
		cStr = Strtran(cStr,'(','\u0028')
		cStr = Strtran(cStr,')','\u0029')
		cStr = Strtran(cStr,'&','\u0026')
		cStr = Strtran(cStr,'/','\u002f')
		cStr = Strtran(cStr,';','\u003b')
		cStr = Strtran(cStr,'?','\u003f')
		cStr = Strtran(cStr,'\','\u005c')
		cStr = Strtran(cStr,'_','\u005f')
		cStr = Strtran(cStr,"'",'\u00b4')
		cStr = Strtran(cStr,'¡','\u00a1')
		cStr = Strtran(cStr,'!','\u0021')
		cStr = Strtran(cStr,'¿','\u00bf')
		Return cStr
	Endfunc



	Hidden Function ReadJsonStringfromUrl
		Lparameters cUrl_, cStreamData_, nStatus_
		*Lee un recurso web y regresa en formato de JSON
		*Read a web resource and returns in JSON format

		*REGRESA un valor lógico para indicar si se tuvo exito o no en leer el recurso
		*RETURNS a boolean to indicate if the action succeeds or not


		* cUrl_			: es la dirección web que se quiere leer
		* cStreamData_	: X REFERENCIA, contendrá todo el contenido del recurso web
		* nStatus_ 		: X REFERENCIA, contendrá el codigo del estado de la lectura, que corresponde a los codigos de estado HTTTP

		* CUrl_: is a valid web address to be read
		* CStreamData_: BY REFERENCE, will contain the entire contents of the web resource
		* NStatus_: BY REFERENCE, will contain the status code reading, which corresponds to HTTP status codes

		* nStatus_, por defecto contiene -1, para indicar que no pudo crear el objeto que administra la conexión
		* nStatus_, by default contains -1, indicating that it could not create the object that manages the connection

		If Parameters()<3
			* si el usuario no manda los 3 parámetros NO tiene sentido procesar nada, puesto que el resultado se regresa en esos otros parámetros
			* If the user does not send the 3 parameters there is NO sense to process anything, since the result is returned in those other parameters
			Return .F.
		Endif

		nStatus_ = -1
		cStreamData_ = ""

		Local ohttp_
		Try
			ohttp_ = Createobject("Microsoft.XMLHTTP")
		Catch
			ohttp_ = Null
		Endtry

		If Isnull(ohttp_)
			Return .F.
		Endif

		Try
			ohttp_.Open("GET", cUrl_, .F.)
			ohttp_.setRequestHeader('Content-Type','application/json')
			ohttp_.Send()
		Catch To oexcept_
			This.setError("Error in the Internet connection" +Chr(13)+;
				"number: "+ Alltrim(Str(oexcept_.ErrorNo))+Chr(13)+;
				oexcept_.Message, .T. )

			ohttp_ = Null
			Return .F.
		Endtry

		nStatus_ = ohttp_.Status
		cStreamData_ = ohttp_.responseText
		cStreamData_ = This.Unicode2Ansi(cStreamData_)

		ohttp_ = Null

		Return .T.
	Endfunc



	* SelectAlias
	* This function checks the table can be found in the table open session data indaicada
	* Or current, and returns one logical value to indicate that there was successful or not
	* If you do not see the table restores data session in which it was before attempting to change
	* Optional ndatasession


	* SelectAlias
	* esta función verifica que se pueda encontrar la tabla abierta en la session de datos indaicada
	* o actual, y regresa un valor lógica para indicar que hubo exito o no
	* si no encuentra la tabla restaura la sesion de datos en la que se encontraba antes de intentar cambiarla
	* ndatasession es opcional
	Hidden Function SelectAlias
		Lparameters  cAlias_, ndatasession_
		Local oldsession__, exito__
		exito__ = .F.
		oldsession__ = Set("Datasession")

		If Vartype(cAlias_)!="C" Or Empty(cAlias_)
			This.setError("invalid Alias name")
			Return .F.
		Endif

		If Vartype(ndatasession_)="N" And ndatasession_>0
			Set DataSession To ndatasession_
		Endif

		If Used(cAlias_)
			Select (cAlias_)
			exito__ = .T.
		Else
			This.setError("Cursor: "+cAlias_+" NOT found")
			Set DataSession To (oldsession__)
		Endif
		Return exito__
	Endfunc


Enddefine





*
* class used to return an array
*
Define Class myArray As Custom
	nSize = 0
	Dimension Array[1]

	Function Add(xExpr)
		This.nSize = This.nSize + 1
		Dimension This.Array[this.nSize]
		This.Array[this.nSize] = xExpr
		Return

	Function Get(N)
		Return This.Array[n]

	Function getsize()
		Return This.nSize

Enddefine



*
* class used to simulate an object
* all properties are prefixed with 'prop' to permit property names like: error, init
* that already exists like vfp methods
*
Define Class myObj As Custom
	Hidden ;
		ClassLibrary,Comment, ;
		BaseClass,ControlCount, ;
		Controls,Objects,Object,;
		Height,HelpContextID,Left,Name, ;
		Parent,ParentClass,Picture, ;
		Tag,Top,WhatsThisHelpID,Width

	Function Set(cPropName, xValue)
		cPropName = '_'+cPropName
		Do Case
			Case Type('ALen(xValue)')=='N'
				* es un arreglo
				Local nLen,cmd,i
				This.AddProperty(cPropName+'(1)')
				nLen = Alen(xValue)
				cmd = 'Dimension This.'+cPropName+ ' [ '+Str(nLen,10,0)+']'
				&cmd.
				For i=1 To nLen
					cmd = 'This.'+cPropName+ ' [ '+Str(i,10,0)+'] = xValue[i]'
					&cmd.
				Next

			Case Type('this.'+cPropName)=='U'
				* la propiedad no existe, definirla
				This.AddProperty(cPropName,@xValue)

			Otherwise
				* actualizar la propiedad
				Local cmd
				cmd = 'this.'+cPropName+'=xValue'
				&cmd
		Endcase
		Return
	Endproc

	Procedure Get (cPropName)
		cPropName = '_'+cPropName
		If Type('this.'+cPropName)=='U'
			Return ''
		Else
			Local cmd
			cmd = 'return this.'+cPropName
			&cmd
		Endif
		Return ''
	Endproc

Enddefine



Function testJsonClass
	Clear
	Set Decimal To 10
	oJson = Newobject('json')


	? 'Test Basic Types'
	? '----------------'
	? oJson.Decode('null')
	? oJson.Decode('true')
	? oJson.Decode('false')
	?
	? oJson.Decode('17311')
	? oJson.Decode('728.45')
	? oJson.Decode('88.45.')
	? oJson.Decode('"nacho gtz"')
	If Not Empty(oJson.cError)
		? oJson.cError
		Return
	Endif
	? oJson.Decode('"nacho gtz\nEs \"bueno\"\nMuy Bueno\ba"')
	If Not Empty(oJson.cError)
		? oJson.cError
		Return
	Endif

	? 'Test Array'
	? '----------'
	arr = oJson.Decode('[3.1416,"Ignacio",false,null]')
	? arr.Get(1), arr.Get(2), arr.Get(3), arr.Get(4)
	arr = oJson.Decode('[ ["Hugo","Paco","Luis"] , [ 8,9,11] ] ')
	nombres = arr.Get(1)
	edades  = arr.Get(2)
	? nombres.Get(1), edades.Get(1)
	? nombres.Get(2), edades.Get(2)
	? nombres.Get(3), edades.Get(3)
	?
	? 'Test Object'
	? '-----------'
	obj = oJson.Decode('{"nombre":"Ignacio", "edad":33.17, "isGood":true}')
	? obj.Get('nombre'), obj.Get('edad'), obj.Get('isGood')
	? obj._Nombre, obj._Edad, obj._IsGood
	obj = oJson.Decode('{"jsonrpc":"1.0", "id":1, "method":"sumArray", "params":[3.1415,2.14,10],"version":1.0}')
	? obj.Get('jsonrpc'), obj._jsonrpc
	? obj.Get('id'), obj._id
	? obj.Get('method'), obj._method
	? obj._Params.Array[1], obj._Params.Get(1)

	?
	? 'Test nested object'
	? '------------------'
	cJson = '{"jsonrpc":"1.0", "id":1, "method":"upload", "params": {"data":{ "usrkey":"2415af77b", "sendto":"ignacio@sait.com.mx", "name":"Ignacio is \"Nacho\"","expires":"20120731" }}}'
	obj = oJson.Decode(cJson)
	If Not Empty(oJson.cError)
		? oJson.cError
		Return
	Endif
	? cJson
	? 'method -->',obj._method
	? 'usrkey -->',obj._Params._data._usrkey
	? 'sendto -->',obj._Params._data._sendto
	? 'name  --->',obj._Params._data._name
	? 'expires ->',obj._Params._data._expires

	?
	? 'Test empty object'
	? '-----------------'
	cJson = '{"result":null,"error":{"code":-3200.012,"message":"invalid usrkey","data":{}},"id":"1"}'
	obj = oJson.Decode(cJson)
	If Not Empty(oJson.cError)
		? oJson.cError
		Return
	Endif
	? cJson
	? 'result -->',obj._result, obj.Get('result')
	oError = obj.Get('error')
	? 'ErrCode ->',obj._error._code, oError.Get('code')
	? 'ErrMsg -->',obj._error._message, oError.Get('message')
	? 'id  ----->',obj._id, obj.Get('id')
	?  Type("oError._code")

	?
	? 'Probar decode-enconde-decode-encode'
	? '------------------------------------'
	cJson = ' {"server":"", "user":"", "password":"" ,'+;
		' "port":0, "auth":false, "ssl":false, "timeout":20, "error":404}'
	? cJson
	oSmtp = json_decode(cJson)
	cJson =  json_encode(oSmtp)
	? cJson
	oSmtp = json_decode(cJson)
	cJson =  json_encode(oSmtp)
	? cJson

	* Probar falla
	?
	? 'Probar una falla en el json'
	? '---------------------------'
	cJson = ' {"server":"", "user":"", "password":"" ,'
	oSmtp = json_decode(cJson)
	If Not Empty(json_getErrorMsg())
		? json_getErrorMsg()
	Endif

	?
	? 'Pruebas Finalizadas'
	Return
Endfunc
