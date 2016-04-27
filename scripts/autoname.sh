#!/bin/bash

adjetive=(capable precise fair fearless crazy infamous inquisitive insidious jazzy melodic oceanic profuse ruddy sassy swanky ultra utopian vigorous vulgar wacky yummy ivory orange white golden silver bronze lime peach scarlet viridian black gray red yellow blue pink purple green clean colorful cold hot deep delicate ugly drunk dusty gay glowing multicoloured muted translucent vibrant faded vivid violent dangerous)

name=(android robot librarian designer firefighter chemist dancer painter)
animals=(spider panda cheeta dolphin condor tapir bull drone cocodrile alligator alpaca cow crow ant antelope lion tiger panter turtle bison dog cat fox buffalo owl pelican bear swan fish duck shark boa snake gnu snail frog flamingo cobra raccoon coyote crab mule wale eagle hawk pigeon lizard dove penguin armadillo worm pig)
fantasy=(dragon knight princess elf orc archer mage warrior unicorn goblin)
pokemon=(squirtle charmander pikachu mew)


function random {
	list=$1

	eval s=\${#$list[@]}

	let limit=$s-1 # porque se cuenta el 0
	rnd=`seq 0 $limit|sort -R| head -n 1`
	eval nn=\${$list[$rnd]}

	echo "$nn"
}

function gethostnameabout {
	list=$1
	adj=`random adjetive`
	nmm=`random $list`
	echo "${adj}-${nmm}"
}


gethostnameabout animals
