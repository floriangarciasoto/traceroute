#!/bin/bash

if [ `ls *.rte 2>/dev/null | wc -l` -gt 0 ];then # Vérification de l'existence de fichier RTE avec redirection de flux d'erreur dans le cas où il n'y a pas de fichier RTE
	echo 'digraph {' > carte.xdot # On initialise le fichier Dot
	for route in `ls *.rte`;do # Boucle sur tous les fichiers RTE
		dns=`echo $route | sed 's/road-to-//' | sed 's/.rte//'` # On prend la partie du fichier qui correspond à la destination
		dest=`cat $route | tail -n1 | sed 's/ /#/'` # On prend la destination du fichier, le dernier enregistrement
		((i=0)) # Variable qui va contenir le saut en question pour chaque enregistrement
		for routeur in `cat $route | sed 's/ /#/'`;do
			((i++))
			if [ "$routeur" == "no_response" ];then routeur="??? Hop $i vers $dns"; fi # On fixe un routeur qui n'a pas répondu par son saut et sa destination
			if [ $i -gt 1 ];then # Si l'on est au delà du premier saut
				echo "\"$routeurdavant\" -> \"$routeur\" [label=\"$dns\"];" | sed 's/#/ /g' | sed 's/\//+/g' >> carte.xdot # On inscrit la liaison dans le fichier Dot
				if [ "$routeur" == "$dest" ];then echo "\"$routeur\" [shape=box label=\"$dns ($routeur)\"];" | sed 's/#/ /g' | sed 's/\//+/g' >> carte.xdot; fi # S'il s'agit de la estination, on marque le nom de domaine avec une forme de rectangle
			fi
			routeurdavant=$routeur # On sauvegarde le routeur pour qu'il devienne le routeur d'avant dans la prochaine itération
		done
	done

	# Partie facultative sur la coloration des AS
	cmd=""
	((i=-1))
	colors=('#000000' '#ff0000' '#bb0000' '#770000' '#0000ff' '#0000bb' '#000077' '#00dd00' '#009900' '#005500' '#00bbbb' '#007777' '#ff0000' '#bb0000' '#770000' '#ff00ff' '#bb00bb' '#770077' '#bbbb00' '#777700')
	for as in `cat *.rte | grep "\[" | cut -d" " -f 2 | awk '!x[$0]++' | sed 's/\[//' | sed 's/\]//'`;do
		((i++))
		if [ $i -gt 0 ];then cmd="$cmd | "; fi
		cmd="${cmd}sed 's/($(echo $as | sed 's/\//+/g'))/${colors[$i]}/'"
	done
	eval "cat *.rte | grep '\[' | awk '{print \$1,\$2,\$2}' | sed 's/\] \[/\] (/' | sed 's/\]$/)/' | sed 's/\//+/g' | $cmd | awk '{printf(\"\\\"%s %s\\\" [color=\\\"%s\\\" fontcolor=\\\"%s\\\"];\\n\",\$1,\$2,\$3,\$3)}'" >> carte.xdot
	

	echo '}' >> carte.xdot # On ferme le fichier Dot
	xdot carte.xdot	# On l'execute
	else echo "Aucun fichier .rte dans le dossier courant."
fi
