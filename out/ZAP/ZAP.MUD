<PACKAGE "ZAP">

<ENTRY ZAP LONG-ERRORS? REAL-ERROR? BYTE-SWAP? DTRACE?>

<USE "ZSTR" "ZOPS" "ZAC">
<USE "SORTEX">

"********** ASSORTED GLOBALS **********"

<GDECL (ZPC TABLE-END CUROBJ CURGVAR INS ASSEMERRS DSBOT DSPOS DSJFN) FIX
       (PASS1? LONG-ERRORS? REAL-ERROR? BYTE-SWAP? DTRACE?) <OR ATOM FALSE>
       (GLOBALS LOCALS) OBLIST
       (ZOB) !<LIST OBLIST OBLIST ATOM OBLIST>
       (ZIN) CHANNEL
       (OZINS) <LIST [REST CHANNEL]>
       (ZCODE) <BYTES 8>
       (STATEMENTS) <LIST [REST LIST]>
       (SCRIPT) <OR CHANNEL FALSE>
       (DSYMBOLS) <BYTES 18>
       (LASTSYM) STRING>

<SETG LONG-ERRORS? T>
<SETG REAL-ERROR? <>>
<SETG BYTE-SWAP? <>>
<SETG DTRACE? <> ;T>

<SETG ZAPID 1>
<MANIFEST ZAPID>


"********** ERROR HANDLERS **********"

<DEFINE ASSEMERR ("TUPLE" TUP)
	#DECL ((TUP) <TUPLE ATOM ATOM>)
	<ASSEMERR1 !.TUP>
	<AGAIN .READ-LOOP>>

<DEFINE ASSEMERR1 ("TUPLE" TUP)
	#DECL ((TUP) <TUPLE ATOM ATOM>)
	<SETG ASSEMERRS <+ ,ASSEMERRS 1>>
	<COND (,REAL-ERROR? <ERROR !.TUP>)
	      (T
	       <BLOCK (<GET ERRORS OBLIST> !.OBLIST)>
	       <COND (,LONG-ERRORS? <MAPF <> ,PRINT .TUP> <CRLF>)
		     (<CRLF>
		      <PRIN1 <1 .TUP>>
		      <PRINC <ASCII 32>>
		      <PRIN1 <2 .TUP>>)>
	       <ENDBLOCK>)>>

"********** RANDOM TYPE DEFINITION STUFF **********"

<NEWTYPE LABEL WORD>
<NEWTYPE PLABEL WORD>
<NEWTYPE VAR WORD>

<PUT NUMBER DECL '<OR ATOM FIX>>


"********** PSEUDO-OP HANDLERS **********"

<BLOCK (!.OBLIST <SETG GLOBALS <MOBLIST GLOBALS 97>>)>
<MOBLIST UNDEFINED>

<DEFOPS ,GLOBALS>		;"DEFINE THE OPERATIONS IN THIS OBLIST"

<MAPF <>
      <FUNCTION (ATM) <INSERT <REMOVE .ATM> ,GLOBALS>>
      '[*WORD
	*BYTE
	*TRUE
	*FALSE
	*ZWORD
	*GSTR
	*STR
	*LEN
	*STRL
	*EQUAL
	*PDEF
	*SEQ
	*TABLE
	*PROP
	*ENDT
	*OBJECT
	*GVAR
	*FUNCT
	*INSERT
	*ENDI
	*END]>

<DEFINE P*WORD (ARGL)
	#DECL ((ARGL) <LIST ATOM [REST NUMBER]>)
	<COND (,PASS1? <SETG ZPC <+ ,ZPC <* 2 <LENGTH <REST .ARGL>>>>>)
	      (<MAPF <> ,OUTWORD <REST .ARGL>>)>>

<DEFINE P*BYTE (ARGL)
	#DECL ((ARGL) <LIST ATOM [REST NUMBER]>)
	<COND (,PASS1? <SETG ZPC <+ ,ZPC <LENGTH <REST .ARGL>>>>)
	      (<MAPF <> ,OUTBYTE <REST .ARGL>>)>>

<DEFINE P*TRUE (ARGL)
	#DECL ((ARGL) !<LIST ATOM>)
	<SETG STATEMENTS ('(1) !,STATEMENTS)>>

<DEFINE P*FALSE (ARGL)
	#DECL ((ARGL) !<LIST ATOM>)
	<SETG STATEMENTS ('(0) !,STATEMENTS)>>

<DEFINE P*ZWORD (ARGL "AUX" (STR <2 .ARGL>) (LEN <LENGTH .STR>))
	#DECL ((ARGL) !<LIST ATOM ZSTR>
	       (STR) ZSTR
	       (LEN) FIX)
	<COND (<==? .LEN 6>)
	      (<L? .LEN 6>
	       <SET STR <CHTYPE <SUBSTRUC .STR 0 .LEN <IBYTES 5 6 ,PADCHR>>
				ZSTR>>)
	      (<SET STR <CHTYPE <SUBSTRUC .STR 0 6> ZSTR>>)>
	<SETG STATEMENTS ((.STR) !,STATEMENTS)>>

<DEFINE P*GSTR (ARGL)
	#DECL ((ARGL) !<LIST ATOM ATOM ZSTR>)
	<SETG STATEMENTS
	      ((*PDEF <2 .ARGL>)
	       (*STR <3 .ARGL>)
	       !,STATEMENTS)>>

<DEFINE P*STR (ARGL "AUX" (STR <2 .ARGL>))
	#DECL ((ARGL) !<LIST ATOM ZSTR>
	       (STR) ZSTR)
	<AND <EMPTY? .STR> <SET STR <CHTYPE <BYTES 5 ,PADCHR> ZSTR>>>
	<COND (,PASS1?
	       <SETG ZPC <+ ,ZPC <* 2 </ <+ 2 <LENGTH <2 .ARGL>>> 3>>>>)
	      (<OUTSTR <2 .ARGL>>)>>

<DEFINE P*LEN (ARGL)
	#DECL ((ARGL) !<LIST ATOM ZSTR>)
	<SETG STATEMENTS ((*BYTE </ <+ 2 <LENGTH <2 .ARGL>>> 3>)
			  !,STATEMENTS)>> 

<DEFINE P*STRL (ARGL)
	#DECL ((ARGL) !<LIST ATOM ZSTR>)
	<SETG STATEMENTS
	      ((*LEN <2 .ARGL>)
	       (*STR <2 .ARGL>)
	       !,STATEMENTS)>>

<DEFINE P*EQUAL (ARGL)
	#DECL ((ARGL) !<LIST ATOM ATOM NUMBER>)
	<AND <GASSIGNED? <2 .ARGL>>
	     <NOT <TYPE? ,<2 .ARGL> FIX>>
	     <ASSEMERR ARG-WRONG-TYPE!-ERRORS P*EQUAL .ARGL>>
	<AND <==? <OBLIST? <2 .ARGL>> ,LOCALS>
	     <ASSEMERR ATTEMPT-TO-ASSIGN-A-LOCAL!-ERRORS P*EQUAL .ARGL>>
	<INSERT <REMOVE <2 .ARGL>> ,GLOBALS>
	<SETG <2 .ARGL> <3 .ARGL>>>

<DEFINE P*PDEF (ARGL)
	#DECL ((ARGL) !<LIST ATOM ATOM>)
	<AND <1? <CHTYPE <ANDB ,ZPC 1> FIX>> <SETG ZPC <+ ,ZPC 1>>>
	<AND <GASSIGNED? <2 .ARGL>>
	     <NOT <==? ,<2 .ARGL> <CHTYPE ,ZPC PLABEL>>>
	     <ASSEMERR ARG-WRONG-TYPE!-ERRORS P*PDEF .ARGL>>
	<INSERT <REMOVE <2 .ARGL>> ,GLOBALS>
	<SETG <2 .ARGL> <CHTYPE ,ZPC PLABEL>>>

<DEFINE P*SEQ (ARGL "AUX" (N -1))
	#DECL ((ARGL) <LIST ATOM [REST ATOM]>
	       (N) FIX)
	<SETG STATEMENTS
	      (!<MAPF ,LIST
		      <FUNCTION (ATM)
				#DECL ((VALUE) LIST
				       (ATM) ATOM)
				(*EQUAL .ATM !\, <SET N <+ .N 1>>)>
		      <REST .ARGL>>
	       !,STATEMENTS)>>

<DEFINE P*TABLE (ARGL)
	#DECL ((ARGL) !<LIST ATOM [OPT FIX]>)
	<OR <0? ,TABLE-END>
	    <ASSEMERR ILLEGAL-TABLE-NESTING!-ERRORS P*TABLE .ARGL>>
	<SETG TABLE-END
	      <COND (<LENGTH? .ARGL 2> *377777777777*)
		    (<+ ,ZPC <3 .ARGL>>)>>>

%%<SETG ERR '<ASSEMERR ARG-WRONG-TYPE!-ERRORS P*PROP .ARGL>>
<DEFINE P*PROP (ARGL "AUX" (N1 <2 .ARGL>) (N2 <3 .ARGL>))
	#DECL ((ARGL) !<LIST ATOM NUMBER NUMBER>
	       (N1 N2) NUMBER)
	<AND <0? ,TABLE-END> <ASSEMERR NOT-IN-TABLE!-ERRORS P*PROP .ARGL>>
	<AND <OR <AND <TYPE? .N1 ATOM>
		      <GASSIGNED? .N1>
		      <NOT <TYPE? ,.N1 FIX>>>
		 <AND <TYPE? .N2 ATOM>
		      <GASSIGNED? .N2>
		      <NOT <TYPE? ,.N2 FIX>>>>
	     %,ERR>
	<SETG STATEMENTS
	      ((*BYTE <COND (,PASS1? 0)
			    (T
			     <COND (<TYPE? .N1 ATOM>
				    <OR <AND <GASSIGNED? .N1>
					     <TYPE? ,.N1 FIX>>
					%,ERR>
				    <SET N1 ,.N1>)>
			     <COND (<TYPE? .N2 ATOM>
				    <OR <AND <GASSIGNED? .N2>
					     <TYPE? ,.N2 FIX>>
					%,ERR>
				    <SET N2 ,.N2>)>
			     <AND <OR <L? .N1 1>
				      <L? .N2 1>
				      <G? .N1 8>
				      <G? .N2 31>>
				  <ASSEMERR NUMBER-OUT-OF-RANGE!-ERRORS
					 P*PROP
					 .ARGL>>
			     <CHTYPE <ORB <* <- .N1 1> 32> .N2> FIX>)>)
	       !,STATEMENTS)>>

<DEFINE P*ENDT (ARGL)
	#DECL ((ARGL) !<LIST ATOM>)
	<AND <0? ,TABLE-END> <ASSEMERR NOT-IN-TABLE!-ERRORS P*ENDT .ARGL>>
	<AND <G? ,ZPC ,TABLE-END>
	     <ASSEMERR TABLE-TOO-LARGE!-ERRORS P*ENDT .ARGL ,TABLE-END ,ZPC>>
	<SETG TABLE-END 0>>

<DEFINE P*OBJECT (ARGL)
	#DECL ((ARGL) !<LIST ATOM ATOM [5 NUMBER] ATOM>)
	<SETG STATEMENTS
	      ((*EQUAL <2 .ARGL> !\, <SETG CUROBJ <+ ,CUROBJ 1>>)
	       (*WORD <3 .ARGL> !\, <4 .ARGL>)
	       (*BYTE <5 .ARGL> !\, <6 .ARGL> !\, <7 .ARGL>)
	       (*WORD <8 .ARGL>)
	       !,STATEMENTS)>>

<DEFINE P*GVAR (ARGL "AUX" ATM VAL)
	#DECL ((ARGL) !<LIST ATOM <OR ATOM <LIST ATOM NUMBER>>>
	       (ATM) ATOM
	       (VAL) NUMBER)
	<COND (<TYPE? <2 .ARGL> ATOM> <SET ATM <2 .ARGL>> <SET VAL 0>)
	      (<SET ATM <1 <2 .ARGL>>> <SET VAL <2 <2 .ARGL>>>)>
	<AND <GASSIGNED? .ATM>
	     <N==? ,.ATM <CHTYPE <+ ,CURGVAR 1> VAR>>
	     <ASSEMERR ILLEGAL-SYMBOL-ASSIGNMENT!-ERRORS P*GVAR .ARGL>>
	<INSERT <REMOVE .ATM> ,GLOBALS>
	<SETG .ATM <CHTYPE <SETG CURGVAR <+ ,CURGVAR 1>> VAR>>
	<SETG STATEMENTS ((*WORD .VAL) !,STATEMENTS)>>

<DEFINE P*FUNCT (ARGL "AUX" (CURLVAR 0))
	#DECL ((ARGL) <LIST ATOM ATOM [REST <OR ATOM <LIST ATOM NUMBER>>]>
	       (CURLVAR) FIX)
	<AND <1? <CHTYPE <ANDB 1 ,ZPC> FIX>> <SETG ZPC <+ ,ZPC 1>>>
	<PUT ,ZOB 1 <SETG LOCALS <MOBLIST <2 .ARGL> 5>>>
	<SETG STATEMENTS
	      ((*PDEF <2 .ARGL>)
	       (*BYTE <- <LENGTH .ARGL> 2>)
	       !<MAPF ,LIST
		      <FUNCTION (ARG "AUX" ATM VAL)
				#DECL ((VALUE) LIST
				       (ARG) <OR ATOM <LIST ATOM NUMBER>>
				       (ATM) ATOM
				       (VAL) NUMBER)
				<COND (<TYPE? .ARG ATOM>
				       <SET ATM .ARG>
				       <SET VAL 0>)
				      (<SET ATM <1 .ARG>>
				       <SET VAL <2 .ARG>>)>
				<OR <GASSIGNED? .ATM> <REMOVE .ATM>>
				<SET ATM <OR <LOOKUP <SPNAME .ATM> ,LOCALS>
					     <INSERT <SPNAME .ATM> ,LOCALS>>>
				<SETG .ATM
				      <CHTYPE <SET CURLVAR <+ .CURLVAR 1>>
					      VAR>>
				(*WORD .VAL)>
		      <REST .ARGL 2>>
	       !,STATEMENTS)>>

<DEFINE P*INSERT (ARGL "AUX" NZIN)
	#DECL ((ARGL) !<LIST ATOM ZSTR>)
	<PRINC "*** P*INSERT(">
	<PRINC .ARGL>
	<PRINC ")***">
	<CRLF>
	<COND (<SET NZIN <OPEN "READ" <STRING <ZSTR-STRING <2 .ARGL>> ;".ZAP"> "ZAP">>
	       <SETG OZINS (,ZIN !,OZINS)>
	       <SETG ZIN .NZIN>)
	      (<ASSEMERR OPEN-FAILED!-ERRORS P*INSERT .ARGL .NZIN>)>>

<DEFINE P*ENDI (ARGL)
	#DECL ((ARGL) !<LIST ATOM>)
	<AND <EMPTY? ,OZINS>
	     <ASSEMERR ILLEGAL-OPERATION!-ERRORS P*ENDI .ARGL>>
	<CLOSE ,ZIN>
	<SETG ZIN <1 ,OZINS>>
	<SETG OZINS <REST ,OZINS>>>

<SETG P*END ,ERROR>		;".END should never get this far"


"********** GLOBAL TABLES *********"

<NEWTYPE PSEUDO LIST '<PSEUDO <OR FORM SEGMENT> APPLICABLE>>

<SETG DEFPSEUDO <FUNCTION (PA 'DCL)
			  <SETG .PA
				<CHTYPE (.DCL
					 ,<PARSE <STRING "P" <SPNAME .PA>>>)
					PSEUDO>>>>
<DEFPSEUDO	*WORD	<LIST [REST NUMBER]>>
<DEFPSEUDO	*BYTE	<LIST [REST NUMBER]>>
<DEFPSEUDO	*TRUE	<>>
<DEFPSEUDO	*FALSE	<>>
<DEFPSEUDO	*ZWORD	!<LIST ZSTR>>
<DEFPSEUDO	*GSTR	!<LIST ATOM ZSTR>>
<DEFPSEUDO	*STR	!<LIST ZSTR>>
<DEFPSEUDO	*LEN	!<LIST ZSTR>>
<DEFPSEUDO	*STRL	!<LIST ZSTR>>
<DEFPSEUDO	*EQUAL	!<LIST ATOM NUMBER>>
<DEFPSEUDO	*PDEF	!<LIST ATOM>>
<DEFPSEUDO	*SEQ	<LIST [REST ATOM]>>
<DEFPSEUDO	*TABLE	!<LIST [OPT FIX]>>
<DEFPSEUDO	*PROP	!<LIST [2 NUMBER]>>
<DEFPSEUDO	*ENDT	<>>
<DEFPSEUDO	*OBJECT	!<LIST ATOM [5 NUMBER] ATOM>>
<DEFPSEUDO	*GVAR	!<LIST <OR ATOM <LIST ATOM NUMBER>>>>
<DEFPSEUDO	*FUNCT	<LIST ATOM [REST <OR ATOM <LIST ATOM NUMBER>>]>>
<DEFPSEUDO	*INSERT	!<LIST ZSTR>>
<DEFPSEUDO	*ENDI	<>>
<DEFPSEUDO	*END	<>>

<SETG DEFGLOBAL
      <FUNCTION (STR VAL)
		<SETG <OR <LOOKUP .STR ,GLOBALS> <INSERT .STR ,GLOBALS>>
		      .VAL>>>

<DEFGLOBAL "STACK" #VAR 0>
<DEFGLOBAL "FALSE" #LABEL 0>
<DEFGLOBAL "TRUE" #LABEL 1>
<DEFGLOBAL "NOJUMP" #LABEL 2>


"********** Z-CODE READ TABLE DEFINITION **********"

<SETG ZCHR <FUNCTION (CHR ACTION) <PUT ,ZRT <+ <ASCII .CHR> 1> .ACTION>>>

<DEFINE NOP-CHR (C)
	#DECL ((VALUE C) CHARACTER)
	.C>

<DEFINE FLUSH-COMMENT (C)
	#DECL ((VALUE) SPLICE
	       (C) CHARACTER)
	<REPEAT () <AND <==? <READCHR> <ASCII 13>> <RETURN>>>
	#SPLICE ()>

<DEFINE READ-ZSTR (C)
	#DECL ((VALUE) ZSTR
	       (C) CHARACTER)
	<STRING-ZSTR
	 <MAPF ,STRING
	       <FUNCTION ()
			 #DECL ((VALUE) CHARACTER)
			 <COND (<N==? <SET C <READCHR>> !\"> .C)
			       (<==? <NEXTCHR> !\"> <READCHR>)
			       (<MAPSTOP>)>>>>>

<DEFINE QUOTE-FUNCT (C "AUX" OBJ)
	#DECL ((VALUE) FIX
	       (C) CHARACTER
	       (OBJ) ANY)
	<COND (<AND <TYPE? <SET OBJ <READ>> ATOM>
		    <GASSIGNED? .OBJ>
		    <TYPE? ,.OBJ VAR>>
	       <CHTYPE ,.OBJ FIX>)
	      (T
	       <ASSEMERR1 BAD-USE-OF-QUOTE!-ERRORS QUOTE-FUNCT .OBJ>
	       0)>>

<SETG ZRT <IVECTOR 128 65>>	;"MOST CHARACTERS ARE SYMBOL CONSTITUENTS"

<ZCHR !\0 0>			;"NUMBERS REMAIN NUMBERS"
<ZCHR !\1 0>
<ZCHR !\2 0>
<ZCHR !\3 0>
<ZCHR !\4 0>
<ZCHR !\5 0>
<ZCHR !\6 0>
<ZCHR !\7 0>
<ZCHR !\8 0>
<ZCHR !\9 0>
<ZCHR !\- 0>
<ZCHR !\, ,NOP-CHR>		;"RETURN SPECIAL CHARS AS THEMSELVES"
<ZCHR !\: ,NOP-CHR>
<ZCHR !\+ ,NOP-CHR>
<ZCHR !\/ ,NOP-CHR>
<ZCHR !\\\ ,NOP-CHR>
<ZCHR !\> ,NOP-CHR>
<ZCHR !\= ,NOP-CHR>
<ZCHR !\; ,FLUSH-COMMENT>	;"IGNORE COMMENTS"
<ZCHR !\' ,QUOTE-FUNCT>		;"QUOTED SYMBOLS ARE IMMEDIATELY TRANSLATED"
<ZCHR <ASCII 32> 0>		;"STANDARD SEPARATORS"
<ZCHR <ASCII 9> 0>
<ZCHR <ASCII 13> 0>
<ZCHR <ASCII 10> ,NOP-CHR>	;"LINE-FEEDS ARE SIGNIFICANT"
<ZCHR !\" ,READ-ZSTR>		;"GET A STRING"
<ZCHR !\. !\*>			;"CONVERT PERIODS (BLETCH!)"
<ZCHR <ASCII 3> 0>		;"PSEUDO-EOF CHARACTER"
<ZCHR <ASCII 26> 0>		;"DON'T DISABLE EOF"


"********** STATEMENT READING AND PARSING STUFF **********"

<DEFINE READ-STATEMENT (ZOB SCRIPT "AUX" (INCHAN ,ZIN)
					 (ZRT ,ZRT)
					 (OTHING T)
					 RET)
	#DECL ((VALUE RET) <OR LIST FALSE>
	       (ZOB) <LIST [REST <OR OBLIST ATOM>]>
	       (INCHAN) <SPECIAL CHANNEL>
	       (ZRT) <SPECIAL VECTOR>
	       (OTHING) <OR ATOM CHARACTER FIX ZSTR>
	       (SCRIPT) <OR CHANNEL FALSE>)
	<COND
	 (<EMPTY? ,STATEMENTS>
	  <SET RET
	       <MAPF ,LIST
		     <FUNCTION ("AUX" THING)
			       #DECL ((VALUE THING)
				      <OR ATOM CHARACTER FIX ZSTR>)
			       <COND (<N==? <SET THING <READ .INCHAN
							     '<MAPLEAVE <>>
							     .ZOB
							     .ZRT>>
					    <ASCII 10>>
				      <SET OTHING .THING>)
				     (<AND <TYPE? .OTHING CHARACTER>
					   <MEMQ .OTHING ",/\\>+=">>
				      <MAPRET>)
				     (<MAPSTOP>)>>>>)
	 (<SET RET <1 ,STATEMENTS>>
	  <SETG STATEMENTS <REST ,STATEMENTS>>
	  <AND .SCRIPT <PRINC <ASCII 9> .SCRIPT>>)>
	<COND (<AND .SCRIPT <NOT <EMPTY? .RET>>>
	       <SET OTHING !\,>
	       <PRINC !\( .SCRIPT>
	       <MAPF <>
		     <FUNCTION (THING)
			       <COND (<TYPE? .THING CHARACTER>)
				     (<OR <TYPE? .OTHING ATOM>
					  <==? .OTHING !\:>>
				      <PRINC <ASCII 32> .SCRIPT>)>
			       <PRINC <SET OTHING .THING> .SCRIPT>>
		     .RET>
	       <PRINC !\) .SCRIPT>)>
	<COND (<NOT ,DTRACE?>)
	      (,PASS1?)
	      (<G? ,ZPC ,DSBOT>
	       <SET OTHING !\,>
	       <SETG LASTSYM
		     <MAPF ,STRING
			   <FUNCTION (THING "AUX" (SPACE? <>))
				     #DECL ((VALUE) <OR STRING CHARACTER>
					    (SPACE?) <OR ATOM FALSE>)
				     <COND (<TYPE? .THING CHARACTER>)
					   (<OR <TYPE? .OTHING ATOM>
						<==? .OTHING !\:>>
					    <SET SPACE? T>)>
				     <SET OTHING .THING>
				     <SET THING
					  <COND (<TYPE? .THING ATOM>
						 <SPNAME .THING>)
						(<TYPE? .THING CHARACTER>
						 .THING)
						(<TYPE? .THING ZSTR>
						 <MAPRET>)
						(<UNPARSE .THING>)>>
				     <AND .SPACE? <MAPRET <ASCII 32> .THING>>
				     .THING>
			   .RET>>)>
	.RET>

%%<SETG ERR '<RETURN <ASSEMERR ZAP-SYNTAX-ERROR!-ERRORS GET-STATEMENT .SL>>>
%%<SETG ERR1
	'<RETURN <ASSEMERR ZAP-SYNTAX-ERROR!-ERRORS GET-STATEMENT .SL .ARGL>>>
<DEFINE GET-STATEMENT (ZOB SCRIPT "AUX" SL)
	#DECL ((VALUE) <OR LIST FALSE>
	       (ZOB) <LIST [REST <OR OBLIST ATOM>]>
	       (SCRIPT) <OR CHANNEL FALSE>
	       (SL) <OR <LIST [REST <OR ATOM ZSTR FIX CHARACTER>]> FALSE>)
	<AND .SCRIPT <PRINT ,ZPC .SCRIPT>>
	<PROG
	 ((OARG !\,) (EQUALS? <>) (ADD? <>) (SKIP? <>) (ADDVAL 0))
	 #DECL ((VALUE) <OR LIST FALSE>
		(OARG) <OR ATOM ZSTR FIX CHARACTER LIST>
		(EQUALS? ADD? SKIP?) <OR ATOM FALSE>
		(ADDVAL) FIX)
	 <COND (<NOT <SET SL <READ-STATEMENT .ZOB .SCRIPT>>>
		<ASSEMERR PREMATURE-END-OF-FILE!-ERRORS GET-STATEMENT>)
	       (<EMPTY? .SL> <AGAIN>)
	       (<==? <1 .SL> *END> <>)
	       (<SETG INS <+ ,INS 1>>
		<AND <TYPE? <1 .SL> ATOM>
		     <NOT <EMPTY? <REST .SL>>>
		     <==? <2 .SL> !\:>
		     <COND (<AND <NOT <EMPTY? <REST .SL 2>>>
				 <==? <3 .SL> !\:>>
			    <DEFINE-LABEL <1 .SL> T>
			    <SET SL <REST .SL 3>>)
			   (T
			    <DEFINE-LABEL <1 .SL>>
			    <SET SL <REST .SL 2>>)>>
		<AND <EMPTY? .SL> <AGAIN>>
		<AND <TYPE? <1 .SL> ZSTR>
		     <OR <LENGTH? .SL 1> %,ERR>
		     <RETURN (*STR <1 .SL>)>>
		<AND <TYPE? <1 .SL> FIX> <SET SL (*WORD !.SL)>>
		<AND <TYPE? <1 .SL> CHARACTER> %,ERR>
		<AND <NOT <EMPTY? <REST .SL>>>
		     <==? <2 .SL> !\=>
		     <OR <==? <LENGTH .SL> 3> %,ERR>
		     <OR <TYPE? <3 .SL> ATOM FIX> %,ERR>
		     <RETURN (*EQUAL <1 .SL> <3 .SL>)>>
		<AND <OR <NOT <GASSIGNED? <1 .SL>>>
			 <NOT <TYPE? ,<1 .SL> OP PSEUDO>>>
		     <SET SL (*WORD !.SL)>>
		(<1 .SL>
		 !<MAPR ,LIST
			<FUNCTION
			 (ARGL "AUX" (ARG <1 .ARGL>))
			 #DECL ((VALUE) ANY
				(ARGL) LIST
				(ARG) <OR ATOM ZSTR FIX CHARACTER>)
			 <SET OARG
			      <COND (.SKIP? <SET SKIP? <>> <MAPRET>)
				    (.ADD?
				     <SET ADD? <>>
				     <COND (<TYPE? .ARG FIX>
					    <SET ADDVAL <+ .ADDVAL .ARG>>)
					   (<AND <TYPE? .ARG ATOM>
						 <GASSIGNED? .ARG>
						 <TYPE? ,.ARG FIX>>
					    <SET ADDVAL <+ .ADDVAL ,.ARG>>)
					   (%,ERR1)>
				     <AND <NOT <EMPTY? <REST .ARGL>>>
					  <==? <2 .ARGL> !\+>
					  <SET SKIP? <SET ADD? T>>
					  <MAPRET>>
				     <COND (.EQUALS? 
					    <SET EQUALS? <>>
					    (.OARG .ADDVAL))
					   (<==? .OARG !\,> .ADDVAL)
					   ((.ADDVAL .OARG))>)
				    (.EQUALS?
				     <AND <TYPE? .ARG CHARACTER> %,ERR1>
				     <COND (<AND <TYPE? .ARG ATOM FIX>
						 <NOT <EMPTY? <REST .ARGL>>>
						 <==? <2 .ARGL> !\+>>
					    <COND (<TYPE? .ARG FIX>
						   <SET ADDVAL .ARG>)
						  (<AND <GASSIGNED? .ARG>
							<TYPE? ,.ARG FIX>>
						   <SET ADDVAL ,.ARG>)
						  (%,ERR1)>
					    <SET SKIP? <SET ADD? T>>
					    <MAPRET>)>
				     <SET EQUALS? <>>
				     (.OARG .ARG))
				    (<TYPE? .ARG CHARACTER>
				     <COND (<NOT <TYPE? .OARG CHARACTER>>)
					   (<AND <==? .ARGL <REST .SL>>
						 <N==? .ARG !\,>>)
					   (%,ERR1)>
				     <OR <MEMQ .ARG ",>/\\"> %,ERR1>
				     <SET OARG .ARG>
				     <MAPRET>)
				    (<==? .OARG !\,>
				     <OR <EMPTY? <REST .ARGL>>
					 <COND (<==? <2 .ARGL> !\+>
						<COND (<TYPE? .ARG FIX>
						       <SET ADDVAL .ARG>)
						      (<AND <TYPE? .ARG ATOM>
							    <GASSIGNED? .ARG>
							    <TYPE? ,.ARG FIX>>
						       <SET ADDVAL ,.ARG>)
						      (%,ERR1)>
						<SET SKIP? <SET ADD? T>>
						<MAPRET>)
					       (<==? <2 .ARGL> !\=>
						<OR <TYPE? .ARG ATOM> %,ERR1>
						<SET OARG .ARG>
						<SET SKIP? <SET EQUALS? T>>
						<MAPRET>)>>
				     .ARG)
				    (<TYPE? .OARG CHARACTER> (.ARG .OARG))
				    (%,ERR1)>>>
			<REST .SL>>))>>>


"********** LOWER LEVEL STUFF **********"

%%<SETG ERR '<ASSEMERR ILLEGAL-SYMBOL-ASSIGNMENT!-ERRORS
		       DEFINE-LABEL
		       .LBL
		       .GLOBAL?
		       ,ZPC>>
<DEFINE DEFINE-LABEL (LBL "OPTIONAL" (GLOBAL? <>)
			  "AUX" (OB <COND (.GLOBAL? ,GLOBALS) (,LOCALS)>))
	#DECL ((VALUE LBL) ATOM
	       (GLOBAL?) <OR ATOM FALSE>
	       (OB) OBLIST)
	<COND (,PASS1?
	       <AND <GASSIGNED? .LBL> %,ERR>
	       <SETG .LBL <CHTYPE ,ZPC LABEL>>
	       <INSERT <REMOVE .LBL> .OB>)
	      (<AND <GASSIGNED? .LBL>
		    <==? ,.LBL <CHTYPE ,ZPC LABEL>>
		    <==? <OBLIST? .LBL> .OB>>
	       .LBL)
	      (%,ERR)>>

<DEFINE ARG-TYPE (ARG)
	#DECL ((VALUE) FIX
	       (ARG) ANY)
	<AND <TYPE? .ARG ATOM> <SET ARG ,.ARG>>
	<COND (<TYPE? .ARG VAR> 2)
	      (<AND <TYPE? .ARG FIX> <L? .ARG 256> <G=? .ARG 0>> 1)
	      (<TYPE? .ARG FIX LABEL PLABEL> 0)
	      (<ASSEMERR ARG-WRONG-TYPE!-ERRORS ARG-TYPE .ARG>)>>

%%<SETG ERR '<ASSEMERR ARG-WRONG-TYPE!-ERRORS OPERATION .ARGL>>
<DEFINE OPERATION (ARGL "AUX" (ZOP ,<1 .ARGL>)
			      (AL <REST .ARGL>)
			      NARGS
			      (XARGS 0)
			      (NBYTES 1)
			      (CD <OPCODE .ZOP>)
			      TYP
			      TYP2
			      NUM
			      DEST)
	#DECL ((VALUE XARGS NARGS NBYTES CD TYP TYP2 NUM) FIX
	       (ARGL) <LIST ATOM>
	       (ZOP) OP
	       (AL) LIST
	       (DEST) WORD)
	<COND
	 (<SPEC? .ZOP "STRING">
	  <OR <AND <1? <LENGTH .AL>> <TYPE? <1 .AL> ZSTR>>
	      %,ERR>
	  <COND (,PASS1?
		 <SETG ZPC <+ ,ZPC 1 <* 2 </ <+ <LENGTH <1 .AL>> 2> 3>>>>)
		(<OUTBYTE .CD>
		 <OUTSTR <1 .AL>>)>)
	 (T
	  <AND <PRED? .ZOP> <SET XARGS 1>>
	  <COND (<VAL? .ZOP>
		 <SET XARGS <+ .XARGS 1>>
		 <SET NUM <LENGTH .AL>>
		 <AND <PRED? .ZOP> <SET NUM <- .NUM 1>>>
		 <COND (<L? .NUM 0>)
		       (<EMPTY? .AL> <SET AL '(STACK !\>)>)
		       (<0? .NUM> <SET AL (<1 .AL> '(STACK !\>))>)
		       (<AND <TYPE? <NTH .AL .NUM> LIST>
			     <==? <2 <NTH .AL .NUM>> !\>>>)
		       (<PUTREST <REST .AL <- .NUM 1>>
				 ('(STACK !\>) !<REST .AL .NUM>)>)>)>
	  <SET NARGS <COND (<L? .CD 128> 2)
			   (<L? .CD 176> 1)
			   (<L? .CD 192> 0)
			   (<- <LENGTH .AL> .XARGS>)>>
	  <AND <SPEC? .ZOP "XARGS">
	       <G? <LENGTH .AL> <+ .NARGS .XARGS>>
	       <SET NARGS <- <LENGTH .AL> .XARGS>>>
	  <OR <AND <==? <LENGTH .AL> <+ .NARGS .XARGS>>
		   <G=? .NARGS 0>
		   <L=? .NARGS 4>>
	      <ASSEMERR WRONG-NUMBER-OF-ARGUMENTS!-ERRORS OPERATION .ARGL>>
	  <MAPF <>
		<FUNCTION (ARG)
			  <AND <0? .NARGS>
			       <L? .CD 128>
			       <G? .NBYTES 3>
			       <SET NBYTES <+ .NBYTES 1>>>
			  <COND (<L? .NARGS 1>
				 <COND (<OR <AND <0? .NARGS> <==? .XARGS 2>>
					    <NOT <PRED? .ZOP>>>
					<OR <AND <TYPE? .ARG LIST>
						 <==? <2 .ARG> !\>>
						 <TYPE? <1 .ARG> ATOM>
						 <GASSIGNED? <1 .ARG>>
						 <TYPE? ,<1 .ARG> VAR>>
					    %,ERR>
					<SET NBYTES <+ .NBYTES 1>>)
				       (<AND <TYPE? .ARG LIST>
					     <MEMQ <2 .ARG> "/\\">
					     <TYPE? <1 .ARG> ATOM>>
					<SET NBYTES
					     <+ .NBYTES
						<COND
						 (<NOT <GASSIGNED? <1 .ARG>>>
						  <OR ,PASS1? %,ERR>
						  2)
						 (<TYPE? ,<1 .ARG>
							 LABEL
							 PLABEL>
						  <COND (<L? <CHTYPE ,<1 .ARG>
								     FIX>
							     3>
							 1)
							(2)>)
						 (%,ERR)>>>)
				       (%,ERR)>)
				(<TYPE? .ARG FIX>
				 <SET NBYTES
				      <+ .NBYTES
					 <COND (<OR <G? .ARG 255> <L? .ARG 0>>
						2)
					       (1)>>>)
				(<TYPE? .ARG ATOM>
				 <SET NBYTES
				      <+ .NBYTES
					 <COND (<GASSIGNED? .ARG>
						<SET ARG ,.ARG>
						<COND (<TYPE? .ARG VAR> 1)
						      (<AND <TYPE? .ARG FIX>
							    <L? .ARG 256>
							    <G=? .ARG 0>>
						       1)
						      (<TYPE? .ARG
							      FIX
							      LABEL
							      PLABEL>
						       2)
						      (%,ERR)>)
					       (<NOT ,PASS1?> %,ERR)
					       (2)>>>)
				(%,ERR)>
			  <SET NARGS <- .NARGS 1>>>
		.AL>
	  <AND <L? .CD 128>
	       <NOT <PRED? .ZOP>>
	       <NOT <VAL? .ZOP>>
	       <G? .NBYTES 3>
	       <SET NBYTES <+ .NBYTES 1>>>
	  <AND <G=? .CD 192> <SET NBYTES <+ .NBYTES 1>>>
	  <COND
	   (,PASS1? <SETG ZPC <+ ,ZPC .NBYTES>>)
	   (<SET NARGS <- <LENGTH .AL> .XARGS>>
	    <COND
	     (<AND <0? .NARGS> <L? .CD 192>> <OUTBYTE .CD>)
	     (<AND <1? .NARGS> <L? .CD 192>>
	      <COND (<0? <SET TYP <ARG-TYPE <1 .AL>>>>
		     <OUTBYTE .CD>
		     <COND (<SPEC? .ZOP "BRANCH">
			    <OUTWORD <1 .AL> <- ,ZPC>>)
			   (<OUTWORD <1 .AL>>)>)
		    (<1? .TYP>
		     <OUTBYTE .CD 16>
		     <OUTBYTE <1 .AL>>)
		    (T
		     <OUTBYTE .CD 32>
		     <OUTBYTE <1 .AL>>)>)
	     (<AND <L? .CD 192> <==? .NARGS 2>>
	      <COND (<0? <* <SET TYP <ARG-TYPE <1 .AL>>>
			    <SET TYP2 <ARG-TYPE <2 .AL>>>>>
		     <OUTBYTE .CD 192>
		     <OUTBYTE 12 <* .TYP 64> <* .TYP2 16>>
		     <COND (<0? .TYP> <OUTWORD <1 .AL>>) (<OUTBYTE <1 .AL>>)>
		     <COND (<0? .TYP2> <OUTWORD <2 .AL>>) (<OUTBYTE <2 .AL>>)>)
		    (<OUTBYTE .CD <* <- .TYP 1> 64> <* <- .TYP2 1> 32>>
		     <OUTBYTE <1 .AL>>
		     <OUTBYTE <2 .AL>>)>)
	     (T
	      <COND (<L? .CD 128> <OUTBYTE .CD 192>) (<OUTBYTE .CD>)>
	      <REPEAT ((TYPS <ILIST 4 3>) (CTYPS .TYPS) (NA .NARGS) (L .AL))
		      #DECL ((TYPS) <LIST [4 FIX]>
			     (CTYPS) <LIST [REST FIX]>
			     (NA) FIX
			     (L) LIST)
		      <COND (<0? .NA>
			     <OUTBYTE <* <1 .TYPS> 64>
				      <* <2 .TYPS> 16>
				      <* <3 .TYPS> 4>
				      <4 .TYPS>>
			     <MAPF <>
				   <FUNCTION (ARG TYP)
					     #DECL ((ARG) ANY
						    (TYP) FIX)
					     <COND (<==? .TYP 3>)
						   (<0? .TYP> <OUTWORD .ARG>)
						   (<OUTBYTE .ARG>)>>
				   .AL
				   .TYPS>
			     <RETURN>)>
		      <PUT .CTYPS 1 <ARG-TYPE <1 .L>>>
		      <SET NA <- .NA 1>>
		      <SET CTYPS <REST .CTYPS>>
		      <SET L <REST .L>>>)>
	    <SET AL <REST .AL .NARGS>>
	    <COND (<VAL? .ZOP> <OUTBYTE <1 <1 .AL>>> <SET AL <REST .AL>>)>
	    <COND (<PRED? .ZOP>
		   <SET CD <COND (<==? <2 <1 .AL>> !\/> 128) (0)>>
		   <COND (<L? <SET NUM <CHTYPE ,<1 <1 .AL>> FIX>> 3>
			  <OUTBYTE .CD 64 .NUM>)
			 (T
			  <SET DEST <ANDB *37777* <- .NUM ,ZPC>>>
			  <OUTBYTE .CD </ <CHTYPE .DEST FIX> 256>>
			  <OUTBYTE <ANDB .DEST 255>>
			  ;"replaces
			    <OUTWORD <* .CD 256>
				   <ANDB *37777* <- .NUM ,ZPC>>>
			    since predicate jumps must not be byte-swapped")>)>
	    ,ZPC)>)>>

<DEFINE OUTBYTE ("TUPLE" TUP "AUX" (BYTE 0))
	#DECL ((VALUE BYTE) FIX
	       (TUP) <TUPLE [REST <OR ATOM <PRIMTYPE WORD>>]>)
	<MAPF <>
	      <FUNCTION (ARG)
			#DECL ((ARG) <OR ATOM <PRIMTYPE WORD>>)
			<COND (<TYPE? .ARG ATOM>
			       <OR <==? <PRIMTYPE ,.ARG> WORD>
				   <ASSEMERR ARG-WRONG-TYPE!-ERRORS
					     OUTBYTE
					     .ARG>>
			       <SET ARG ,.ARG>)>
			<SET BYTE <+ .BYTE <CHTYPE .ARG FIX>>>>
	      .TUP>
	<OR <AND <G=? .BYTE 0> <L? .BYTE 256>>
	    <ASSEMERR NUMBER-OUT-OF-RANGE!-ERRORS OUTBYTE .BYTE .TUP>>
	<COND (,SCRIPT
	       <PRINC !\  ,SCRIPT>
	       <PRIN1 <CHTYPE .BYTE FIX> ,SCRIPT>)>
	<PUT ,ZCODE <SETG ZPC <+ ,ZPC 1>> .BYTE>
	,ZPC>

<DEFINE OUTWORD ("TUPLE" TUP "AUX" (WRD 0) HIBYT LOBYT)
	#DECL ((VALUE WRD HIBYT LOBYT) FIX
	       (TUP) <TUPLE [REST <OR ATOM <PRIMTYPE WORD>>]>)
	<MAPF <>
	      <FUNCTION (ARG)
			#DECL ((ARG) <OR ATOM <PRIMTYPE WORD>>)
			<COND (<TYPE? .ARG ATOM>
			       <OR <==? <PRIMTYPE ,.ARG> WORD>
				   <ASSEMERR ARG-WRONG-TYPE!-ERRORS
					     OUTWORD
					     .ARG>>
			       <SET ARG ,.ARG>)>
			<SET WRD
			     <+ .WRD
				<COND (<TYPE? .ARG PLABEL>
				       </ <CHTYPE .ARG FIX> 2>)
				      (<CHTYPE .ARG FIX>)>>>>
	      .TUP>
	<COND (<OR <0? <CHTYPE <ANDB .WRD *777777600000*> FIX>>
		   <==? #WORD -1 <ORB .WRD *77777*>>>)
	      (<ASSEMERR NUMBER-OUT-OF-RANGE!-ERRORS OUTWORD .WRD>)>
	<COND (,SCRIPT
	       <PRINC " [" ,SCRIPT>
	       <PRIN1 <CHTYPE .WRD FIX> ,SCRIPT>
	       <PRINC !\] ,SCRIPT>)>
	<SET HIBYT </ <CHTYPE <ANDB .WRD *177777*> FIX> 256>>
	<SET LOBYT <CHTYPE <ANDB .WRD *377*> FIX>>
	<PUT ,ZCODE
	     <SETG ZPC <+ ,ZPC 1>>
	     <COND (,BYTE-SWAP? .LOBYT) (.HIBYT)>>
	<PUT ,ZCODE
	     <SETG ZPC <+ ,ZPC 1>>
	     <COND (,BYTE-SWAP? .HIBYT) (.LOBYT)>>
	,ZPC>

<DEFINE OUTSTR (STR "AUX" (BYTNUM 3) (WRD #WORD 0))
	#DECL ((VALUE BYTNUM) FIX
	       (STR) ZSTR
	       (WRD) WORD)
	<MAPR <>
	      <FUNCTION (BYTS)
			#DECL ((BYTS) <<PRIMTYPE BYTES> 5>)
			<SET WRD <ORB <1 .BYTS> <* <CHTYPE .WRD FIX> 32>>>
			<COND (<0? <SET BYTNUM <- .BYTNUM 1>>>
			       <COND (<EMPTY? <REST .BYTS>>
				      <OUTWORD .WRD *100000*>)
				     (<OUTWORD .WRD>)>
			       <SET BYTNUM 3>
			       <SET WRD #WORD 0>)>>
	      .STR>
	<COND (<==? .BYTNUM 3> ,ZPC)
	      (<SET WRD <ORB <* <CHTYPE .WRD FIX> 32> ,PADCHR>>
	       <OR <1? .BYTNUM>
		   <SET WRD <ORB <* <CHTYPE .WRD FIX> 32> ,PADCHR>>>
	       <OUTWORD .WRD *100000*>)>>


"********** HIGHER LEVEL STUFF **********"

<DEFINE ZAP-PASS ("AUX" (SCRIPT ,SCRIPT) (ZOB ,ZOB) (OTIME <TIME>))
	#DECL ((SCRIPT) <OR CHANNEL FALSE>
	       (ZOB) <LIST [REST <OR OBLIST ATOM>]>
	       (OTIME) FLOAT)
	<PRINC "ZAP pass #">
	<PRIN1 <COND (,PASS1? 1) (2)>>
	<SETG ASSEMERRS 0>
	<SETG ZPC 0>
	<SETG CUROBJ 0>
	<SETG CURGVAR 15>
	<SETG OZINS ()>
	<SETG INS 0>
	<SETG STATEMENTS
	      ((*BYTE!-GLOBALS ,ZAPID)
	       (*BYTE!-GLOBALS <COND (,BYTE-SWAP? 1) (0)>)
	       (ZORKID!-UNDEFINED)
	       (ENDLOD!-UNDEFINED)
	       (START!-UNDEFINED)
	       (VOCAB!-UNDEFINED)
	       (OBJECT!-UNDEFINED)
	       (GLOBAL!-UNDEFINED)
	       (IMPURE!-UNDEFINED)
	       !<ILIST 24 '(0)>)>
	<REPEAT READ-LOOP (SL)
		#DECL ((READ-LOOP) <SPECIAL ACTIVATION>
		       (SL) <OR LIST FALSE>)
		<OR <SET SL <GET-STATEMENT .ZOB .SCRIPT>> <RETURN>>
		<MAPF <>
		      <FUNCTION (ARG)
				#DECL ((ARG) <OR ATOM
						 FIX
						 ZSTR
						 <LIST ATOM
						       <OR NUMBER CHARACTER>>>)
				<COND (<TYPE? .ARG ATOM FIX ZSTR>)
				      (<TYPE? <2 .ARG> ATOM>
				       <SET ARG <2 .ARG>>)
				      (<SET ARG <1 .ARG>>)>
				<AND <TYPE? .ARG ATOM>
				     <REPEAT ()
					     <OR <AND <GASSIGNED? .ARG>
						      <TYPE? ,.ARG ATOM>>
						 <RETURN>>
					     <SET ARG ,.ARG>>>>
		      <REST .SL>>
		<COND (<TYPE? ,<1 .SL> OP>
		       <COND (<NOT ,DTRACE?>)
			     (,PASS1?
			      <AND <0? ,DSBOT> <SETG DSBOT <- ,ZPC 1>>>)
			     (T
			      <DSPRINT ,LASTSYM ,DSJFN>
			      <PUT ,DSYMBOLS <- ,ZPC ,DSBOT> ,DSPOS>
			      <SETG DSPOS <+ ,DSPOS <LENGTH ,LASTSYM> 1>>)>
		       <OPERATION .SL>)
		      (<COND (<EMPTY? <1 ,<1 .SL>>> <EMPTY? <REST .SL>>)
			     (<DECL? <REST .SL> <1 ,<1 .SL>>>)>
		       <APPLY <2 ,<1 .SL>> .SL>)
		      (<ASSEMERR ARG-WRONG-TYPE!-ERRORS ZAP-PASS .SL>)>>
	<PRINC " completed in ">
	<PRIN1 <FIX <- <TIME> .OTIME -.5>>>
	<PRINC " seconds.">
	<CRLF>>

<DEFINE ZAP (FILE "OPTIONAL" (SCRIPT <>) (LIST1? <>)
		  "AUX" ZIN UNDEF (OTIME <TIME>) SYMS)
	#DECL ((FILE) STRING
	       (SCRIPT) <OR STRING CHANNEL FALSE>
	       (ZIN) <OR CHANNEL FALSE>
	       (LIST1?) <OR ATOM FALSE>
	       (UNDEF) <LIST [REST ATOM]>
	       (OTIME) FLOAT
	       (SYMS) VECTOR)
	<AND <TYPE? .SCRIPT STRING> <SET SCRIPT <OPEN "PRINT" .SCRIPT>>>
	<AND <TYPE? .SCRIPT CHANNEL>
	     <PUT .SCRIPT 13 <CHTYPE <MIN> FIX>>>
	<COND (<SET ZIN <OPEN "READ" <STRING .FILE ;".ZAP">>>
	       <SETG ZIN .ZIN>)
	      (<ERROR OPEN-FAILED!-ERRORS ZAP .FILE .ZIN>)>
	<SETG PASS1? T>
	<SETG DSBOT 0>
	<SETG TABLE-END 0>
	<SETG ZOB (<SETG LOCALS <MOBLIST TOPLOCALS 1>>
		   ,GLOBALS
		   DEFAULT
		   <GET UNDEFINED OBLIST>)>
	<SETG SCRIPT <AND .LIST1? .SCRIPT>>
	<ZAP-PASS>
	<SET UNDEF <MAPF ,LIST
			 <FUNCTION (L)
				   #DECL ((L) LIST)
				   <MAPRET !.L>>
			 <GET UNDEFINED OBLIST>>>
	<COND (<AND <EMPTY? .UNDEF> <0? ,ASSEMERRS>>
	       <RESET ,ZIN>
	       <SETG PASS1? <>>
	       <COND (,DTRACE?
		      <SETG DSYMBOLS <IBYTES 18 <- ,ZPC ,DSBOT 1>>>
		      <SETG DSJFN <DSOPEN <STRING .FILE ".DTEXT" <ASCII 0>> T>>
		      <DSPRINT " " ,DSJFN>
		      <SETG DSPOS 2>)>
	       <PUT ,ZOB 1 <GET TOPLOCALS OBLIST>>
	       <SETG ZCODE <IBYTES 8 ,ZPC>>
	       <SETG SCRIPT .SCRIPT>
	       <ZAP-PASS>
	       <PRIN1 ,ZPC>
	       <PRINC " bytes used.">
	       <CRLF>
;<PRINT ",INS=">
;<PRINT ,INS>
;<CRLF>
;<PRINT ".OTIME=">
;<PRINT .OTIME>
;<CRLF>
;<PRINT "<TIME>=">
;<PRINT <TIME>>
;<CRLF>
	       <PRIN1 <FIX <+ 0.5 </ ,INS <- <TIME> .OTIME>>>>>
	       <PRINC " instructions assembled per second.">
<BLOAT 20000 0 0 500>
<GC 0 T>
	       <COND (<SET ZIN <OPEN ;"PRINTB" "PRINT" <STRING .FILE ".ZIP">>>)
		     (<ERROR OPEN-FAILED!-ERRORS ZAP .FILE .ZIN>)>
;<PRINT ",ZCODE=">
;<PRINT ,ZCODE>
;<CRLF>
	       ;<GC-DUMP ,ZCODE .ZIN>
               <PRINT ,ZCODE .ZIN>
	       <CLOSE .ZIN>
<PRINT "<GC-DUMP ,ZCODE .ZIN> DONE.">
<CRLF>
	       <COND (,DTRACE?
		      <DSCLOSE ,DSJFN>
		      <COND (<SET ZIN <OPEN "PRINTB" <STRING .FILE
							     ".DSYMBOLS">>>)
			    (<ERROR OPEN-FAILED!-ERRORS ZAP .FILE .ZIN>)>
		      <GC-DUMP (,DSBOT ,DSYMBOLS) .ZIN>
		      <CLOSE .ZIN>)>
	       <SET SYMS
		    <MAPF ,VECTOR
			  <FUNCTION (BUCK)
			     #DECL ((BUCK) LIST)
			     <MAPRET !<MAPF ,VECTOR
				        <FUNCTION (ATM
					           "AUX" (S <SPNAME .ATM>))
					      #DECL ((ATM) ATOM
						     (S) STRING)
					      <COND (<AND <MEMQ !\? .S>
							  <N==? 
							   <NTH .S <LENGTH .S>>
							   !\?>>
						     <MAPRET>)
						    (<==? <PRIMTYPE ,.ATM>
							  WORD>
						     <MAPRET <CHTYPE ,.ATM FIX>
						             .S>)
						    (<MAPRET>)>>
				    .BUCK>>>
			  ,GLOBALS>>
<PRINT "BEFORE <SORTEX...">
	       <SORTEX <> .SYMS 2>
<PRINT "AFTER <SORTEX...">
	       <SET ZIN <OPEN "PRINT" <STRING .FILE ".ZSYM">>>
	       <PRINT .SYMS .ZIN>
	       <CLOSE .ZIN>
<PRINT "AFTER .SYMS SAVED.">
 	       <COND (<NOT <0? ,ASSEMERRS>>
		      <PRIN1 ,ASSEMERRS>
		      <PRINC " assembly errors">)>)
	      (<PRINC "Assembly aborted">
	       <CRLF>
	       <COND (<NOT <0? ,ASSEMERRS>>
		      <PRIN1 ,ASSEMERRS>
		      <PRINC " assembly errors">
		      <CRLF>)>
	       <COND (<NOT <EMPTY? .UNDEF>>
		      <PRINC "undefined symbols found:">
		      <MAPF <> ,PRINT .UNDEF>)>)>
	<CRLF>
<PRINC "ZAP \"DONE\".">
<CRLF>
	<AND .SCRIPT <N==? .SCRIPT ,OUTCHAN> <CLOSE .SCRIPT>>
	<QUIT>>
<ENDBLOCK>

<ENDPACKAGE>