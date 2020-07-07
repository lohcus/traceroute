#!/bin/bash
#Criado por Daniel Domingues
#https://github.com/lohcus

colunas=$(tput cols) # VERIFICA O TAMANHO DA JANELA PARA PODER DESENHAR O LAYOUT

divisao () {
	printf "\r\033[35;1m=\033[m"

	# LACO PARA PREENCHER UMA LINHA COM "="
	for i in $(seq 0 1 $(($colunas-2)))
	do
		printf "\033[35;1m=\033[m"
	done
	echo
}
# ================================================================================

# TESTA SE FOI DIGITADO O DOMÍNIO
if [ -z "$1" ]
then
	echo "Uso: $0 URL"
	exit
fi

clear

# VARIÁVEIS PARA FACILITAR A ESCRITA NA TELA
vermelho="\033[31;1m"
verde="\033[32;1m"
branco="\033[37;1m"

divisao

centro_coluna=$(( $(( $(( $colunas-17))/2 )))) #CALCULO PARA CENTRALIZAR O TEXTO
tput cup 0 $centro_coluna #POSICIONAR O CURSOR
printf "\033[37;1mSCRIPT TRACEROUTE\n\033[m"

# TESTE PARA VERIFICAR SE O DOMÍNIO RESPONDE
teste=$(host $1 | grep "not found")
if [ ! -z "$teste" ]
then
	printf "$vermelho[+] Domínio $verde$1$vermelho não encontrado...\n$branco"
	exit 1
fi

printf "$branco[+] Fazendo traceroute para o endereço $verde$1\n$branco"
divisao

for i in $(seq 1 255)
do
	#FAZ UM PING PARA O DOMINIO OU ENDERECO DIGITADO COM UM TTL=$i
	retorno=$(ping -4 -c 1 -w 1 -t $i $1 2> /dev/null)

	#TESTA SE FOI RETORNADA A MENSAGEM ICMP "Time to live exceeded"
	if [[ $(echo $retorno | grep "From" | cut -d "=" -f 2 | cut -d " " -f 2-5) == "Time to live exceeded" ]]
	then
		if [[ $(echo $retorno | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1) == "" ]] #CASO NAO CONSIGA SABER O IP DO ROTEADOR, IMPRIME UM "*" VERDE
		then
			printf "$verde$i - *\n$branco"
		else
			retorno=$(echo $retorno | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1) #SALVA O IP DO ROTEADOR QUE RETORNOU A MENSAGEM ICMP "Time to live exceeded"
			printf "$verde$i - $retorno\n$branco"
		fi
	else #CASO NEGATIVO
		if [[ $(echo $retorno | grep "ttl=" | cut -d "=" -f 3 | cut -d " " -f 1) ]]
		then
			#SALVA O IP DO ALVO E O TTL DA CONEXAO
			ip=$(echo $retorno | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -2)
			retorno=$(echo $retorno | grep "ttl=" | cut -d "=" -f 3 | cut -d " " -f 1)
			divisao
			
			#TESTE PARA FAZER UMA SUGESTAO DO SISTEMA OPERACIONAL DO ALVO
			case $retorno in
				[0-9]|[0-5][0-9]|6[0-4]) destino="Linux"; dec=64 ;;
				6[5-9]|[7-9][0-9]|1[0-1][0-9]|12[0-8]) destino="Windows"; dec=128 ;;
				12[8-9]|1[3-9][0-9]|2[0-5][0-9]|25[0-5]) destino="Unix"; dec=255 ;;
			esac
			
			printf "\033[32;1m[+] DESTINO ALCANÇADO! \033[31;1m$ip\033[32;1m: TTL foi \033[31;1m$retorno\033[32;1m, ou seja, \033[31;1m64\033[32;1m decrementado de \033[31;1m$(($dec-$retorno))\033[32;1m (\033[31;1mpossivelmente $destino\033[32;1m)\n\033[m"

			divisao
			#ASSIM QUE ATINGE O ALVO, O SCRIPT E ENCERRADO
			exit 0
		else  #CASO NAO CONSIGA UMA RESPOSTA DO ROTEADOR, IMPRIME UM "*" VERMELHO
			printf "$vermelho$i - *\n$branco"
		fi
	fi
done
