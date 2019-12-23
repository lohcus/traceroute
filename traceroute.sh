#!/bin/bash

clear
vermelho="\033[31;1m"
verde="\033[32;1m"
branco="\033[m"
printf "$vermelho[+] Fazendo traceroute para o endereço $verde$1\n$branco"
echo

for i in $(seq 1 255)
do
	#FAZ UM PING PARA O DOMINIO OU ENDERECO DIGITADO COM UM TTL=$i
	pingo=$(ping -4 -c 1 -w 1 -t $i $1 2> /dev/null)

	#TESTA SE FOI RETORNADA A MENSAGEM ICMP "Time to live exceeded"
	if [[ $(echo $pingo | grep "From" | cut -d "=" -f 2 | cut -d " " -f 2-5) == "Time to live exceeded" ]]
	then
		if [[ $(echo $pingo | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1) == "" ]] #CASO NAO CONSIGA SABER O IP DO ROTEADOR, IMPRIME UM "*" VERDE
		then
			printf "$verde$i - *\n$branco"
		else
			pingo=$(echo $pingo | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1) #SALVA O IP DO ROTEADOR QUE RETORNO A MENSAGEM ICMP "Time to live exceeded"
			printf "$verde$i - $pingo\n$branco"
		fi
	else #CASO NEGATIVO
		if [[ $(echo $pingo | grep "ttl=" | cut -d "=" -f 3 | cut -d " " -f 1) ]]
		then
			#SALVA O IP DO ALVO E O TTL DA CONEXAO
			ip=$(echo $pingo | cut -d " " -f 9- | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -2)
			pingo=$(echo $pingo | grep "ttl=" | cut -d "=" -f 3 | cut -d " " -f 1)
			printf "$vermelho===============================================\n$branco"
			#TESTE PARA FAZER UMA SUGESTAO DO SISTEMA OPERACIONAL DO ALVO
			case $pingo in
				[0-9]|[0-5][0-9]|6[0-4]) printf "\033[32;1mDESTINO ALCANÇADO! \033[31;1m$ip\033[32;1m: TTL foi \033[31;1m$pingo\033[32;1m, ou seja, \033[31;1m64\033[32;1m decrementado de \033[31;1m$((64-$pingo))\033[32;1m (\033[31;1mLinux\033[32;1m)\n\033[m" ;;
				6[5-9]|[7-9][0-9]|1[0-1][0-9]|12[0-8])printf "\033[32;1mDESTINO ALCANÇADO! \033[31;1m$ip\033[32;1m: TTL foi \033[31;1m$pingo\033[32;1m, ou seja, \033[31;1m64\033[32;1m decrementado de \033[31;1m$((128-$pingo))\033[32;1m (\033[31;1mWindows\033[32;1m)\n\033[m" ;;
				12[8-9]|1[3-9][0-9]|2[0-5][0-9]|25[0-5])printf "\033[32;1mDESTINO ALCANÇADO! \033[31;1m$ip\033[32;1m: TTL foi \033[31;1m$pingo\033[32;1m, ou seja, \033[31;1m64\033[32;1m decrementado de \033[31;1m$((255-$pingo))\033[32;1m (\033[31;1mUnix\033[32;1m)\n\033[m" ;;
			esac
			printf "$vermelho===============================================\n$branco"
			#ASSIM QUE ATINGE O ALVO, O SCRIPT E ENCERRADO
			exit 0
		else  #CASO NAO CONSIGA UMA RESPOSTA DO ROTEADOR, IMPRIME UM "*" VERMELHO
			printf "$vermelho$i - *\n$branco"
		fi
	fi
done
