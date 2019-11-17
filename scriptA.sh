#!/bin/bash

if [ $# -gt 0 ];then # On vérifie d'abord si le nombre d'arguments est plus grand que 0
	if [ $# -gt 1 ];then echo "Seul le premier argument est pris en compte, les autres sont ignorés."; fi
	destdn=$1 # La variable $1 peut être modifiée par d'autre commandes, il est donc préférable de la stocker dans une variable plus parlante
	echo "Tentavive de calcul de destination vers $destdn :"
	((go=0)) # Il s'agit de la variable de type booléen qui va déterminer si l'on peut commencer les boucles ou non
	declare -a destips # Tableau qui va contenir les différentes IP que peuvent avoir certains noms de domaines
	((n=0)) # Variable qui va permettre d'indexer ce tableau par rapport au nombre d'IP obtenus
	for i in `host -W 1 $destdn | grep has | cut -d" " -f 4`; do ((n++)); destips[$n]=$i; done # On rentre dans le tableau toutes les IP obtenues par la commande host
	if [ ${#destips[@]} -gt 0 ];then # Si des IP ont été obtenues pour le nom de domaine donné
		echo "Nom de domaine valide : OK"
		echo "Destination(s) possible(s) :"
		for i in ${destips[@]}; do echo $i; done # On affiche les IP trouvées
		((go=1)) # On va pouvoir passer aux boucles
	else # Si aucune IP n'a était trouvé
		echo -n "Détermination du nom de domaine : "
		destips[1]=$destdn
		test=`host -W 1 $destdn | grep pointer | head -n1 | cut -d" " -f 5 | sed 's/.$//g'` # On cherche le nom de domaine éventuel pour l'IP donnée
		if [ "$test" != "" ];then # Si un nom de domaine a été obtenu
			echo "$test : OK"
			destdn=$test
			((go=1)) # On va pouvoir passer aux boucles
		else # Si l'IP n'a donné aucun nom de domaine
			echo "FAILED"
			echo -n "Tentative de contact avec $destdn (ping) : "
			test=`ping -c 1 $destdn -w 1 2>/dev/null | grep '1 received'` # Si la destination peut tout de même être atteinte
			if [ "$test" != "" ];then
				echo "OK"
				((go=1)) # On va pouvoir passer aux boucles
			else echo "FAILED"; fi
		fi
	fi
	if [ $go -eq 1 ];then
		echo "Calcul de la route vers ${destips[1]} :"
		rm "road-to-$destdn".rte -f # On supprime le fichier RTE dans le cas où il existe déjà
		touch "road-to-$destdn".rte # On crée le fichier RTE vide
		((ok2=0)) # Variable déterminant si la destination a été atteinte
		for ttl in `seq 1 30`;do # Boucle sur les TTL
			((ok=0)) # Variable déterminant si le routeur pour le saut en question a répondu
			echo " TTL à $ttl :"
			for scenario in '-I' '-U' '-T' #'-U -p 23' '-T -p 80' '-T -p 443' # tous les scénarios possibles sont inscrits sur cette ligne
			do
				echo -n "  Envoi en $scenario : "
				routeur=`sudo traceroute $destdn -n -A -f $ttl -m $ttl $scenario | tail -n 1 | sed 's/*//g' | awk '{print $2,$3}' | sed 's/\[\]//'` # Commande traceroute prenant en compte le TTL, le scénario. Extraction des infos avec sed et awk.
				if [ "$routeur" != " " ];then # Si une réponse a était obtenue
					save=$routeur # On sauverarde la réponse que l'on a obtenu
					echo $routeur | awk '{printf("Routeur trouvé : %s",$1);if ($2 != "") {printf(" %s",$2);};print " : OK"}' # On affiche correctement les IP et les AS
					((ok=1)) # Le routeur a répondu, on met cette variable à 1
					for i in ${destips[@]}; do if [ "$(echo $routeur | awk '{print $1}')" == "$i" ];then ((ok2=1));destips[1]=$i;break; fi; done # On vérifie si leur routeur en question fait parti des IP de destinations
					if [ "$(echo $routeur | awk '{print $2}')" != "" ];then break; fi # Si il y a une AS, on brise la boucle
					#break # Pour que le script ignore l'obtention absolue d'AS, décommenter cette ligne
				else echo "Pas de réponse : FAILED"; fi
			done
			if [ $ok -eq 1 ];then echo $save >> "road-to-$destdn".rte; else echo 'no_response' >> "road-to-$destdn".rte;echo "  Le routeur ne semble pas vouloir répondre ... : FAILED"; fi # On sauvegarde le résultat dans le fichier RTE
			if [ $ok2 -eq 1 ];then break; fi # Si la destination a été atteinte, on sort de la boucle des TTL
		done
		if [ $ok2 -eq 1 ];then echo "Destination atteinte (${destips[1]}) : OK"; else echo "Destination non atteinte (${destips[1]}) : FAILED"; fi
	else echo "Impossible de calculer la route vers $destdn."
	fi
else echo "Saisir la destination en tant qu'argument."
fi