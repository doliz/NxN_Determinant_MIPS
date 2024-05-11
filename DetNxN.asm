# Determinante matrice NxN usando il metodo di eliminazione di Gauss

.data 0x10020000
n: .word 3
float0: .float 0
float1: .float 1
floatMeno1: .float -1
.data 0x10010000
Matrice: .float 15, 0, 2		# 0 1 0
	 .float	1, 0, 1			# 0 1 1
	 .float 4, 1, 10		# 1 0 1

# 1: M = 0, 2: M = 0, 4: M = 0, 10: 1010, Normalizzato 1,01
# Quindi servono 2 bit; per gli altri non ne servono

# (i*n + j)*4

# Mat[j][k] = Mat[j][k] - R*Mat[i][k]
# R = Mat[j][i]/Mat[i][i]
.text
main:

la 	$t0, n
lw 	$a0, ($t0)
la 	$a1, Matrice



li 	$t1, 0x007fffff
li 	$t0, 0		# indice i = 0
li	$t7, 0		# var. appoggio shift
li 	$t8, 0		# Numero max shift


Ciclo:
lw 	$t2, ($a1)	
and 	$t3, $t2, $t1
sll 	$t3, $t3, 9


Controllo_Zero:
beq	$t3, $zero, Salta
sll	$t3, $t3, 1
addi 	$t7, $t7, 1
j Controllo_Zero


Salta:

addi	$t0, $t0, 1	
j Ciclo



jal 	Mat_Tri_Sup



la 	$t0, n
lw 	$a0, ($t0)
la 	$a1, Matrice
move 	$a2, $v0
jal 	Det



j 	Fine
    
      
        




Mat_Tri_Sup:
l.s 	$f0, float0
li 	$t0, 0	# indice i = 0;
li 	$t7, 0	# variabile di appoggio per tenere traccia degli switch fatti

# a1 = &Mat[0][0]
# Calcolo posizione indice --> &Mat[j][i] = (j*n + i)*4

Ciclo_i:
# Controllo le posizioni Mat[i][i], devono essere diverse da 0
	mul 	$t9, $a0, $t0	# i*n					Lo metto in t9 perché dopo riuso il risultato
	add 	$t1, $t9, $t0 	# i*n + i
	sll 	$t1, $t1, 2	# (i*n + i)*4
	
	
	addu 	$t1, $t1, $a1	# &Mat[i][i]
	l.s 	$f1, ($t1)	# Mat[i][i]
	
	c.eq.s 	$f0, $f1		# Mat[i][i] = 0 ?
	bc1f 	No_Errore
	# Dentro a0 ho n, a1 &matrice
	# Usa lo stack
	
	move 	$a2, $t0
	addi 	$sp, $sp, -12
	sw 	$t0, 8($sp)
	sw 	$t1, 4($sp)
	sw 	$ra, ($sp)
	
	jal 	Switch
	
	lw 	$ra, ($sp)
	lw 	$t1, 4($sp)
	lw 	$t0, 8($sp)
	addi 	$sp, $sp, 12
	
	add 	$t7, $t7, $v0	# tengo traccia degli scambi
	beq 	$v0, $zero, Switch_Non_Possibile
	j 	Ciclo_i
	Switch_Non_Possibile:
	jr 	$ra
	
	No_Errore:

	addiu 	$t2, $t0, 1	# j = i + 1, mi poisizone nella riga successiva
	Ciclo_j:
	# Devo calcolare R =  M[j][i]/M[i][i]
	# per &Mat[j][i] --> (j*n + 1) * 4
		mul 	$t8, $t2, $a0	# j*n 		Lo metto in t8 perché dopo riuso il risultato	
		add 	$t3, $t8, $t0	# j*n + i
		sll 	$t3, $t3, 2		# (j*n + i) * 4
		addu 	$t3, $t3, $a1	# &Mat[j][i]
	
		l.s 	$f2, ($t3)		# Mat[j][i]
		div.s 	$f2, $f2, $f1	# Mat[j][i]/Mat[i][i] = R
	
		li 	$t4, 0		# k = 0;
		Ciclo_k:
			# Ora scorro la riga j ed i e faccio Mat[j][k] = Mat[j][k] - R*Mat[i][k]
			addu 	$t5, $t8, $t4 	# j*n + k
			sll 	$t5, $t5, 2		# (j*n + k)*4
			addu 	$t5, $t5, $a1	# &Mat[j][k]
			
			addu 	$t6, $t9, $t4	# i*n + k
			sll 	$t6, $t6, 2		# (i*n + k)*4
			addu 	$t6, $t6, $a1	# &Mat[i][k]
			
			l.s 	$f3, ($t5)		# M[j][k]
			l.s 	$f4, ($t6)		# M[i][k]
			mul.s 	$f4, $f4, $f2	# R * M[i][k]
			
			sub.s 	$f5, $f3, $f4
			
			s.s 	$f5, ($t5)		# Metto il risultato in M[j][k]
			
			addiu 	$t4, $t4, 1	# k++
			blt 	$t4, $a0, Ciclo_k	# k < n ?
		
		addiu 	$t2, $t2, 1	# j++
		blt 	$t2, $a0, Ciclo_j
	
	addiu 	$t0, $t0, 1	# i++
	blt 	$t0, $a0, Ciclo_i
	
move 	$v0, $t7
jr 	$ra



Switch:
li 	$t0, 0	# p, riga con cui fare switch
li 	$v0, 0	# N switch eseguiti
Controllo_Valori:
	beq 	$t0, $a2, oltre
	# Prendo valore M[i][p]		(i*n + p)*4
	
	mul 	$t1, $a0, $a2	# i*n
	addu 	$t1, $t1, $t0	# i*n + p
	sll 	$t1, $t1, 2	# (i*n+p)*4
	addu 	$t1, $t1, $a1	# &M[i][p]
	
	l.s 	$f4, ($t1)		# M[i][p]
	c.eq.s 	$f0, $f4		# Mat[i][p] = 0 ?
	bc1t 	oltre
	
	mul 	$t1, $a0, $t0	# p*n
	addu 	$t1, $t1, $a2	# p*n + i
	sll 	$t1, $t1, 2		# (p*n+i)*4
	addu 	$t1, $t1, $a1	# &M[p][i]
	
	l.s 	$f4, ($t1)		# M[p][i]
	c.eq.s 	$f0, $f4		# Mat[p][i] = 0 ?
	bc1t 	oltre
	
	addi 	$v0, $v0, 1	# Devo tenere traccia di quanti scambi faccio perché cambia il segno del determinante
	move 	$t2, $zero		# indice k € [0,n]
	Ciclo_Switch:
		mul 	$t1, $a0, $t2	# k*n
		addu 	$t1, $t1, $t0	# k*n + p
		sll 	$t1, $t1, 2		# (k*n + p)*4
		addu 	$t1, $t1, $a1	# &M[k][p]
		l.s 	$f4, ($t1)		# M[k][p]
		
		mul 	$t3, $a0, $t2	# i*n
		addu 	$t3, $t3, $a2	# i*n + p
		sll 	$t3, $t3, 2		# (i*n+p)*4
		addu 	$t3, $t3, $a1	# &M[i][p]
		l.s 	$f6, ($t3)		# M[i][p]
		
		s.s 	$f4, ($t3)		# Switch
		s.s 	$f6, ($t1)		# Switch

		
		addiu 	$t2, $t2, 1
		blt 	$t2, $a0, Ciclo_Switch

	s.s 	$f4, float0
	s.s 	$f6, float0

	jr 	$ra
	oltre:
	addi 	$t0, $t0, 1
	blt 	$t0, $a0, Controllo_Valori

s.s 	$f4, float0
s.s 	$f6, float0

jr 	$ra




Det:
li 	$t0, 0
l.s 	$f10, floatMeno1
l.s 	$f12, float1	 	# variabile di appoggio per il calcolo del determinante
Ciclo_Det:
	mul 	$t1, $t0, $a0	# i*n
	addu 	$t1, $t1, $t0	# (i*n+i)
	sll 	$t1, $t1, 2	# (i*n+i) * 4
	addu 	$t1, $t1, $a1	# &Mat[i][i]
	
	l.s 	$f2, ($t1)
	mul.s 	$f12, $f12, $f2	# Moltiplico gli elementi sulla diagonale
	
	addiu 	$t0, $t0, 1	# i++
	blt 	$t0, $a0, Ciclo_Det

li 	$t2, 2
div 	$a2, $t2
mfhi 	$t0
beq 	$t0, $zero, Positivo
mul.s 	$f12, $f12, $f10

Positivo:
# Stampa
li 	$v0, 2
syscall


jr 	$ra
	

Fine:
j 	Fine
