#VFPJSON
JSON library for VFP.

**Express2Json(eExpr)**
Returns a string, that is the json of any expression passed.


**Json2Object(cJson)**
Returns an object, from the string passed.

**json_getErrorMsg()**
Returns empty if no error found in last decode.

**Record2Json()**
Returns the json representation for current record.

**Table2Json()**
Returns the json representation for current table

**JsonfromUrl(cUrl)
Capture properly the JSON of a websever

###Examples
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

