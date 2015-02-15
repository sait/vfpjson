set proc to json additive

* test table customer
create cursor customers (id n(5), name c(50), lastname c(50), phone c(30))
insert into customers values (1,'Ignacio','Gutierrez','(653)534-8800')
insert into customers values (2,'Antonio','Esparza','(81)8347-1411')
insert into customers values (3,'David','Flores','(653)534-2755')

* parse first record
? 'Json Representing for each customer'
select customers
scan
	? recordToJson()
endscan

?
? 
? 'Now json represent of a whole table'
go top
? tableToJson()