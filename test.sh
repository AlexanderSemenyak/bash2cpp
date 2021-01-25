#!/bin/bash

declare -a buildonly=(
"9.1.sh"
"3.4.sh"
# banner.sh
# logic.sh
# "populate-volatile.sh"
# checkroot.sh
"9.9.sh"
# quote issue
# "9.8.sh"
# quote problem
# "9.7.sh"
# quote problem
# "9.6.sh"
"9.5.sh"
# crashes
# "9.4.sh"
"9.3.sh"
"9.2.sh"
"8.5.sh"
# parse problem
# "8.4.sh"
"8.3.sh"
# parse problem
# "8.2.sh"
"8.1.sh"
"7.7.sh"
"7.6.sh"
"7.5.sh"
"7.4.sh"
# divide by zero
# "7.3.sh"
"7.2.sh"
"7.1.sh"
"6.2.sh"
"6.1.sh"
# parse problem
# "5.3.sh"
# parse problem"
# "5.2.sh"
# quote issues
# "5.1.sh"
"4.7.sh"
"4.6.sh"
"4.5.sh"
"4.4.sh"
"4.3.sh"
"4.2.sh"
"4.1.sh"
"3.3.sh"
"3.2.sh"
"3.1.sh"
"2.1.sh"
"2.2.sh"
"2.3.sh"
"for3.sh"
"urandom"
"logic.sh"
"read-only-rootfs-hook.sh"
"hostname.sh"
"if.sh"
"functions"
"dmesg.sh"
"mountnfs.sh"
"redirect.sh"
"umountnfs.sh"
"while0.sh"
"read.sh"
"variables.sh"
"redirection.sh"
"functions0.sh"
"case.sh"
"if7.sh"
"for.sh"
"alignment.sh"
"bootmisc.sh"
"checkfs.sh"
"devpts.sh"
"halt"
"mountall.sh"
"reboot"
"rmnologin.sh"
"save-rtc.sh"
"sendsigs"
"single"
"sushell"
"sysfs.sh"
"umountfs"
)

declare -a buildandexec=(
"for8.sh"
"if10.sh"
"local.sh"
"default0.sh"
"functions3.sh"
"array0.sh"
"array.sh"
"for7.sh"
"for5.sh"
"for4.sh"
"echo4.sh"
"showsize.sh"
# "upper.sh"
"echo3.sh"
# "functions2.sh"
"lower0.sh"
"upper0.sh"
#"catinput.sh"
#"substring.sh"
"echo2.sh"
"special.sh"
# "regex.sh"
# "split.sh"
# "dirname.sh"
# "replacement.sh"
"functions1.sh"
"arguments.sh 1 2 3"
"arguments.sh 1"
"arguments.sh"
"for2.sh"
"tildaexpansion.sh"
"echo1.sh"
"redirection0.sh"
"while0.sh"
"for0.sh"
"braceexpansion.sh"
"redirection.sh"
"pipeline.sh"
"hostname0.sh"
"if9.sh"
"redirect.sh"
"while0.sh"
"if3.sh"
# "expansions.sh"
# "for1.sh"
"if0.sh"
"case0.sh"
"arithmetic.sh"
"while.sh"
"if8.sh"
"parameterexpansion.sh"
"var1.sh"
"var0.sh"
"until.sh"
"conditionals.sh"
"stringconcat.sh"
"if6.sh"
"if5.sh"
"if4.sh"
"if2.sh"
"if1.sh"
)

mkdir -p gen

do_buildtest()
(
	stringarray=($1)
	bashargs="${stringarray[@]:1}"
	fullfile="${stringarray[0]}"
	filename=$(basename -- "$fullfile")
	extension="${filename##*.}"
	filename="${filename%.*}"
	f="$filename"
	node app.js tests/${stringarray[0]} gen/$f.cpp gen/$f.log
	if [ "$?" -ne 0 ]; then
		exit -1
	fi

	g++ gen/$f.cpp -o gen/$f -g $3 -fno-exceptions -lpcre -std=c++17
	echo "$1"
)

do_test()
(
	stringarray=($1)
	bashargs="${stringarray[@]:1}"
	fullfile="${stringarray[0]}"
	filename=$(basename -- "$fullfile")
	extension="${filename##*.}"
	filename="${filename%.*}"
	f="$filename"
	node app.js tests/${stringarray[0]} gen/$f.cpp gen/$f.log
	if [ "$?" -ne 0 ]; then
		exit -1
	fi

	g++ gen/$f.cpp -o gen/$f -g $3 -fno-exceptions -lpcre -std=c++17

	out0=$(gen/$f $bashargs)
	out1=$(bash tests/$1)
	if [ "$out0" != "$out1" ]; then
		# for (( i=0; i<${#out0}; i++ )); do
			# echo "${out0:$i:1} vs. ${out1:$i:1}"
			# if [ "${out0:$i:1}" != "${out1:$i:1}" ]; then
				# printf "%d\n" \'${out0:$i:1}
				# printf "%d\n" \'${out1:$i:1}
				# break
			# fi
		# done
		# echo ${#out0}
		gen/$f $bashargs > out0.txt
		# echo ${#out1}
		tests/$1 > out1.txt
		exit 1
	fi
	start=$(date +%s.%N)
	for i in $(seq 1 $2)
	do
		$(gen/$f 2>&1 > /dev/null )
	done
	end=$(date +%s.%N)
	runtime0=$(python -c "print(${end} - ${start})")

	start=$(date +%s.%N)
	for i in $(seq 1 $2)
	do
		$(bash tests/$1 2>&1 > /dev/null )
	done
	end=$(date +%s.%N)
	runtime1=$(python -c "print(${end} - ${start})")
	diff=$(python -c "print(${runtime0} - ${runtime1})")
	echo "$f: bin:$runtime0 vs. sh:$runtime1 diff:$diff"
	return 
)

do_looptest()
(
	run0avg=0
	run1avg=0
	runtime=$(do_test "$1" "$2" "$3" )
	if [ "$runtime" == "" ]; then
		echo "$1 failed"
		return 1
	fi
	run0=$(echo "$runtime" | cut -d':' -f 3 |  cut -d' ' -f 1)
	run1=$(echo "$runtime" | cut -d':' -f 4 |  cut -d' ' -f 1)
	diff=$(echo "$runtime" | cut -d':' -f 5 |  cut -d' ' -f 1)
	percent=$(python -c "print((${diff} / ${run0}) * 100)")
	echo "$1: run0 = $run0 run1 = $run1 diff=$diff percent=$percent"
	return 0
)

if [ "$#" -eq 1 ]; then
	if [ $1 == "-b" ]; then
		for filename in "${buildandexec[@]}"
		do
			do_looptest $filename 100 "-O3"
		done

		exit 0
	fi
	if [ $1 != "-e" ]; then
	do_looptest $1 1 "-O0" -g
	exit 0
	fi
fi

if [ "$#" -eq 2 ]; then
	# echo "count is $2"
	do_looptest $1 $2 "-O3"
	exit 0
fi

if [ "$#" -eq 1 ] && [ $1 == "-e" ]; then
	for filename in "${buildandexec[@]}"
	do
		do_looptest "$filename" 1 "-O3"
		if [ $? -ne 0 ]; then
			exit $?
		fi
	done
	exit 0
fi

## now loop through the above array
for filename in "${buildonly[@]}"
do
	do_buildtest "$filename" 1 "-O3"
	if [ $? -ne 0 ]; then
		exit $?
	fi
done

for filename in "${buildandexec[@]}"
do
	do_looptest "$filename" 1 "-O3"
	if [ $? -ne 0 ]; then
		exit $?
	fi
done

exit 0
