
<PACKAGE "FACT">

<ENTRY FACT>

<DEFINE FACT (N) ;"the standard recursive factorial"
	<COND (<0? .N> 1)
	      (ELSE <* .N <FACT <- .N 1>>>)>>

<ENDPACKAGE>
