
	.FUNCT	THIS-IT?,OBJ,TBL,SYNS,?TMP1
	FSET?	OBJ,INVISIBLE /FALSE
	ZERO?	P-NAM /?THN3
	GETPT	OBJ,P?SYNONYM >SYNS
	PTSIZE	SYNS
	DIV	STACK,2
	SUB	STACK,1
	CALL	ZMEMQ,P-NAM,SYNS,STACK
	ZERO?	STACK /FALSE
?THN3:	ZERO?	P-ADJ /?ELS8
	GETPT	OBJ,P?ADJECTIVE >SYNS
	ZERO?	SYNS /FALSE
	PTSIZE	SYNS
	SUB	STACK,1
	CALL	ZMEMQB,P-ADJ,SYNS,STACK
	ZERO?	STACK /FALSE
?ELS8:	ZERO?	P-GWIMBIT /TRUE
	FSET?	OBJ,P-GWIMBIT /TRUE
	RFALSE	


	.FUNCT	I-LANTERN
	CALL	LIGHT-INT,LAMP,I-LANTERN,'LAMP-TABLE
	RSTACK	

	.ENDI
