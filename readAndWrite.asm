.data
# nome do arquivo texto
fileName:	.asciiz	"db.txt"
auxFileName:	.asciiz	"auxdb.txt"
# caracteres que separam os campos
separator:	.asciiz	"; "
newline:	.asciiz	";\n"
# buffer que armazena um registro da agenda temporariamente
regBuffer:	.space	500
# utilidade publica
fieldSizes:	.word	0, 0, 0, 0, 0




.text
######## METAINFO: adiciona o campo de informações antes de um registro ########
#### ENTRADAS ####
# a0 - array de words contendo os 5 tamanhos do campo de informações
# a1 - flag que indica em qual arquivo escrever (0 - principal, 1 - auxiliar)
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl metaInfo
metaInfo:
	# salva registradores
	addi	$sp, $sp, -24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	# pega as informacoes de tamanho de bsizes
	lw	$s0, 0($a0)
	lw	$s1, 4($a0)
	lw	$s2, 8($a0)
	lw	$s3, 12($a0)
	# flag que indica em qual arquivo escrever
	move	$s4, $a1
	# escreve o campo de informacao numa string
	la	$a0, regBuffer
	add	$a1, $s0, $s1	
	add	$a1, $a1, $s2	# $a1 = $t0 + $t1 + $t2 + $t3 (soma dos tamanhos dos campos principais)
	add	$a1, $a1, $s3	# $a1 = $a1 + 6*2 + 3 (soma dos separadores e do ID)
	addi	$a1, $a1, 28	# $a1 = $a1 + 3 + 3 + 2 + 3 + 2 (soma dos campos de informacao)
	li	$a2, 3
	jal	numToStr	# tamanho total
	la	$a0, regBuffer+3
	move	$a1, $s0
	li	$a2, 3
	jal	numToStr	# tamanho do nome completo
	la	$a0, regBuffer+6
	move	$a1, $s1
	li	$a2, 2
	jal	numToStr	# tamanho do apelido
	la	$a0, regBuffer+8
	move	$a1, $s2
	li	$a2, 3
	jal	numToStr	# tamanho do email
	la	$a0, regBuffer+11
	move	$a1, $s3
	li	$a2, 2
	jal	numToStr	# tamanho do telefone
	# abre o arquivo para escrita
	la	$a0, fileName
	beqz	$s4, writetomain1
	la	$a0, auxFileName	# se a1 for 1, é pra escrever no arquivo secundário
writetomain1:
	li	$a1, 9
	li	$v0, 13
	syscall
	# escreve a string no arquivo
	move	$a0, $v0
	la	$a1, regBuffer
	li	$a2, 13
	li	$v0, 15
	syscall
	# escreve o separador
	la	$a1, separator
	li	$a2, 2
	li	$v0, 15
	syscall
	# fecha o arquivo
	li	$v0, 16
	syscall
	# recupera registradores
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 24
	jr	$ra





######## ADDREG: adiciona um novo registro na agenda ########
#### ENTRADAS ####
# a0 - array com os endereços das strings que contém os dados lidos pelo usuário
# a1 - array com o tamanhos dos campos (por enquanto)
# a2 - numero de contatos atual
# a3 - flag que indica em qual arquivo escrever (0 - principal, 1 - auxiliar)
#### VARIÁVEIS ####
# s0 - endereço do array de endereços
# s1 - endereço do array de tamanhos (por enquanto)
# s2 - ID máximo, é o ID associado a este registro / também usado para iterar nas informações
# s3 - descritor do arquivo principal
#### SAÍDAS ####
# não tem
.globl addReg
addReg:
	# salva registradores
	addi	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$s3, 0($sp)
	move	$s0, $a0
	move	$s1, $a1
	move	$s2, $a2
	# abre o arquivo para escrita
	la	$a0, fileName
	beqz	$a3, writetomain2
	la	$a0, auxFileName	# se a1 for 1, é pra escrever no arquivo secundário
writetomain2:
	li	$a1, 9
	li	$v0, 13
	syscall
	# salva o descritor
	move	$s3, $v0
	# escreve este número numa string
	la	$a0, regBuffer
	addi	$a1, $s2, 1	# ID é o número de contatos mais um
	li	$a2, 3
	jal	numToStr
	# escreve a string do ID no arquivo
	move	$a0, $s3
	la	$a1, regBuffer
	li	$a2, 3
	li	$v0, 15
	syscall
	# escreve o separador
	la	$a1, separator
	li	$a2, 2
	li	$v0, 15
	syscall
	# escreve o restante das informacoes
	move	$s2, $zero
infol:	
	add	$t0, $s0, $s2	# $s0 é o array de endereços
	add	$t1, $s1, $s2	# $s1 é o array de tamanhos
	lw	$a1, 0($t0)	# carrega endereço do buffer
	lw	$a2, 0($t1)	# carrega tamanho do buffer
	li	$v0, 15
	syscall
	la	$a1, separator
	bne	$s2, 12, norm
	la	$a1, newline	# substitui separator por newline
norm:	li	$a2, 2
	li	$v0, 15
	syscall
	addi	$s2, $s2, 4
	bne	$s2, 16, infol
	# fecha o arquivo
	li	$v0, 16
	syscall
	# recupera registradores
	lw	$s3, 0($sp)
	lw	$s2, 4($sp)
	lw	$s1, 8($sp)
	lw	$s0, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, 20
	jr	$ra





######## METATOMEMORY: passa as informações do campo de informações para a memória #########
#### ENTRADAS ####
# a0 - string contendo o campo de informações
# a1 - endereço de memoria onde serão armazenados os números
#### VARIÁVEIS ####
# s0 - endereço de memória dos números
#### SAÍDAS ####
# não tem
metaToMemory:
	# salva registradores
	addi	$sp, $sp, -8
	sw	$s0, 4($sp)
	sw	$ra, 0($sp)
	move	$s0, $a1
	# tamanho total
	li	$a1, 3
	jal	strToNum
	sw	$v0, 0($s0)
	addi	$a0, $a0, 3
	# tamanho do nome
	li	$a1, 3
	jal	strToNum
	sw	$v0, 4($s0)
	addi	$a0, $a0, 3
	# tamanho do apelido
	li	$a1, 2
	jal	strToNum
	sw	$v0, 8($s0)
	addi	$a0, $a0, 2
	# tamanho do email	
	li	$a1, 3
	jal	strToNum
	sw	$v0, 12($s0)
	addi	$a0, $a0, 3
	# tamanho do telefone
	li	$a1, 2
	jal	strToNum
	sw	$v0, 16($s0)
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra





######## READREGLINE: lê um registro do arquivo texto ########
#### ENTRADAS ####
# a0 - descritor do arquivo
# a1 - endereço da string para guardar o registro
# a2 - endereço de memoria para guardar os tamanhos
#### VARIÁVEIS ####
# s0 - descritor do arquivo
# s1 - endereço da string para guardar o registro
# s3 - endereço de memoria para guardar os tamanhos
#### SAÍDAS ####
# v0 - indicador de eof
# v1 - tamanho total do registro
.globl	readRegLine
readRegLine:
	# salva registradores
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	# salva as entradas
	move	$s0, $a0	# descritor
	move	$s1, $a1	# regBuffer
	move	$s2, $a2	# fieldSizes
	# le o campo de informacoes e checa se deu eof
	move	$a0, $s0
	move	$a1, $s1	# la	$a1, regBuffer
	li	$a2, 15
	li	$v0, 14
	syscall
	# se chegar ao fim do arquivo, sai
	beq	$v0, $zero, readregline_exit
	# passa as informacoes de tamanho de campo para a memoria
	move	$a0, $s1	# la	$a0, regBuffer
	move	$a1, $s2	# la	$a1, fieldSizes
	jal	metaToMemory
	# le o resto do registro
	move	$a0, $s0
	addi	$a1, $s1, 15	# la	$a1, regBuffer+15
	lw	$t0, 0($s2)	# lw	$t0, fieldSizes	# tamanho total do registro
	addi	$a2, $t0, -15	# tamanho total - (15)
	li	$v0, 14
	syscall
readregline_exit:
	# retorna o tamanho do registro
	lw	$v1, 0($s2)
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	addi	$sp, $sp, 16
	jr	$ra





######## CREATEFILE: cria o arquivo de registros se ele não existir ########
#### ENTRADAS ####
# não tem
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl	createFile
createFile:
	# zera o arquivo auxiliar
	la	$a0, auxFileName
	li	$a1, 1
	li	$v0, 13
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $v0
	li	$v0, 16
	syscall
	# abre o arquivo p write+append. se existir, nao substitui, e se nao existir, cria
	la	$a0, fileName
	li	$a1, 9
	li	$v0, 13
	syscall
	# fecha o arquivo
	move	$a0, $v0
	li	$v0, 16
	syscall
	jr	$ra





######## ERASEFILE: deleta o arquivo de registros ########
#### ENTRADAS ####
# não tem
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl	eraseFile
eraseFile:
	# zera o arquivo auxiliar
	la	$a0, auxFileName
	li	$a1, 1
	li	$v0, 13
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $v0
	li	$v0, 16
	syscall
	# zera o arquivo principal
	la	$a0, fileName
	li	$a1, 1
	li	$v0, 13
	syscall
	# fecha o arquivo principal
	move	$a0, $v0
	li	$v0, 16
	syscall
	jr	$ra
